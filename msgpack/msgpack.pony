/*

Copyright 2017 The Pony MessagePack Developers

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

*/

"""
# Pony MessagePack

Pure Pony implementation of the [MessagePack](https://msgpack.org/)
serialization format.

Three public APIs are available:

* `MessagePackEncoder` — Stateless encoding methods. Each takes a `Writer`
  and encodes a single value.

* `MessagePackDecoder` — Stateless decoding methods. Each takes a
  `Reader ref` and decodes a single value. Assumes all data is available;
  not suitable for streaming.

* `MessagePackStreamingDecoder` — A streaming-safe decoder that peeks before
  consuming bytes. Returns `NotEnoughData` when more bytes are needed, with
  zero bytes consumed.

## Encoding and Decoding Scalar Values

```pony
use "buffered"
use "msgpack"

// Encode
let w: Writer ref = Writer
MessagePackEncoder.nil(w)
MessagePackEncoder.bool(w, true)
MessagePackEncoder.uint_32(w, 42)
MessagePackEncoder.fixstr(w, "hello")?

// Transfer encoded bytes to a reader
let r: Reader ref = Reader
for bs in w.done().values() do
  r.append(bs)
end

// Decode in the same order
MessagePackDecoder.nil(r)?
let b = MessagePackDecoder.bool(r)?
let n = MessagePackDecoder.u32(r)?
let s = MessagePackDecoder.fixstr(r)?
```

## Encoding and Decoding Arrays

Array and map methods only write or read headers containing the element
count. The caller must encode or decode each element individually.

```pony
// Encode a 3-element array of U32
let w: Writer ref = Writer
MessagePackEncoder.fixarray(w, 3)?
MessagePackEncoder.uint_32(w, 1)
MessagePackEncoder.uint_32(w, 2)
MessagePackEncoder.uint_32(w, 3)

// Decode
let r: Reader ref = Reader
for bs in w.done().values() do
  r.append(bs)
end

let count = MessagePackDecoder.fixarray(r)?
var i: U8 = 0
while i < count do
  let v = MessagePackDecoder.u32(r)?
  // use v
  i = i + 1
end
```

## Encoding and Decoding Maps

Map entries are key-value pairs. The header specifies the number of pairs.
Keys and values are encoded alternately.

```pony
// Encode a 2-entry map: "a" => 1, "b" => 2
let w: Writer ref = Writer
MessagePackEncoder.fixmap(w, 2)?
MessagePackEncoder.fixstr(w, "a")?
MessagePackEncoder.uint_32(w, 1)
MessagePackEncoder.fixstr(w, "b")?
MessagePackEncoder.uint_32(w, 2)

// Decode
let r: Reader ref = Reader
for bs in w.done().values() do
  r.append(bs)
end

let count = MessagePackDecoder.fixmap(r)?
var i: U8 = 0
while i < count do
  let key = MessagePackDecoder.fixstr(r)?
  let value = MessagePackDecoder.u32(r)?
  // use key and value
  i = i + 1
end
```

## Streaming Decoder

`MessagePackStreamingDecoder` is safe for incremental data. It returns
`MessagePackArray` or `MessagePackMap` header objects for containers; the
caller then reads the elements.

```pony
let sd = MessagePackStreamingDecoder
sd.append(data)

match sd.next()
| None => None // decoded nil
| let v: U32 => None // decoded a U32
| let a: MessagePackArray =>
  // read a.size elements
  var i: U32 = 0
  while i < a.size do
    match sd.next()
    | let v: U32 => None // use v
    end
    i = i + 1
  end
| let m: MessagePackMap =>
  // read m.size key-value pairs
  var i: U32 = 0
  while i < m.size do
    match sd.next()
    | let key: String val => None
    end
    match sd.next()
    | let value: U32 => None
    end
    i = i + 1
  end
| NotEnoughData => None // need more bytes
| InvalidData => None // stream is corrupt
end
```
"""
