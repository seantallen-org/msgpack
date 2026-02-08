// in your code this `use` statement would be:
// use "msgpack"
use "../../msgpack"
use "buffered"

actor Main
  """
  Demonstrates three approaches to UTF-8 validation when
  encoding or decoding MessagePack str values.

  1. **Validate on encode** — `str_utf8` rejects invalid bytes
     before they enter the wire format.
  2. **Validate on streaming decode** — the streaming decoder's
     `validate_utf8` option returns `InvalidUtf8` for invalid
     strings.
  3. **Decode then validate manually** — decode without
     validation, then check with `MessagePackValidateUTF8`.
     The raw bytes remain accessible on failure.
  """
  new create(env: Env) =>
    _validate_on_encode(env)
    _validate_on_streaming_decode(env)
    _validate_manually(env)

  fun _validate_on_encode(env: Env) =>
    """
    Use `str_utf8` to reject invalid bytes at encode time.
    """
    env.out.print("--- validate on encode ---")

    let valid: Array[U8] val =
      recover val [as U8: 0x68; 0x69] end  // "hi"
    let invalid: Array[U8] val =
      // "hello" + 0xFF (invalid UTF-8 byte)
      recover val
        [as U8: 0x68; 0x65; 0x6C; 0x6C; 0x6F; 0xFF]
      end

    let w: Writer ref = Writer
    try
      MessagePackEncoder.str_utf8(w, valid)?
      env.out.print("valid bytes: encoded ok")
    else
      env.out.print("valid bytes: rejected (unexpected)")
    end

    try
      MessagePackEncoder.str_utf8(w, invalid)?
      env.out.print("invalid bytes: encoded (unexpected)")
    else
      env.out.print("invalid bytes: rejected at encode")
    end

  fun _validate_on_streaming_decode(env: Env) =>
    """
    Enable UTF-8 validation in the streaming decoder.
    """
    env.out.print("--- validate on streaming decode ---")

    // Encode invalid bytes using non-validating str
    let invalid: Array[U8] val =
      recover val
        [as U8: 0x68; 0x65; 0x6C; 0x6C; 0x6F; 0xFF]
      end
    let w: Writer ref = Writer
    try
      MessagePackEncoder.str(w, invalid)?
    else
      env.out.print("encode error (unexpected)")
      return
    end

    // Decode with validation enabled
    let sd = MessagePackStreamingDecoder(
      where validate_utf8' = true)
    for bs in w.done().values() do
      sd.append(bs)
    end

    match sd.next()
    | let s: String val =>
      env.out.print("decoded ok (unexpected): " + s)
    | InvalidUtf8 =>
      env.out.print(
        "invalid UTF-8 detected by streaming decoder")
    end

  fun _validate_manually(env: Env) =>
    """
    Decode without validation, then check manually. The raw
    bytes remain accessible on failure.
    """
    env.out.print("--- decode then validate manually ---")

    // Encode invalid bytes using non-validating str
    let invalid: Array[U8] val =
      recover val
        [as U8: 0x68; 0x65; 0x6C; 0x6C; 0x6F; 0xFF]
      end
    let w: Writer ref = Writer
    try
      MessagePackEncoder.str(w, invalid)?
    else
      env.out.print("encode error (unexpected)")
      return
    end

    let r: Reader ref = Reader
    for bs in w.done().values() do
      r.append(bs)
    end

    try
      let s: String val = MessagePackDecoder.str(r)?
      if MessagePackValidateUTF8(s) then
        env.out.print("valid UTF-8: " + s)
      else
        env.out.print("invalid UTF-8 detected manually"
          + " (raw bytes still available, size="
          + s.size().string() + ")")
      end
    else
      env.out.print("decode error (unexpected)")
    end
