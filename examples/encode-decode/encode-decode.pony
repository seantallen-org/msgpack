// in your code this `use` statement would be:
// use "msgpack"
use "../../msgpack"
use "buffered"

actor Main
  """
  Demonstrates encoding and decoding MessagePack values using
  the compact API. Encodes nil, bool, uint, int, str, an array,
  and a map, then decodes each in the same order.
  """
  new create(env: Env) =>
    try
      _encode_and_decode(env)?
    else
      env.out.print("error during encode/decode")
    end

  fun _encode_and_decode(env: Env) ? =>
    let w: Writer ref = Writer
    let r: Reader ref = Reader

    // Encode values into the writer
    MessagePackEncoder.nil(w)
    MessagePackEncoder.bool(w, true)
    MessagePackEncoder.uint(w, 42)
    MessagePackEncoder.int(w, -10)
    MessagePackEncoder.str(w, "hello msgpack")?

    // Encode a 3-element array of uints
    MessagePackEncoder.array(w, 3)
    MessagePackEncoder.uint(w, 1)
    MessagePackEncoder.uint(w, 2)
    MessagePackEncoder.uint(w, 3)

    // Encode a 2-entry map: str -> uint
    MessagePackEncoder.map(w, 2)
    MessagePackEncoder.str(w, "x")?
    MessagePackEncoder.uint(w, 10)
    MessagePackEncoder.str(w, "y")?
    MessagePackEncoder.uint(w, 20)

    // Transfer encoded bytes to the reader
    for bs in w.done().values() do
      r.append(bs)
    end

    // Decode values in the same order they were encoded
    MessagePackDecoder.nil(r)?
    env.out.print("decoded nil")

    env.out.print("decoded bool: "
      + MessagePackDecoder.bool(r)?.string())

    env.out.print("decoded uint: "
      + MessagePackDecoder.uint(r)?.string())

    env.out.print("decoded int: "
      + MessagePackDecoder.int(r)?.string())

    env.out.print("decoded str: "
      + MessagePackDecoder.str(r)?)

    // Decode the array header, then each element
    let arr_size = MessagePackDecoder.array(r)?
    env.out.write("decoded array: [")
    var i: U32 = 0
    while i < arr_size do
      if i > 0 then env.out.write(", ") end
      env.out.write(MessagePackDecoder.uint(r)?.string())
      i = i + 1
    end
    env.out.print("]")

    // Decode the map header, then each key-value pair
    let map_size = MessagePackDecoder.map(r)?
    i = 0
    while i < map_size do
      let key = MessagePackDecoder.str(r)?
      let value = MessagePackDecoder.uint(r)?
      env.out.print("decoded map entry: "
        + consume key + " = " + value.string())
      i = i + 1
    end
