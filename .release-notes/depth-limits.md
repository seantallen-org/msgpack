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
