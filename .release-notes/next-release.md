## Add streaming-safe MessagePack decoder

Add `MessagePackStreamingDecoder`, a new decoder class designed for use with streaming data sources. Unlike `MessagePackDecoder`, which assumes all data is available and will corrupt the reader on partial reads, the streaming decoder peeks at format bytes and length fields before consuming any data. If insufficient data is available, it returns `NotEnoughData` with zero bytes consumed, allowing the caller to append more data and retry.

### Example Usage

```pony
// Decode values as chunks of data arrive.
// Call append() with each chunk, then next() to attempt decoding.
// next() returns NotEnoughData if more bytes are needed,
// InvalidData if the stream is corrupt, or a decoded value.
let sd = MessagePackStreamingDecoder
sd.append(chunk)

match sd.next()
| let v: U32 => // got a value
| let s: String val => // got a string
| let t: MessagePackTimestamp => // got a timestamp
| let a: MessagePackArray => // array header; read a.size elements
| let m: MessagePackMap => // map header; read m.size key-value pairs
| NotEnoughData => // append more data and retry
| InvalidData => // stream is corrupt
end
```
## Change timestamp nsec type from I64 to U32

The nanoseconds component of decoded timestamps is now `U32` instead of `I64`. This affects `MessagePackDecoder.timestamp()` (return type changed from `(I64, I64)` to `(I64, U32)`) and `MessagePackTimestamp.nsec` (field type changed from `I64` to `U32`).

This is a breaking change. Code that destructures the decoder's return value or reads the `nsec` field will need to account for the new type. The encoder already accepted `U32` for nanoseconds, so encoding code is unaffected.

### Before

```pony
// MessagePackDecoder.timestamp()
(let sec: I64, let nsec: I64) =
  MessagePackDecoder.timestamp(reader)?

// MessagePackTimestamp.nsec
let ts: MessagePackTimestamp = ...
let nsec: I64 = ts.nsec
```

### After

```pony
// MessagePackDecoder.timestamp()
(let sec: I64, let nsec: U32) =
  MessagePackDecoder.timestamp(reader)?

// MessagePackTimestamp.nsec
let ts: MessagePackTimestamp = ...
let nsec: U32 = ts.nsec
```

