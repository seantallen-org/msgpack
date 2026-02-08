// in your code this `use` statement would be:
// use "msgpack"
use "../../msgpack"
use "buffered"

actor Main
  """
  Demonstrates `MessagePackDecoder.skip` for forward-compatible
  protocol handling. When a map contains fields your code
  doesn't recognize, `skip` advances past them without needing
  to know their type or structure.

  This is useful for evolving protocols: the sender can add new
  fields without breaking receivers that don't know about them.
  """
  new create(env: Env) =>
    try
      _skip_unknown_fields(env)?
    else
      env.out.print("error during skip example")
    end

  fun _skip_unknown_fields(env: Env) ? =>
    // Encode a map with 3 fields
    let w: Writer ref = Writer
    MessagePackEncoder.map(w, 3)
    MessagePackEncoder.str(w, "name")?
    MessagePackEncoder.str(w, "alice")?
    MessagePackEncoder.str(w, "age")?
    MessagePackEncoder.uint(w, 30)
    MessagePackEncoder.str(w, "email")?
    MessagePackEncoder.str(w, "a@b.c")?

    // Transfer to reader
    let r: Reader ref = Reader
    for bs in w.done().values() do
      r.append(bs)
    end

    // Decode the map, extracting only "name" and
    // skipping everything else
    let map_size = MessagePackDecoder.map(r)?
    var name: (String | None) = None
    var i: U32 = 0
    while i < map_size do
      let key = MessagePackDecoder.str(r)?
      if (consume key) == "name" then
        name = MessagePackDecoder.str(r)?
      else
        // Skip the value for any unrecognized key
        MessagePackDecoder.skip(r)?
      end
      i = i + 1
    end

    match name
    | let n: String =>
      env.out.print("extracted name: " + n)
    | None =>
      env.out.print("name field not found")
    end
