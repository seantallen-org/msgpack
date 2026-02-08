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

* `MessagePackEncoder` — Stateless encoding methods. Compact methods
  (`uint`, `int`, `str`, `bin`, `array`, `map`, `ext`, `timestamp`)
  automatically select the smallest wire format. Format-specific methods
  (`uint_8`, `uint_32`, `fixstr`, `str_8`, etc.) are available for
  explicit control.

* `MessagePackDecoder` — Stateless decoding methods. Compact methods
  (`uint`, `int`, `str`, `array`, `map`) accept any wire format within a
  format family. Format-specific methods are available when the caller
  knows the exact wire format. Assumes all data is available; not suitable
  for streaming.

* `MessagePackStreamingDecoder` — A streaming-safe decoder that peeks before
  consuming bytes. Returns `NotEnoughData` when more bytes are needed, with
  zero bytes consumed.

## Encoding and Decoding Scalar Values

Compact methods pick the smallest wire format automatically:

```pony
use "buffered"
use "msgpack"

// Encode
let w: Writer ref = Writer
MessagePackEncoder.nil(w)
MessagePackEncoder.bool(w, true)
MessagePackEncoder.uint(w, 42)       // positive_fixint (1 byte)
MessagePackEncoder.str(w, "hello")?  // fixstr (6 bytes)

// Transfer encoded bytes to a reader
let r: Reader ref = Reader
for bs in w.done().values() do
  r.append(bs)
end

// Decode — compact methods accept any format in the family
MessagePackDecoder.nil(r)?
let b = MessagePackDecoder.bool(r)?
let n = MessagePackDecoder.uint(r)?
let s = MessagePackDecoder.str(r)?
```

Format-specific methods (`uint_32`, `fixstr`, `str_8`, etc.) are available
when you need explicit control over the wire format.

## Encoding and Decoding Arrays

Array and map methods only write or read headers containing the element
count. The caller must encode or decode each element individually.

```pony
// Encode a 3-element array of U32
let w: Writer ref = Writer
MessagePackEncoder.array(w, 3)  // picks fixarray
MessagePackEncoder.uint(w, 1)
MessagePackEncoder.uint(w, 2)
MessagePackEncoder.uint(w, 3)

// Decode
let r: Reader ref = Reader
for bs in w.done().values() do
  r.append(bs)
end

let count = MessagePackDecoder.array(r)?
var i: U32 = 0
while i < count do
  let v = MessagePackDecoder.uint(r)?
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
MessagePackEncoder.map(w, 2)       // picks fixmap
MessagePackEncoder.str(w, "a")?
MessagePackEncoder.uint(w, 1)
MessagePackEncoder.str(w, "b")?
MessagePackEncoder.uint(w, 2)

// Decode
let r: Reader ref = Reader
for bs in w.done().values() do
  r.append(bs)
end

let count = MessagePackDecoder.map(r)?
var i: U32 = 0
while i < count do
  let key = MessagePackDecoder.str(r)?
  let value = MessagePackDecoder.uint(r)?
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
