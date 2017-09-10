# Pony-msgpack

A pure Pony implementation of the [MessagePack serialization format](http://msgpack.org/).

## Status

[![Build Status](https://travis-ci.org/SeanTAllen/pony-msgpack.svg?branch=master)](https://travis-ci.org/SeanTAllen/pony-msgpack)

Pony-msgpack is currently alpha software. It implements a low-level API for encoding data. Still to do:

- Encoding array, map and extension types
- Decoding of encoded MessagePack data
- High-level API for a better programming experience

## Installation

* Install [pony-stable](https://github.com/ponylang/pony-stable)
* Update your `bundle.json`

```json
{ 
  "type": "github",
  "repo": "SeanTAllen/pony-msgpack"
}
```

* `stable fetch` to fetch your dependencies
* `stable env ponyc` to compile your application
