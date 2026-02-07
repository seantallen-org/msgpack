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
