# msgpack

A pure Pony implementation of the [MessagePack serialization format](http://msgpack.org/).

## Status

msgpack is currently beta software. It provides compact encoding/decoding methods that automatically select the smallest wire format, format-specific primitives for explicit control, and a streaming-safe decoder for incremental data sources.

## Installation

* Install [corral](https://github.com/ponylang/corral)
* `corral add github.com/seantallen-org/msgpack.git --version 0.2.5`
* `corral fetch` to fetch your dependencies
* `use "msgpack"` to include this package
* `corral run -- ponyc` to compile your application

## Usage

### Encoding and Decoding

`MessagePackEncoder` and `MessagePackDecoder` provide compact methods that automatically select the smallest wire format for a given value. Encode values into a `Writer`, transfer the bytes to a `Reader`, then decode in the same order.

```pony
use "msgpack"
use "buffered"

// Encode — compact methods pick the smallest wire format
let w: Writer ref = Writer
MessagePackEncoder.nil(w)
MessagePackEncoder.bool(w, true)
MessagePackEncoder.uint(w, 42)           // positive_fixint (1 byte)
MessagePackEncoder.str(w, "hello")?      // fixstr (6 bytes)

// Transfer encoded bytes to the reader
let r: Reader ref = Reader
for bs in w.done().values() do
  r.append(bs)
end

// Decode — compact methods accept any format in the family
MessagePackDecoder.nil(r)?
MessagePackDecoder.bool(r)?   // true
MessagePackDecoder.uint(r)?   // 42
MessagePackDecoder.str(r)?    // "hello"
```

Format-specific methods (`uint_8`, `uint_32`, `fixstr`, `str_8`, etc.) are available when you need explicit control over the wire format.

### Streaming Decoder

`MessagePackStreamingDecoder` is designed for use with data that arrives incrementally. It peeks at format bytes and length fields before consuming any data. If insufficient data is available, it returns `NotEnoughData` with zero bytes consumed, allowing the caller to append more data and retry.

```pony
use "msgpack"

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

See the `examples/` directory for runnable demos.

## API Documentation

[https://seantallen-org.github.io/msgpack/](https://seantallen-org.github.io/msgpack/)
