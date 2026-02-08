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
