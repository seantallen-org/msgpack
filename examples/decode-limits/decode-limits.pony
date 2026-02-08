// in your code this `use` statement would be:
// use "msgpack"
use "../../msgpack"
use "buffered"

actor Main
  """
  Demonstrates `MessagePackDecodeLimits` with the streaming
  decoder. When decoding data from untrusted sources, limits
  prevent denial-of-service attacks where a malicious payload
  claims enormous sizes for strings, binary data, or container
  counts.

  This example sets a tight `max_str_len` of 10 bytes, then
  shows that a short string decodes successfully while a longer
  string is rejected with `LimitExceeded`.
  """
  new create(env: Env) =>
    try
      _decode_limits(env)?
    else
      env.out.print("error during decode-limits example")
    end

  fun _decode_limits(env: Env) ? =>
    let limits = MessagePackDecodeLimits(
      where max_str_len' = 10)
    let sd = MessagePackStreamingDecoder(limits)

    // Encode a short string (5 bytes — within limit)
    let w1: Writer ref = Writer
    MessagePackEncoder.str(w1, "hello")?
    for bs in w1.done().values() do
      sd.append(bs)
    end

    match sd.next()
    | let s: String val =>
      env.out.print("short string ok: " + s)
    | LimitExceeded =>
      env.out.print("short string rejected (unexpected)")
    end

    // Encode a long string (26 bytes — exceeds limit)
    let w2: Writer ref = Writer
    MessagePackEncoder.str(w2, "abcdefghijklmnopqrstuvwxyz")?
    for bs in w2.done().values() do
      sd.append(bs)
    end

    match sd.next()
    | let s: String val =>
      env.out.print("long string ok (unexpected): " + s)
    | LimitExceeded =>
      env.out.print(
        "long string rejected: limit exceeded")
    end
