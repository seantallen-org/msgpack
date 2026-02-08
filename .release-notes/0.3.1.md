## Add decoding size limits to streaming decoder

`MessagePackStreamingDecoder` now enforces size limits on variable-length values to protect against denial-of-service attacks. By default, conservative limits are applied: 1 MB for str/bin/ext data and 131,072 for array/map element counts.

When a value exceeds its limit, `next()` returns `LimitExceeded` with no bytes consumed.

```pony
// Default limits (1 MB str/bin/ext, 131K array/map):
let sd = MessagePackStreamingDecoder

// Custom limits:
let limits = MessagePackDecodeLimits(
  where max_str_len' = 4096)
let sd = MessagePackStreamingDecoder(limits)

// No limits:
let sd = MessagePackStreamingDecoder(
  MessagePackDecodeLimits.unlimited())
```

Existing code using `MessagePackStreamingDecoder` with no arguments gets limit protection automatically. The `DecodeResult` type now includes `LimitExceeded`, so `match` expressions on `DecodeResult` need a new branch:

```pony
// Before:
match decoder.next()
| let v: U32 => // handle value
| NotEnoughData => // wait for more data
| InvalidData => // abort
end

// After:
match decoder.next()
| let v: U32 => // handle value
| NotEnoughData => // wait for more data
| LimitExceeded => // value too large, reject
| InvalidData => // abort
end
```

## Add container depth limits to streaming decoder

`MessagePackStreamingDecoder` now tracks container nesting depth and enforces a configurable limit. When decoding nested arrays or maps would exceed the limit, `next()` returns `LimitExceeded` with no bytes consumed. This protects against stack overflow and exponential work from deeply nested container structures.

The default limit is 512 levels of nesting. Depth tracking is automatic — the decoder increments depth when returning `MessagePackArray` or `MessagePackMap` headers and decrements as elements are consumed.

```pony
// Default limits include max_depth=512:
let sd = MessagePackStreamingDecoder

// Custom depth limit:
let limits = MessagePackDecodeLimits(
  where max_depth' = 16)
let sd = MessagePackStreamingDecoder(limits)

// Query current nesting depth:
sd.depth()
```

## Add skip method for advancing past values without decoding

`MessagePackDecoder` and `MessagePackStreamingDecoder` now support
skipping values without decoding them. This enables forward-compatible
protocols where consumers can gracefully handle unknown fields.

`MessagePackDecoder.skip` advances the reader past one complete
value, including nested containers:

```pony
let count = MessagePackDecoder.map(reader)?
var i: U32 = 0
while i < count do
  let key = MessagePackDecoder.str(reader)?
  match consume key
  | "name" => name = MessagePackDecoder.str(reader)?
  else
    MessagePackDecoder.skip(reader)?
  end
  i = i + 1
end
```

`MessagePackStreamingDecoder.skip` provides the streaming-safe
variant, returning `SkipResult` (`None` on success, `NotEnoughData`,
`InvalidData`, or `LimitExceeded`). A new `max_skip_values` field
on `MessagePackDecodeLimits` bounds the number of values traversed
during a single skip (default: 1,048,576).

## Add opt-in UTF-8 validation for str format values

The MessagePack spec defines str format values as UTF-8 strings, but previously this library treated them as opaque byte sequences without validation. Opt-in UTF-8 validation is now available at every layer.

Validating `_utf8` method variants are available on all encoders and decoders. They work identically to their non-validating counterparts but error when the bytes are not valid UTF-8:

```pony
// Encode — errors if bytes are not valid UTF-8
MessagePackEncoder.str_utf8(w, value)?

// Decode — errors if decoded bytes are not valid UTF-8
let s = MessagePackDecoder.str_utf8(reader)?
let s = MessagePackZeroCopyDecoder.str_utf8(reader)?
```

Format-specific variants are also available: `fixstr_utf8`, `str_8_utf8`, `str_16_utf8`, and `str_32_utf8`.

The streaming decoder accepts a `validate_utf8` constructor option. When enabled, str values with invalid UTF-8 return `InvalidUtf8` — a new member of the `DecodeResult` union, distinct from `InvalidData`. The MessagePack framing is valid and decoding can continue:

```pony
let sd = MessagePackStreamingDecoder(
  where validate_utf8' = true)
match sd.next()
| let s: String val => // valid UTF-8 string
| InvalidUtf8 => // invalid UTF-8, stream is fine
end
```

A public `MessagePackValidateUTF8` primitive supports the "decode then validate" pattern for callers who need access to the raw bytes on validation failure:

```pony
let s = MessagePackDecoder.str(reader)?
if not MessagePackValidateUTF8(s) then
  // s still available — log, reject, or use as raw bytes
end
```

Existing non-validating methods are unchanged. The default behavior is preserved for backward compatibility.

