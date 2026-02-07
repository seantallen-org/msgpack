# msgpack

A pure Pony implementation of the [MessagePack serialization format](http://msgpack.org/).

## Status

msgpack is currently beta software. It provides low-level encoding/decoding primitives and a streaming-safe decoder for incremental data sources. Still to do:

* High-level API for a better programming experience

## Installation

* Install [corral](https://github.com/ponylang/corral)
* `corral add github.com/seantallen-org/msgpack.git --version 0.2.5`
* `corral fetch` to fetch your dependencies
* `use "msgpack"` to include this package
* `corral run -- ponyc` to compile your application

## Usage

### Encoding and Decoding

`MessagePackEncoder` and `MessagePackDecoder` provide direct access to each MessagePack format type. Encode values into a `Writer`, transfer the bytes to a `Reader`, then decode in the same order.

```pony
use "msgpack"
use "buffered"

// Encode
let w: Writer ref = Writer
MessagePackEncoder.nil(w)
MessagePackEncoder.bool(w, true)
MessagePackEncoder.uint_32(w, 42)
MessagePackEncoder.fixstr(w, "hello msgpack")?

// Transfer encoded bytes to the reader
let r: Reader ref = Reader
for bs in w.done().values() do
  r.append(bs)
end

// Decode in the same order
MessagePackDecoder.nil(r)?
MessagePackDecoder.bool(r)?    // true
MessagePackDecoder.u32(r)?     // 42
MessagePackDecoder.fixstr(r)?  // "hello msgpack"
```

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
