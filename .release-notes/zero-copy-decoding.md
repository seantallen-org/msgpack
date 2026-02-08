## Add zero-copy decoding

Strings, binary data, and extensions can now be decoded without copying
payload bytes. `ZeroCopyReader` + `MessagePackZeroCopyDecoder` return
shared views into the reader's buffer instead of allocating fresh arrays.

`MessagePackStreamingDecoder` now uses zero-copy decoding internally —
existing callers benefit automatically with no code changes.

For low-level decoding where you want zero-copy directly:

```pony
use "buffered"
use "msgpack"

let w: Writer ref = Writer
MessagePackEncoder.str(w, "hello")?

let r = ZeroCopyReader
for bs in w.done().values() do
  r.append(bs)
end

let s = MessagePackZeroCopyDecoder.str(r)?
```

`ZeroCopyReader` is specific to this package and is not interoperable
with APIs that expect `buffered.Reader`.
