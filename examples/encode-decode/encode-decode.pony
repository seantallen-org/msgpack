// in your code this `use` statement would be:
// use "msgpack"
use "../../msgpack"
use "buffered"

actor Main
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
    MessagePackEncoder.uint_32(w, 42)
    MessagePackEncoder.fixstr(w, "hello msgpack")?

    // Transfer encoded bytes to the reader
    for bs in w.done().values() do
      r.append(bs)
    end

    // Decode values in the same order they were encoded
    MessagePackDecoder.nil(r)?
    env.out.print("decoded nil")

    env.out.print("decoded bool: "
      + MessagePackDecoder.bool(r)?.string())

    env.out.print("decoded u32: "
      + MessagePackDecoder.u32(r)?.string())

    env.out.print("decoded fixstr: "
      + MessagePackDecoder.fixstr(r)?)
