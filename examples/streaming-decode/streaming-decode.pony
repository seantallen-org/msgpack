// in your code this `use` statement would be:
// use "msgpack"
use "../../msgpack"
use "buffered"

actor Main
  """
  Demonstrates the streaming decoder's behavior when data
  arrives incrementally. A uint_32 value (5 bytes) is fed
  one byte at a time. The decoder returns NotEnoughData
  until all bytes have arrived.
  """
  new create(env: Env) =>
    try
      _streaming_decode(env)?
    else
      env.out.print("error during streaming decode")
    end

  fun _streaming_decode(env: Env) ? =>
    // Encode a uint_32 (5 bytes: 1 format + 4 data)
    let w: Writer ref = Writer
    MessagePackEncoder.uint_32(w, 12345)

    // Collect encoded bytes into a contiguous array
    let encoded = recover val
      let out = Array[U8]
      for chunk in w.done().values() do
        match chunk
        | let a: Array[U8] val => out.append(a)
        | let s: String val => out.append(s.array())
        end
      end
      out
    end

    // Feed bytes one at a time to the streaming decoder
    let sd = MessagePackStreamingDecoder
    var i: USize = 0
    while i < encoded.size() do
      sd.append(
        recover val [as U8: encoded(i)?] end)

      match sd.next()
      | NotEnoughData =>
        env.out.print("byte " + (i + 1).string()
          + " of " + encoded.size().string()
          + ": need more data")
      | let v: U32 =>
        env.out.print("byte " + (i + 1).string()
          + " of " + encoded.size().string()
          + ": decoded U32 = " + v.string())
      end

      i = i + 1
    end
