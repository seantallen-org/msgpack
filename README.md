# Pony-msgpack

A pure Pony implementation of the [MessagePack serialization format](http://msgpack.org/).

## Status

[![CircleCI](https://circleci.com/gh/SeanTAllen/pony-msgpack.svg?style=svg)](https://circleci.com/gh/SeanTAllen/pony-msgpack)

Pony-msgpack is currently alpha software. It implements a low-level API for encoding and decoding data. Still to do:

- High-level API for a better programming experience

## Installation

* Install [pony-stable](https://github.com/ponylang/pony-stable)
* Update your `bundle.json`

```json
{ 
  "type": "github",
  "repo": "SeanTAllen/pony-msgpack",
  "tag": "0.2.0"
}
```

* `stable fetch` to fetch your dependencies
* `use "msgpack"` to include this package
* `stable env ponyc` to compile your application
