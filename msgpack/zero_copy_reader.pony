/*

Copyright 2017 The Pony MessagePack Developers

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

*/

class ZeroCopyReader
  """
  A reader optimized for zero-copy extraction of byte ranges.
  Returns `val` views into the internal buffer instead of
  copying into fresh `iso` arrays.

  Zero-copy succeeds when the requested range falls within a
  single internal chunk. When data spans chunk boundaries, the
  reader falls back to copying — no worse than `buffered.Reader`.

  This reader is specific to the msgpack package and is not
  interoperable with APIs that expect `buffered.Reader`. Use it
  with `MessagePackZeroCopyDecoder` for zero-copy decoding, or
  use `MessagePackStreamingDecoder` which uses it internally.

  Decoded values returned via `block()` may hold references to
  the reader's internal chunks. As long as a decoded value is
  live, its source chunk stays in memory. For most use cases
  (decode, process, discard) this is not a concern. Callers who
  cache decoded values should be aware of this lifetime
  relationship.
  """
  embed _chunks: Array[(Array[U8] val, USize)]
  var _available: USize = 0

  new create() =>
    _chunks = Array[(Array[U8] val, USize)]

  fun size(): USize =>
    """
    Return the number of available bytes.
    """
    _available

  fun ref append(data: ByteSeq) =>
    """
    Add a chunk of data. The reader holds a `val` reference to
    the chunk's underlying array. No copy is performed.
    """
    let data_array =
      match data
      | let data': Array[U8] val => data'
      | let data': String => data'.array()
      end

    _available = _available + data_array.size()
    _chunks.push((data_array, 0))

  fun ref block(len: USize): Array[U8] val ? =>
    """
    Return `len` bytes. If the range falls within a single
    chunk, returns a `trim`'d view (zero-copy). If it spans
    chunks, copies into a new array (fallback).
    """
    if _available < len then error end
    if len == 0 then
      return recover val Array[U8] end
    end
    _available = _available - len

    (let data, let offset) = _chunks(0)?
    let avail = data.size() - offset
    if avail >= len then
      // Fast path: single chunk, zero-copy
      let result = data.trim(offset, offset + len)
      if avail == len then
        _chunks.shift()?
      else
        _chunks(0)? = (data, offset + len)
      end
      result
    else
      // Slow path: spans chunks, must copy
      _block_copy(len)?
    end

  fun ref skip(n: USize) ? =>
    """
    Skip `n` bytes. Errors if fewer than `n` bytes are
    available.
    """
    if _available >= n then
      _available = _available - n
      var rem = n

      while rem > 0 do
        (var data, var offset) = _chunks(0)?
        let avail = data.size() - offset

        if avail > rem then
          _chunks(0)? = (data, offset + rem)
          break
        end

        rem = rem - avail
        _chunks.shift()?
      end
    else
      error
    end

  fun ref u8(): U8 ? =>
    """
    Get a U8. Errors if there isn't enough data.
    """
    if _available >= 1 then
      _byte()?
    else
      error
    end

  fun ref i8(): I8 ? =>
    """
    Get an I8.
    """
    u8()?.i8()

  fun ref u16_be(): U16 ? =>
    """
    Get a big-endian U16.
    """
    let num_bytes = USize(2)
    if _available >= num_bytes then
      (var data, var offset) = _chunks(0)?
      if (data.size() - offset) >= num_bytes then
        let r =
          ifdef bigendian then
            data.read_u16(offset)?
          else
            data.read_u16(offset)?.bswap()
          end

        offset = offset + num_bytes
        _available = _available - num_bytes

        if offset < data.size() then
          _chunks(0)? = (data, offset)
        else
          _chunks.shift()?
        end
        r
      else
        (u8()?.u16() << 8) or u8()?.u16()
      end
    else
      error
    end

  fun ref i16_be(): I16 ? =>
    """
    Get a big-endian I16.
    """
    u16_be()?.i16()

  fun ref u32_be(): U32 ? =>
    """
    Get a big-endian U32.
    """
    let num_bytes = USize(4)
    if _available >= num_bytes then
      (var data, var offset) = _chunks(0)?
      if (data.size() - offset) >= num_bytes then
        let r =
          ifdef bigendian then
            data.read_u32(offset)?
          else
            data.read_u32(offset)?.bswap()
          end

        offset = offset + num_bytes
        _available = _available - num_bytes

        if offset < data.size() then
          _chunks(0)? = (data, offset)
        else
          _chunks.shift()?
        end
        r
      else
        (u8()?.u32() << 24) or (u8()?.u32() << 16) or
          (u8()?.u32() << 8) or u8()?.u32()
      end
    else
      error
    end

  fun ref i32_be(): I32 ? =>
    """
    Get a big-endian I32.
    """
    u32_be()?.i32()

  fun ref u64_be(): U64 ? =>
    """
    Get a big-endian U64.
    """
    let num_bytes = USize(8)
    if _available >= num_bytes then
      (var data, var offset) = _chunks(0)?
      if (data.size() - offset) >= num_bytes then
        let r =
          ifdef bigendian then
            data.read_u64(offset)?
          else
            data.read_u64(offset)?.bswap()
          end

        offset = offset + num_bytes
        _available = _available - num_bytes

        if offset < data.size() then
          _chunks(0)? = (data, offset)
        else
          _chunks.shift()?
        end
        r
      else
        (u8()?.u64() << 56) or (u8()?.u64() << 48) or
          (u8()?.u64() << 40) or (u8()?.u64() << 32) or
          (u8()?.u64() << 24) or (u8()?.u64() << 16) or
          (u8()?.u64() << 8) or u8()?.u64()
      end
    else
      error
    end

  fun ref i64_be(): I64 ? =>
    """
    Get a big-endian I64.
    """
    u64_be()?.i64()

  fun ref f32_be(): F32 ? =>
    """
    Get a big-endian F32.
    """
    F32.from_bits(u32_be()?)

  fun ref f64_be(): F64 ? =>
    """
    Get a big-endian F64.
    """
    F64.from_bits(u64_be()?)

  fun peek_u8(offset: USize = 0): U8 ? =>
    """
    Peek at a U8 at the given offset without consuming it.
    Errors if there isn't enough data.
    """
    _peek_byte(offset)?

  fun peek_u16_be(offset: USize = 0): U16 ? =>
    """
    Peek at a big-endian U16 at the given offset without
    consuming it.
    """
    (peek_u8(offset)?.u16() << 8) or
      peek_u8(offset + 1)?.u16()

  fun peek_u32_be(offset: USize = 0): U32 ? =>
    """
    Peek at a big-endian U32 at the given offset without
    consuming it.
    """
    (peek_u16_be(offset)?.u32() << 16) or
      peek_u16_be(offset + 2)?.u32()

  fun ref _byte(): U8 ? =>
    """
    Get a single byte.
    """
    (var data, var offset) = _chunks(0)?
    let r = data(offset)?

    offset = offset + 1
    _available = _available - 1

    if offset < data.size() then
      _chunks(0)? = (data, offset)
    else
      _chunks.shift()?
    end
    r

  fun _peek_byte(offset: USize = 0): U8 ? =>
    """
    Get the byte at the given offset without moving the cursor.
    Errors if the offset is beyond available data.
    """
    var offset' = offset
    var i: USize = 0

    while i < _chunks.size() do
      (let data, let node_offset) = _chunks(i)?
      offset' = offset' + node_offset

      let data_size = data.size()
      if offset' >= data_size then
        offset' = offset' - data_size
      else
        return data(offset')?
      end
      i = i + 1
    end

    error

  fun ref _block_copy(len: USize): Array[U8] val ? =>
    """
    Copy `len` bytes from multiple chunks into a new array.
    Consumes fully-exhausted chunks.
    """
    var out = recover iso Array[U8] .> undefined(len) end
    var i = USize(0)

    while i < len do
      (let data, let offset) = _chunks(0)?

      let avail = data.size() - offset
      let need = len - i
      let copy_len = need.min(avail)

      out = recover iso
        let r = consume ref out
        data.copy_to(r, offset, i, copy_len)
        consume r
      end

      if avail > need then
        _chunks(0)? = (data, offset + need)
        break
      end

      i = i + copy_len
      _chunks.shift()?
    end

    consume out
