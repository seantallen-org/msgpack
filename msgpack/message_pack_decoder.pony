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

use "buffered"

type MessagePackType is U8

primitive MessagePackDecoder
  """
  Implements low-level decoding from the [MessagePack serialization format](https://github.com/msgpack/msgpack/blob/master/spec.md).

  You should be familiar with how MessagePack encodes messages if you use
  this API directly. There are very few guardrails preventing you from
  incorrectly decoding documents. This is particularly true when using the
  `array` and `map` format family decoding methods, which only read
  headers — the caller must read each element individually afterward.

  Two styles of decode methods are provided:

  - **Compact methods** (`uint`, `int`, `str`, `byte_array`, `ext`,
    `array`, `map`) peek at the format byte to determine the wire
    format and accept any format within the family.
  - **Format-specific methods** (`u8`, `u16`, `str_8`, `str_16`,
    `bin_8`, `fixext_1`, `ext_8`, etc.) validate a single expected
    format byte, then read the data directly. Use these when you
    know the exact wire format in advance.

  This decoder assumes all data is available when decoding begins. If data
  may arrive incrementally, use `MessagePackStreamingDecoder` instead.
  """
  //
  // compact format family
  //
  // These methods peek at the format byte to determine the wire
  // format, then decode accordingly. They accept any format within
  // the relevant MessagePack format family.
  //
  // The format-specific methods below remain available for callers
  // who know the exact wire format in advance.
  //

  fun uint(b: Reader ref): U64 ? =>
    """
    Decodes an unsigned integer from any uint or positive fixint
    format.
    """
    let t = b.peek_u8()?
    if (t and 0x80) == 0 then
      b.u8()?.u64()
    elseif t == _FormatName.uint_8() then
      _read_type(b)?
      b.u8()?.u64()
    elseif t == _FormatName.uint_16() then
      _read_type(b)?
      b.u16_be()?.u64()
    elseif t == _FormatName.uint_32() then
      _read_type(b)?
      b.u32_be()?.u64()
    elseif t == _FormatName.uint_64() then
      _read_type(b)?
      b.u64_be()?
    else
      error
    end

  fun int(b: Reader ref): I64 ? =>
    """
    Decodes a signed integer from any int, uint, or fixint
    format. Errors if a uint_64 value exceeds I64.max_value().
    """
    let t = b.peek_u8()?
    if (t and 0x80) == 0 then
      b.u8()?.i64()
    elseif (t and 0xE0) == _FormatName.negative_fixint() then
      b.i8()?.i64()
    elseif t == _FormatName.uint_8() then
      _read_type(b)?
      b.u8()?.i64()
    elseif t == _FormatName.uint_16() then
      _read_type(b)?
      b.u16_be()?.i64()
    elseif t == _FormatName.uint_32() then
      _read_type(b)?
      b.u32_be()?.i64()
    elseif t == _FormatName.uint_64() then
      _read_type(b)?
      let v = b.u64_be()?
      if v > I64.max_value().u64() then error end
      v.i64()
    elseif t == _FormatName.int_8() then
      _read_type(b)?
      b.i8()?.i64()
    elseif t == _FormatName.int_16() then
      _read_type(b)?
      b.i16_be()?.i64()
    elseif t == _FormatName.int_32() then
      _read_type(b)?
      b.i32_be()?.i64()
    elseif t == _FormatName.int_64() then
      _read_type(b)?
      b.i64_be()?
    else
      error
    end

  fun array(b: Reader ref): U32 ? =>
    """
    Reads an array header from any array format. Returns the
    element count. The caller must read that many elements
    afterward.
    """
    let t = b.peek_u8()?
    if (t and 0xF0) == _FormatName.fixarray() then
      (b.u8()? and 0x0F).u32()
    elseif t == _FormatName.array_16() then
      _read_type(b)?
      b.u16_be()?.u32()
    elseif t == _FormatName.array_32() then
      _read_type(b)?
      b.u32_be()?
    else
      error
    end

  fun map(b: Reader ref): U32 ? =>
    """
    Reads a map header from any map format. Returns the pair
    count. The caller must read that many key-value pairs
    afterward.
    """
    let t = b.peek_u8()?
    if (t and 0xF0) == _FormatName.fixmap() then
      (b.u8()? and 0x0F).u32()
    elseif t == _FormatName.map_16() then
      _read_type(b)?
      b.u16_be()?.u32()
    elseif t == _FormatName.map_32() then
      _read_type(b)?
      b.u32_be()?
    else
      error
    end

  //
  // nil format family
  //

  fun nil(b: Reader ref): None ? =>
    """
    Returns nothing. Throws an error if the next byte isn't a MessagePack nil.
    """
    if _read_type(b)? != _FormatName.nil() then
      error
    end

  //
  // bool format family
  //

  fun bool(b: Reader ref): Bool ? =>
    match _read_type(b)?
    | _FormatName.truthy() => true
    | _FormatName.falsey() => false
    else
      error
    end

  //
  // fixed number family
  //

  fun positive_fixint(b: Reader ref): U8 ? =>
    b.u8()?

  fun negative_fixint(b: Reader ref): I8 ? =>
    b.i8()?

  //
  // unsigned int family
  //

  fun u8(b: Reader ref): U8 ? =>
    if _read_type(b)? != _FormatName.uint_8() then
      error
    end

    b.u8()?

  fun u16(b: Reader ref): U16 ? =>
    if _read_type(b)? != _FormatName.uint_16() then
      error
    end

    b.u16_be()?

  fun u32(b: Reader ref): U32 ? =>
    if _read_type(b)? != _FormatName.uint_32() then
      error
    end

    b.u32_be()?

  fun u64(b: Reader ref): U64 ? =>
    if _read_type(b)? != _FormatName.uint_64() then
      error
    end

    b.u64_be()?

  //
  // signed integer family
  //

  fun i8(b: Reader ref): I8 ? =>
    if _read_type(b)? != _FormatName.int_8() then
      error
    end

    b.i8()?

  fun i16(b: Reader ref): I16 ? =>
    if _read_type(b)? != _FormatName.int_16() then
      error
    end

    b.i16_be()?

  fun i32(b: Reader ref): I32 ? =>
    if _read_type(b)? != _FormatName.int_32() then
      error
    end

    b.i32_be()?

  fun i64(b: Reader ref): I64 ? =>
    if _read_type(b)? != _FormatName.int_64() then
      error
    end

    b.i64_be()?

  //
  // float format family
  //

  fun f32(b: Reader ref): F32 ? =>
    if _read_type(b)? != _FormatName.float_32() then
      error
    end

    b.f32_be()?

  fun f64(b: Reader ref): F64 ? =>
    if _read_type(b)? != _FormatName.float_64() then
      error
    end

    b.f64_be()?

  //
  // str family
  //

  // Note: MessagePackStreamingDecoder pre-validates total size
  // before calling this method. If the read sequence changes,
  // update the size check in _decode_fixstr.
  fun fixstr(b: Reader): String iso^ ? =>
    let len = (b.u8()?.usize() and _Limit.fixstr())
    String.from_iso_array(b.block(len)?)

  fun str(b: Reader): String iso^ ? =>
    let t = _read_type(b)?

    let len = if (t and 0xE0) == _FormatName.fixstr() then
      (t and 0x1F).usize()
    elseif t == _FormatName.str_8() then
      b.u8()?
    elseif t == _FormatName.str_16() then
      b.u16_be()?.usize()
    elseif t == _FormatName.str_32() then
      b.u32_be()?.usize()
    else
      error
    end

    String.from_iso_array(b.block(len.usize())?)

  // Note: MessagePackStreamingDecoder pre-validates total size
  // before calling this method. If the read sequence changes,
  // update the size check in _decode_str.
  fun str_8(b: Reader): String iso^ ? =>
    """
    Decodes a MessagePack str 8 value. Validates that the format
    byte is str_8 (0xD9), then reads the 1-byte length prefix and
    data.

    Errors if the format byte does not match or if insufficient
    data is available. For a method that accepts any string wire
    format, use `str()` instead.
    """
    if _read_type(b)? != _FormatName.str_8() then error end
    let len = b.u8()?.usize()
    String.from_iso_array(b.block(len)?)

  // Note: MessagePackStreamingDecoder pre-validates total size
  // before calling this method. If the read sequence changes,
  // update the size check in _decode_str.
  fun str_16(b: Reader): String iso^ ? =>
    """
    Decodes a MessagePack str 16 value. Validates that the format
    byte is str_16 (0xDA), then reads the 2-byte length prefix and
    data.

    Errors if the format byte does not match or if insufficient
    data is available. For a method that accepts any string wire
    format, use `str()` instead.
    """
    if _read_type(b)? != _FormatName.str_16() then error end
    let len = b.u16_be()?.usize()
    String.from_iso_array(b.block(len)?)

  // Note: MessagePackStreamingDecoder pre-validates total size
  // before calling this method. If the read sequence changes,
  // update the size check in _decode_str.
  fun str_32(b: Reader): String iso^ ? =>
    """
    Decodes a MessagePack str 32 value. Validates that the format
    byte is str_32 (0xDB), then reads the 4-byte length prefix and
    data.

    Errors if the format byte does not match or if insufficient
    data is available. For a method that accepts any string wire
    format, use `str()` instead.
    """
    if _read_type(b)? != _FormatName.str_32() then error end
    let len = b.u32_be()?.usize()
    String.from_iso_array(b.block(len)?)

  //
  // byte array family
  //

  fun byte_array(b: Reader): Array[U8] iso^ ? =>
    let t = _read_type(b)?

    let len = if t == _FormatName.bin_8() then
      b.u8()?
    elseif t == _FormatName.bin_16() then
      b.u16_be()?.usize()
    elseif t == _FormatName.bin_32() then
      b.u32_be()?.usize()
    else
      error
    end

    b.block(len.usize())?

  // Note: MessagePackStreamingDecoder pre-validates total size
  // before calling this method. If the read sequence changes,
  // update the size check in _decode_bin.
  fun bin_8(b: Reader): Array[U8] iso^ ? =>
    """
    Decodes a MessagePack bin 8 value. Validates that the format
    byte is bin_8 (0xC4), then reads the 1-byte length prefix and
    data.

    Errors if the format byte does not match or if insufficient
    data is available. For a method that accepts any bin wire
    format, use `byte_array()` instead.
    """
    if _read_type(b)? != _FormatName.bin_8() then error end
    let len = b.u8()?.usize()
    b.block(len)?

  // Note: MessagePackStreamingDecoder pre-validates total size
  // before calling this method. If the read sequence changes,
  // update the size check in _decode_bin.
  fun bin_16(b: Reader): Array[U8] iso^ ? =>
    """
    Decodes a MessagePack bin 16 value. Validates that the format
    byte is bin_16 (0xC5), then reads the 2-byte length prefix and
    data.

    Errors if the format byte does not match or if insufficient
    data is available. For a method that accepts any bin wire
    format, use `byte_array()` instead.
    """
    if _read_type(b)? != _FormatName.bin_16() then error end
    let len = b.u16_be()?.usize()
    b.block(len)?

  // Note: MessagePackStreamingDecoder pre-validates total size
  // before calling this method. If the read sequence changes,
  // update the size check in _decode_bin.
  fun bin_32(b: Reader): Array[U8] iso^ ? =>
    """
    Decodes a MessagePack bin 32 value. Validates that the format
    byte is bin_32 (0xC6), then reads the 4-byte length prefix and
    data.

    Errors if the format byte does not match or if insufficient
    data is available. For a method that accepts any bin wire
    format, use `byte_array()` instead.
    """
    if _read_type(b)? != _FormatName.bin_32() then error end
    let len = b.u32_be()?.usize()
    b.block(len)?

  //
  // array format family
  //

  fun fixarray(b: Reader): U8 ? =>
    """
    Reads a header for a MessgePack "fixarray". This only reads the
    header. The number of array items returned by this method needs
    to be read via other methods after this is called.
    """
    (b.u8()? and _Limit.fixarray())

  fun array_16(b: Reader): U16 ? =>
    """
    Reads a header for a MessgePack "array_16". This only reads the
    header. The number of array items returned by this method needs
    to be read via other methods after this is called.
    """
    if _read_type(b)? != _FormatName.array_16() then
      error
    end

    b.u16_be()?

  fun array_32(b: Reader): U32 ? =>
    """
    Reads a header for a MessgePack "array_32". This only reads the
    header. The number of array items returned by this method needs
    to be read via other methods after this is called.
    """
    if _read_type(b)? != _FormatName.array_32() then
      error
    end

    b.u32_be()?

  //
  // map format family
  //

  fun fixmap(b: Reader): U8 ? =>
    """
    Reads a header for a MessgePack "fixmap". This only reads the
    header. The number of map items returned by this method needs
    to be read via other methods after this is called.
    """
    (b.u8()? and _Limit.fixmap())

  fun map_16(b: Reader): U16 ? =>
    """
    Reads a header for a MessgePack "map_16". This only reads the
    header. The number of map items returned by this method needs
    to be read via other methods after this is called.
    """
    if _read_type(b)? != _FormatName.map_16() then
      error
    end

    b.u16_be()?

  fun map_32(b: Reader): U32 ? =>
    """
    Reads a header for a MessgePack "map_32". This only reads the
    header. The number of map items returned by this method needs
    to be read via other methods after this is called.
    """
    if _read_type(b)? != _FormatName.map_32() then
      error
    end

    b.u32_be()?

  //
  // ext format family
  //

  fun ext(b: Reader): (U8, Array[U8] val) ? =>
    """
    Allows for the reading of user supplied extensions to the MessagePack
    format.

    fixext * types return a tuple representing:

    (user supplied type indentifier, data byte array)
    """
    let t = _read_type(b)?

    let size: USize = if t == _FormatName.fixext_1() then
      1
    elseif t == _FormatName.fixext_2() then
      2
    elseif t == _FormatName.fixext_4() then
      4
    elseif t == _FormatName.fixext_8() then
      8
    elseif t == _FormatName.fixext_16() then
      16
    elseif t == _FormatName.ext_8() then
      b.u8()?.usize()
    elseif t == _FormatName.ext_16() then
      b.u16_be()?.usize()
    elseif t == _FormatName.ext_32() then
      b.u32_be()?.usize()
    else
      error
    end

    (b.u8()?, b.block(size)?)

  // Note: MessagePackStreamingDecoder pre-validates total size
  // before calling this method. If the read sequence changes,
  // update the size check in _decode_fixext.
  fun fixext_1(b: Reader): (U8, Array[U8] val) ? =>
    """
    Decodes a MessagePack fixext 1 value. Validates that the
    format byte is fixext_1 (0xD4), then reads the ext type byte
    and 1 byte of data.

    Returns `(ext_type, data)`. Errors if the format byte does
    not match. For a method that accepts any ext wire format, use
    `ext()` instead.
    """
    if _read_type(b)? != _FormatName.fixext_1() then error end
    (b.u8()?, b.block(1)?)

  // Note: MessagePackStreamingDecoder pre-validates total size
  // before calling this method. If the read sequence changes,
  // update the size check in _decode_fixext.
  fun fixext_2(b: Reader): (U8, Array[U8] val) ? =>
    """
    Decodes a MessagePack fixext 2 value. Validates that the
    format byte is fixext_2 (0xD5), then reads the ext type byte
    and 2 bytes of data.

    Returns `(ext_type, data)`. Errors if the format byte does
    not match. For a method that accepts any ext wire format, use
    `ext()` instead.
    """
    if _read_type(b)? != _FormatName.fixext_2() then error end
    (b.u8()?, b.block(2)?)

  // Note: MessagePackStreamingDecoder pre-validates total size
  // before calling this method. If the read sequence changes,
  // update the size check in _decode_fixext.
  fun fixext_4(b: Reader): (U8, Array[U8] val) ? =>
    """
    Decodes a MessagePack fixext 4 value. Validates that the
    format byte is fixext_4 (0xD6), then reads the ext type byte
    and 4 bytes of data.

    Returns `(ext_type, data)`. Errors if the format byte does
    not match. For a method that accepts any ext wire format, use
    `ext()` instead.
    """
    if _read_type(b)? != _FormatName.fixext_4() then error end
    (b.u8()?, b.block(4)?)

  // Note: MessagePackStreamingDecoder pre-validates total size
  // before calling this method. If the read sequence changes,
  // update the size check in _decode_fixext.
  fun fixext_8(b: Reader): (U8, Array[U8] val) ? =>
    """
    Decodes a MessagePack fixext 8 value. Validates that the
    format byte is fixext_8 (0xD7), then reads the ext type byte
    and 8 bytes of data.

    Returns `(ext_type, data)`. Errors if the format byte does
    not match. For a method that accepts any ext wire format, use
    `ext()` instead.
    """
    if _read_type(b)? != _FormatName.fixext_8() then error end
    (b.u8()?, b.block(8)?)

  // Note: MessagePackStreamingDecoder pre-validates total size
  // before calling this method. If the read sequence changes,
  // update the size check in _decode_fixext.
  fun fixext_16(b: Reader): (U8, Array[U8] val) ? =>
    """
    Decodes a MessagePack fixext 16 value. Validates that the
    format byte is fixext_16 (0xD8), then reads the ext type byte
    and 16 bytes of data.

    Returns `(ext_type, data)`. Errors if the format byte does
    not match. For a method that accepts any ext wire format, use
    `ext()` instead.
    """
    if _read_type(b)? != _FormatName.fixext_16() then error end
    (b.u8()?, b.block(16)?)

  // Note: MessagePackStreamingDecoder pre-validates total size
  // before calling this method. If the read sequence changes,
  // update the size check in _decode_ext_variable.
  fun ext_8(b: Reader): (U8, Array[U8] val) ? =>
    """
    Decodes a MessagePack ext 8 value. Validates that the format
    byte is ext_8 (0xC7), then reads the 1-byte length prefix,
    ext type byte, and data.

    Returns `(ext_type, data)`. Errors if the format byte does
    not match. For a method that accepts any ext wire format, use
    `ext()` instead.
    """
    if _read_type(b)? != _FormatName.ext_8() then error end
    let len = b.u8()?.usize()
    (b.u8()?, b.block(len)?)

  // Note: MessagePackStreamingDecoder pre-validates total size
  // before calling this method. If the read sequence changes,
  // update the size check in _decode_ext_variable.
  fun ext_16(b: Reader): (U8, Array[U8] val) ? =>
    """
    Decodes a MessagePack ext 16 value. Validates that the format
    byte is ext_16 (0xC8), then reads the 2-byte length prefix,
    ext type byte, and data.

    Returns `(ext_type, data)`. Errors if the format byte does
    not match. For a method that accepts any ext wire format, use
    `ext()` instead.
    """
    if _read_type(b)? != _FormatName.ext_16() then error end
    let len = b.u16_be()?.usize()
    (b.u8()?, b.block(len)?)

  // Note: MessagePackStreamingDecoder pre-validates total size
  // before calling this method. If the read sequence changes,
  // update the size check in _decode_ext_variable.
  fun ext_32(b: Reader): (U8, Array[U8] val) ? =>
    """
    Decodes a MessagePack ext 32 value. Validates that the format
    byte is ext_32 (0xC9), then reads the 4-byte length prefix,
    ext type byte, and data.

    Returns `(ext_type, data)`. Errors if the format byte does
    not match. For a method that accepts any ext wire format, use
    `ext()` instead.
    """
    if _read_type(b)? != _FormatName.ext_32() then error end
    let len = b.u32_be()?.usize()
    (b.u8()?, b.block(len)?)

  //
  // timestamp format family
  //

  // Note: MessagePackStreamingDecoder pre-validates total size
  // before calling this method. If the read sequence here changes,
  // update the size checks in _decode_fixext and _decode_ext_variable.
  fun timestamp(b: Reader): (I64, U32) ? =>
    let t = _read_type(b)?

    b.i8()?
    var nsec: U32 = 0
    var sec: I64 = 0
    if t == _FormatName.fixext_4() then
      sec = b.u32_be()?.i64()
    elseif t == _FormatName.fixext_8() then
      let u: U64 = b.u64_be()?
      nsec = (u >> 34).u32()
      sec = (u - (nsec.u64() << 34)).i64()
    elseif t == _FormatName.ext_8() then
      b.u8()?
      nsec = b.u32_be()?
      sec = b.i64_be()?
    else
      error
    end

    (sec, nsec)

  //
  // support functions
  //

  fun _read_type(b: Reader ref): MessagePackType ? =>
    b.u8()?
