# Streaming Support for msgpack

Ideas for making the decoder safe for streaming (incremental data
arrival). See [issue #14](https://github.com/seantallen-org/msgpack/issues/14).

## Design Constraints

- **No stdlib changes**: Modifications to `buffered.Reader` in ponyc
  are off the table.
- **Custom reader is OK**: A replacement reader within the msgpack
  package is acceptable.
- **Preserve existing API**: The existing `MessagePackEncoder` and
  `MessagePackDecoder` primitives should remain as-is for non-streaming
  use. Streaming support should be additive.

## Key Facts About `buffered.Reader`

These details about the stdlib Reader inform which approaches are
viable:

- **Consuming reads**: `u8()`, `u16_be()`, `block()`, etc. permanently
  advance the cursor and discard consumed bytes. No undo.
- **Non-consuming peeks exist**: `peek_u8(offset)`,
  `peek_u16_be(offset)`, `peek_u32_be(offset)`, `peek_u64_be(offset)`,
  and their little-endian/signed variants. These read without advancing
  the cursor.
- **No `peek_block`**: You can peek at fixed-width integers but not at
  arbitrary byte ranges. This is fine for the size-check strategy
  (you only need to peek at format bytes and length fields, not
  payloads) but means you can't fully preview variable-length data
  without consuming it.
- **`size()` returns available bytes**: Useful for checking whether
  enough data is buffered before attempting a decode.
- **No snapshot/rollback**: No built-in way to save cursor position and
  restore it after a failed partial read.

## The Problem

The decoder does multiple consuming reads from the `Reader` per value.
For example, `MessagePackDecoder.str()` reads:

1. 1 byte — the format type
2. 1/2/4 bytes — the string length
3. N bytes — the string payload

If step 1 succeeds but step 3 fails because the payload hasn't arrived
yet, the Reader has already consumed the type and length bytes. They're
gone. When more data arrives and the caller retries, the stream is
corrupted.

The `Reader` has no rollback mechanism — each `u8()`, `u16_be()`,
`block()` call permanently advances the cursor.

## Cross-Cutting Concern: Error Discrimination

All approaches must solve this: the current API uses `?` for both "not
enough data" and "invalid data." A streaming layer must distinguish
these because the caller's response is completely different — wait for
more data vs. abort.

Options for expressing this:

- **Union return type**: `(T | NotEnoughData | InvalidData)` — explicit,
  pattern-matchable, no ambiguity. Most idiomatic for Pony.
- **Notify/callback**: Emit decoded values via an interface. Errors
  become method calls too. Natural for push-based streaming.
- **Separate check method**: Ask "is there enough data?" before
  decoding. Keeps existing `?` semantics for actual errors. But creates
  a check-then-act race if used incorrectly (not really a race in Pony's
  single-actor model, but it's two calls that must stay in sync).

## Approach A: Peek-and-Check Wrapper

A new primitive (or small class) that peeks at the Reader to calculate
how many bytes the next value needs, checks `reader.size()`, and only
delegates to the existing `MessagePackDecoder` if sufficient data is
available.

**How it works**: For every MessagePack format, the total byte count is
deterministic from the format byte and (for variable-length types) the
length field:

- Fixed-size types (nil, bool, ints, floats): known from format byte
  alone (1-9 bytes total).
- Variable-length types (str, bin, ext): peek at format byte + length
  bytes using `Reader.peek_u8/peek_u16_be/peek_u32_be` to determine
  total size without consuming anything.
- Container headers (array, map): fixed size from format byte (1-5
  bytes). The contained items are the caller's problem — same as today.

If enough bytes: call the corresponding `MessagePackDecoder` method.
If not: return `NotEnoughData` (no bytes consumed).

**Pros**:
- Lightest implementation — reuses all existing decoder logic.
- Existing `MessagePackDecoder` stays untouched.
- No new reader type needed.

**Cons**:
- Caller still needs to know which type to expect (calls
  `streaming_str()`, `streaming_u32()`, etc.). Doesn't solve the
  "read the next value regardless of type" use case.
- Duplicates the format-byte-to-size logic that's implicit in the
  decoder. Could drift if the decoder changes.
- Doesn't help with nested structures — if you're midway through
  decoding an array's items and run out of data, you need your own
  bookkeeping for where you left off.

## Approach B: Custom Reader with Snapshot/Rollback

Create a reader class within the msgpack package that supports
transactional reads. The existing decoder methods expect
`buffered.Reader`, so this approach also requires new decoder methods
(or a new decoder type) that accept the custom reader.

**How it works**: The custom reader wraps incoming byte chunks and
maintains a cursor. Key addition: `save()` returns a snapshot of the
cursor position, and `restore(snapshot)` resets back to it. Bytes
aren't discarded until explicitly committed (or until the snapshot is
dropped).

```
let snap = reader.save()
try
  let value = MyDecoder.str(reader)?
  // success — snap can be dropped, bytes are consumed
else
  reader.restore(snap)
  // not enough data — cursor back to where we started
end
```

**Pros**:
- Can reuse the *logic* of the existing decoder (copy/adapt the methods
  to use the custom reader type).
- Clean try/rollback pattern — callers don't need to pre-calculate
  sizes.
- A custom reader could also serve other future needs (e.g., the
  high-level API mentioned in the README).

**Cons**:
- Still can't distinguish "not enough data" from "invalid format" —
  both raise `error`. After a rollback, the caller doesn't know whether
  to wait for more data or give up. Would need a secondary mechanism
  (e.g., a `last_error` field on the reader, or wrapping the decoder
  to peek-validate the format byte before attempting the full read).
- Requires writing and maintaining a reader implementation. The
  `buffered.Reader` is ~800 lines with careful chunk management and
  endianness handling.
- The adapted decoder methods would be near-duplicates of the existing
  ones, just accepting a different reader type.

**Variant — interface extraction**: If the custom reader and
`buffered.Reader` shared a common interface, the existing decoder could
potentially accept either. But `buffered.Reader` is a concrete class in
stdlib and doesn't implement a reading interface. This would require
either structural typing compatibility or stdlib changes (ruled out).

## Approach C: State Machine Streaming Decoder

A class that accepts data incrementally and emits complete decoded
values via a notify interface. Internally tracks parse state so it can
pause mid-value and resume when more data arrives.

**How it works**:

```
interface StreamingDecoderNotify
  fun ref on_nil() => None
  fun ref on_bool(value: Bool) => None
  fun ref on_uint_8(value: U8) => None
  fun ref on_uint_16(value: U16) => None
  // ... etc for all types
  fun ref on_str(value: String val) => None
  fun ref on_bin(value: Array[U8] val) => None
  fun ref on_array_start(size: U32) => None
  fun ref on_map_start(size: U32) => None
  fun ref on_ext(type_id: U8, data: Array[U8] val) => None
  fun ref on_error() => None
```

The decoder class holds a `Reader` internally and maintains a state
enum (conceptually):

- `_AwaitingType` — need at least 1 byte
- `_ReadingFixedValue(format, bytes_needed)` — have the type, need
  N more bytes for a fixed-size value
- `_ReadingLength(format, length_bytes_needed)` — need the length
  field before we know the payload size
- `_ReadingPayload(format, remaining)` — know the full size, waiting
  for payload bytes

When `append()` is called with new data, the decoder runs a loop:
check state, check if enough bytes are available (via `reader.size()`),
if yes consume and emit via notify, advance to next state. Stop when
insufficient data.

**Pros**:
- Cleanest streaming API — caller just feeds data and handles
  callbacks. No corruption possible.
- Naturally distinguishes "need more data" (just stops) from "invalid
  data" (`on_error` callback).
- Could also serve as the foundation for the high-level API — the
  notify interface gives the caller typed values without needing to know
  MessagePack format details.
- No pre-calculation or rollback needed — the state machine only
  consumes bytes it can fully process.

**Cons**:
- Most code to write. Doesn't reuse `MessagePackDecoder` at all.
- The state machine is a different programming model than the current
  synchronous pull-based API. Users who want "decode the next value"
  synchronously need to adapt.
- Nested structures (arrays of arrays, maps of maps) may need the
  notify callbacks to handle nesting, or the decoder needs an internal
  stack. This adds complexity.

## Approach D: Peek-Check + Pull API (Hybrid of A and C)

Combine approach A's peek-and-check with a unified "read next value"
method. A class that wraps a `Reader`, peeks to determine the type and
required bytes, and either returns a decoded value or `NotEnoughData`.

**How it works**:

```
// Possible value type
type MessagePackValue is
  ( None                          // nil
  | Bool
  | U8 | U16 | U32 | U64         // unsigned ints
  | I8 | I16 | I32 | I64         // signed ints
  | F32 | F64                     // floats
  | String val                    // strings
  | Array[U8] val                 // binary
  | MessagePackArray              // array header (contains size)
  | MessagePackMap                // map header (contains size)
  | MessagePackExt                // extension (type_id + data)
  | MessagePackTimestamp           // timestamp (sec + nsec)
  )

// Result type
type DecodeResult is
  (MessagePackValue | NotEnoughData | InvalidData)
```

The class has a `next(): DecodeResult` method that:

1. Peeks at format byte — if no bytes available, return `NotEnoughData`
2. Determines value type and calculates total bytes needed (peeking at
   length fields for variable-length types)
3. If insufficient bytes, return `NotEnoughData`
4. Consume the bytes and return the decoded value

**Pros**:
- Pull-based API — feels like the current decoder but streaming-safe.
- Clean union return type — no ambiguity between "need data" and
  "invalid data."
- Provides the "read next value" high-level API as a side effect.
- Simpler than a full state machine because it only attempts a decode
  when all bytes are present.

**Cons**:
- The `MessagePackValue` union type loses some specificity — you get
  back a union and need to match on it. The current API gives you the
  exact type you asked for.
- The peek-then-consume pattern means the format byte gets examined
  twice (once to peek, once during actual decode). Minor overhead.
- Same nested-structure concern as other approaches — array/map
  contents are still the caller's responsibility to track.
- Specific int types get a bit muddled: positive_fixint and uint_8
  both return U8 but are different formats. The union collapses them.
  This might or might not matter — need to decide whether the value
  type represents the *Pony type* or the *MessagePack format*.

## Nested Structures: A Shared Challenge

Arrays and maps in MessagePack are headers followed by N values (or
2*N for maps). The current decoder only reads headers — the caller is
responsible for then reading N items. In a streaming context, you might
get the array header but not all items.

Options:
- **Leave it to the caller** (all approaches): The streaming decoder
  handles individual values. The caller tracks "I'm 3 items into a
  5-item array" themselves. Simple for the library, more work for
  users.
- **Nesting-aware decoder** (approach C mainly): The state machine
  tracks an internal stack of containers. It doesn't emit an array
  until all its items are decoded. This gives the caller complete
  values but means the decoder must buffer an entire array/map in
  memory before emitting — which could be arbitrarily large.
- **Hybrid**: Emit `on_array_start(5)` ... five value callbacks ...
  `on_array_end()`. SAX-style event stream. The caller gets structure
  awareness without the decoder needing to buffer.

## Recommendation

Not making a recommendation yet — this document is for discussion. But
some observations:

- Approaches A and B feel like patches to make the current low-level API
  streaming-safe. They work but don't move toward the high-level API
  that's already identified as a TODO.
- Approaches C and D could serve double duty: streaming safety *and*
  the beginnings of a high-level API.
- Approach D (peek-check + pull) is probably the best balance of
  simplicity and capability. It's streaming-safe, provides a high-level
  "read next value" API, and is simpler than a full state machine.
- The error discrimination problem is solved most cleanly by approaches
  C and D, where the return type itself carries the distinction.
