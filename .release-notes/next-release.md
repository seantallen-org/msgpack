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

