// in your code this `use` statement would be:
// use "msgpack"
use "../../msgpack"
use "buffered"

actor Main
  """
  Demonstrates zero-copy decoding using `ZeroCopyReader` and
  `MessagePackZeroCopyDecoder`. Variable-length values (strings,
  binary data) are returned as `val` views into the reader's
  internal buffer instead of freshly allocated copies.

  This avoids allocation for decoded strings and byte arrays
  when the data falls within a single chunk in the reader. The
  trade-off is that decoded values hold a reference to the
  source chunk, keeping it in memory until the decoded value is
  discarded.
  """
  new create(env: Env) =>
    try
      _zero_copy_decode(env)?
    else
      env.out.print("error during zero-copy decode")
    end

  fun _zero_copy_decode(env: Env) ? =>
    // Encode several values using the standard encoder
    let w: Writer ref = Writer
    MessagePackEncoder.nil(w)
    MessagePackEncoder.bool(w, false)
    MessagePackEncoder.uint(w, 256)
    MessagePackEncoder.str(w, "zero-copy string")?

    // Transfer encoded bytes into a ZeroCopyReader
    let r = ZeroCopyReader
    for bs in w.done().values() do
      r.append(bs)
    end

    // Decode using the zero-copy decoder
    MessagePackZeroCopyDecoder.nil(r)?
    env.out.print("decoded nil")

    env.out.print("decoded bool: "
      + MessagePackZeroCopyDecoder.bool(r)?.string())

    env.out.print("decoded uint: "
      + MessagePackZeroCopyDecoder.uint(r)?.string())

    // str() returns String val (a view), not String iso^
    env.out.print("decoded str: "
      + MessagePackZeroCopyDecoder.str(r)?)
