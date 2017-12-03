# Pony-msgpack

A pure Pony implementation of the [MessagePack serialization format](http://msgpack.org/).

## Status

[![Build Status](https://travis-ci.org/SeanTAllen/pony-msgpack.svg?branch=master)](https://travis-ci.org/SeanTAllen/pony-msgpack)

Pony-msgpack is currently alpha software. It implements a low-level API for encoding and decoding data. Still to do:

- High-level API for a better programming experience
- Timestamp extension type

## Installation

* Install [pony-stable](https://github.com/ponylang/pony-stable)
* Update your `bundle.json`

```json
{ 
  "type": "github",
  "repo": "SeanTAllen/pony-msgpack",
  "tag": "0.1"
}
```

* `stable fetch` to fetch your dependencies
* `use "msgpack"` to include this package
* `stable env ponyc` to compile your application
