// in your code this `use` statement would be:
// use "msgpack"
use "../../msgpack"
use "buffered"

actor Main
  """
  Demonstrates the streaming decoder with containers, mixed
  types, and realistic chunking. Encodes a map
  `{"name": "alice", "age": 30}`, splits the bytes into two
  chunks, and feeds them incrementally. The decoder returns
  `NotEnoughData` when a chunk boundary falls mid-value.
  """
  new create(env: Env) =>
    try
      _streaming_decode(env)?
    else
      env.out.print("error during streaming decode")
    end

  fun _streaming_decode(env: Env) ? =>
    // Encode a map: {"name": "alice", "age": 30}
    let w: Writer ref = Writer
    MessagePackEncoder.map(w, 2)
    MessagePackEncoder.str(w, "name")?
    MessagePackEncoder.str(w, "alice")?
    MessagePackEncoder.str(w, "age")?
    MessagePackEncoder.uint(w, 30)

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

    // Split at the midpoint to simulate chunked arrival
    let mid = encoded.size() / 2
    let chunk1 = encoded.trim(0, mid)
    let chunk2 = encoded.trim(mid)

    let sd = MessagePackStreamingDecoder

    // Feed the first chunk and decode until we need more
    env.out.print("--- feeding chunk 1 ("
      + mid.string() + " bytes) ---")
    sd.append(chunk1)
    _decode_loop(sd, env)

    // Feed the second chunk and decode the rest
    env.out.print("--- feeding chunk 2 ("
      + (encoded.size() - mid).string() + " bytes) ---")
    sd.append(chunk2)
    _decode_loop(sd, env)

  fun _decode_loop(
    sd: MessagePackStreamingDecoder ref,
    env: Env)
  =>
    var done = false
    while not done do
      match sd.next()
      | let m: MessagePackMap =>
        env.out.print("map header: "
          + m.size.string() + " entries")
      | let s: String val =>
        env.out.print("string: " + s)
      | let v: U8 =>
        env.out.print("uint8: " + v.string())
      | NotEnoughData =>
        env.out.print("need more data")
        done = true
      | InvalidData =>
        env.out.print("invalid data — stream corrupt")
        done = true
      | LimitExceeded =>
        env.out.print("limit exceeded")
        done = true
      else
        env.out.print("other value")
      end
    end
