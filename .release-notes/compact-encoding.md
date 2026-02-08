## Add compact encoding and decoding methods

`MessagePackEncoder` and `MessagePackDecoder` now provide compact methods that automatically select the smallest wire format for a given value, per the MessagePack spec recommendation. The format-specific methods remain available for explicit control.

### Encoder

```pony
let w: Writer ref = Writer

// Integer — picks positive_fixint, uint_8, ..., or uint_64
MessagePackEncoder.uint(w, 42)

// Signed — uses unsigned formats for positive values
MessagePackEncoder.int(w, -100)

// String — picks fixstr, str_8, str_16, or str_32
MessagePackEncoder.str(w, "hello")?

// Binary — picks bin_8, bin_16, or bin_32
MessagePackEncoder.bin(w, data)?

// Array header — picks fixarray, array_16, or array_32
MessagePackEncoder.array(w, 3)

// Map header — picks fixmap, map_16, or map_32
MessagePackEncoder.map(w, 2)

// Extension — prefers fixext for sizes 1/2/4/8/16
MessagePackEncoder.ext(w, ext_type, data)?

// Timestamp — picks timestamp_32, _64, or _96
MessagePackEncoder.timestamp(w, seconds, nanoseconds)?
```

### Decoder

```pony
let b: Reader ref = Reader

// Reads any unsigned integer format
let n: U64 = MessagePackDecoder.uint(b)?

// Reads any signed or unsigned integer format
let i: I64 = MessagePackDecoder.int(b)?

// str() now handles fixstr in addition to str_8/str_16/str_32
// (previously, fixstr required calling fixstr() directly)
let s: String iso^ = MessagePackDecoder.str(b)?

// Reads any array header format
let count: U32 = MessagePackDecoder.array(b)?

// Reads any map header format
let pairs: U32 = MessagePackDecoder.map(b)?
```
