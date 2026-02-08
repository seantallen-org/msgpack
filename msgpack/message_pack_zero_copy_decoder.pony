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

primitive MessagePackZeroCopyDecoder
  """
  Implements low-level zero-copy decoding from the [MessagePack
  serialization format](https://github.com/msgpack/msgpack/blob/master/spec.md).

  This decoder mirrors `MessagePackDecoder` but takes a
  `ZeroCopyReader` instead of a `buffered.Reader`. Variable-length
  values (strings, binary data, extensions) are returned as `val`
  views into the reader's internal buffer rather than freshly
  allocated copies. Fixed-size values (integers, floats, booleans)
  are decoded identically to `MessagePackDecoder`.

  You should be familiar with how MessagePack encodes messages if
  you use this API directly. There are very few guardrails
  preventing you from incorrectly decoding documents. This is
  particularly true when using the `array` and `map` format family
  decoding methods, which only read headers — the caller must read
  each element individually afterward.

  Two styles of decode methods are provided:

  - **Compact methods** (`uint`, `int`, `str`, `byte_array`, `ext`,
    `array`, `map`) peek at the format byte to determine the wire
    format and accept any format within the family.
  - **Format-specific methods** (`u8`, `u16`, `str_8`, `str_16`,
    `bin_8`, `fixext_1`, `ext_8`, etc.) validate a single expected
    format byte, then read the data directly. Use these when you
    know the exact wire format in advance.

  This decoder assumes all data is available when decoding begins.
  For streaming use, `MessagePackStreamingDecoder` uses zero-copy
  decoding internally.
  """
  //
  // compact format family
  //

  fun uint(b: ZeroCopyReader): U64 ? =>
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

  fun int(b: ZeroCopyReader): I64 ? =>
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

  fun array(b: ZeroCopyReader): U32 ? =>
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

  fun map(b: ZeroCopyReader): U32 ? =>
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

  fun nil(b: ZeroCopyReader): None ? =>
    """
    Returns nothing. Throws an error if the next byte isn't a
    MessagePack nil.
    """
    if _read_type(b)? != _FormatName.nil() then
      error
    end

  //
  // bool format family
  //

  fun bool(b: ZeroCopyReader): Bool ? =>
    match _read_type(b)?
    | _FormatName.truthy() => true
    | _FormatName.falsey() => false
    else
      error
    end

  //
  // fixed number family
  //

  fun positive_fixint(b: ZeroCopyReader): U8 ? =>
    b.u8()?

  fun negative_fixint(b: ZeroCopyReader): I8 ? =>
    b.i8()?

  //
  // unsigned int family
  //

  fun u8(b: ZeroCopyReader): U8 ? =>
    if _read_type(b)? != _FormatName.uint_8() then
      error
    end

    b.u8()?

  fun u16(b: ZeroCopyReader): U16 ? =>
    if _read_type(b)? != _FormatName.uint_16() then
      error
    end

    b.u16_be()?

  fun u32(b: ZeroCopyReader): U32 ? =>
    if _read_type(b)? != _FormatName.uint_32() then
      error
    end

    b.u32_be()?

  fun u64(b: ZeroCopyReader): U64 ? =>
    if _read_type(b)? != _FormatName.uint_64() then
      error
    end

    b.u64_be()?

  //
  // signed integer family
  //

  fun i8(b: ZeroCopyReader): I8 ? =>
    if _read_type(b)? != _FormatName.int_8() then
      error
    end

    b.i8()?

  fun i16(b: ZeroCopyReader): I16 ? =>
    if _read_type(b)? != _FormatName.int_16() then
      error
    end

    b.i16_be()?

  fun i32(b: ZeroCopyReader): I32 ? =>
    if _read_type(b)? != _FormatName.int_32() then
      error
    end

    b.i32_be()?

  fun i64(b: ZeroCopyReader): I64 ? =>
    if _read_type(b)? != _FormatName.int_64() then
      error
    end

    b.i64_be()?

  //
  // float format family
  //

  fun f32(b: ZeroCopyReader): F32 ? =>
    if _read_type(b)? != _FormatName.float_32() then
      error
    end

    b.f32_be()?

  fun f64(b: ZeroCopyReader): F64 ? =>
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
  fun fixstr(b: ZeroCopyReader): String val ? =>
    let len = (b.u8()?.usize() and _Limit.fixstr())
    String.from_array(b.block(len)?)

  fun str(b: ZeroCopyReader): String val ? =>
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

    String.from_array(b.block(len.usize())?)

  // Note: MessagePackStreamingDecoder pre-validates total size
  // before calling this method. If the read sequence changes,
  // update the size check in _decode_str.
  fun str_8(b: ZeroCopyReader): String val ? =>
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
    String.from_array(b.block(len)?)

  // Note: MessagePackStreamingDecoder pre-validates total size
  // before calling this method. If the read sequence changes,
  // update the size check in _decode_str.
  fun str_16(b: ZeroCopyReader): String val ? =>
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
    String.from_array(b.block(len)?)

  // Note: MessagePackStreamingDecoder pre-validates total size
  // before calling this method. If the read sequence changes,
  // update the size check in _decode_str.
  fun str_32(b: ZeroCopyReader): String val ? =>
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
    String.from_array(b.block(len)?)

  //
  // str family — UTF-8 validating variants
  //

  fun str_utf8(b: ZeroCopyReader): String val ? =>
    """
    Decodes a MessagePack str value using the smallest matching
    format, then validates that the bytes are valid UTF-8.

    Errors if the format byte is not a str type, if insufficient
    data is available, or if the decoded bytes are not valid
    UTF-8. On a UTF-8 validation error the bytes have already
    been consumed from the reader. For the non-validating
    variant, use `str()`. To retain access to the raw bytes on
    validation failure, use `str()` followed by
    `MessagePackValidateUTF8`.
    """
    let s = str(b)?
    if not MessagePackValidateUTF8(s) then error end
    s

  fun fixstr_utf8(b: ZeroCopyReader): String val ? =>
    """
    Decodes a MessagePack fixstr value, then validates that the
    bytes are valid UTF-8.

    Errors if the format byte does not match, if insufficient
    data is available, or if the decoded bytes are not valid
    UTF-8. For the non-validating variant, use `fixstr()`.
    """
    let s = fixstr(b)?
    if not MessagePackValidateUTF8(s) then error end
    s

  fun str_8_utf8(b: ZeroCopyReader): String val ? =>
    """
    Decodes a MessagePack str 8 value, then validates that the
    bytes are valid UTF-8.

    Errors if the format byte does not match, if insufficient
    data is available, or if the decoded bytes are not valid
    UTF-8. For the non-validating variant, use `str_8()`.
    """
    let s = str_8(b)?
    if not MessagePackValidateUTF8(s) then error end
    s

  fun str_16_utf8(b: ZeroCopyReader): String val ? =>
    """
    Decodes a MessagePack str 16 value, then validates that the
    bytes are valid UTF-8.

    Errors if the format byte does not match, if insufficient
    data is available, or if the decoded bytes are not valid
    UTF-8. For the non-validating variant, use `str_16()`.
    """
    let s = str_16(b)?
    if not MessagePackValidateUTF8(s) then error end
    s

  fun str_32_utf8(b: ZeroCopyReader): String val ? =>
    """
    Decodes a MessagePack str 32 value, then validates that the
    bytes are valid UTF-8.

    Errors if the format byte does not match, if insufficient
    data is available, or if the decoded bytes are not valid
    UTF-8. For the non-validating variant, use `str_32()`.
    """
    let s = str_32(b)?
    if not MessagePackValidateUTF8(s) then error end
    s

  //
  // byte array family
  //

  fun byte_array(b: ZeroCopyReader): Array[U8] val ? =>
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
  fun bin_8(b: ZeroCopyReader): Array[U8] val ? =>
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
  fun bin_16(b: ZeroCopyReader): Array[U8] val ? =>
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
  fun bin_32(b: ZeroCopyReader): Array[U8] val ? =>
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

  fun fixarray(b: ZeroCopyReader): U8 ? =>
    """
    Reads a header for a MessgePack "fixarray". This only reads
    the header. The number of array items returned by this method
    needs to be read via other methods after this is called.
    """
    (b.u8()? and _Limit.fixarray())

  fun array_16(b: ZeroCopyReader): U16 ? =>
    """
    Reads a header for a MessgePack "array_16". This only reads
    the header. The number of array items returned by this method
    needs to be read via other methods after this is called.
    """
    if _read_type(b)? != _FormatName.array_16() then
      error
    end

    b.u16_be()?

  fun array_32(b: ZeroCopyReader): U32 ? =>
    """
    Reads a header for a MessgePack "array_32". This only reads
    the header. The number of array items returned by this method
    needs to be read via other methods after this is called.
    """
    if _read_type(b)? != _FormatName.array_32() then
      error
    end

    b.u32_be()?

  //
  // map format family
  //

  fun fixmap(b: ZeroCopyReader): U8 ? =>
    """
    Reads a header for a MessgePack "fixmap". This only reads the
    header. The number of map items returned by this method needs
    to be read via other methods after this is called.
    """
    (b.u8()? and _Limit.fixmap())

  fun map_16(b: ZeroCopyReader): U16 ? =>
    """
    Reads a header for a MessgePack "map_16". This only reads the
    header. The number of map items returned by this method needs
    to be read via other methods after this is called.
    """
    if _read_type(b)? != _FormatName.map_16() then
      error
    end

    b.u16_be()?

  fun map_32(b: ZeroCopyReader): U32 ? =>
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

  fun ext(b: ZeroCopyReader): (U8, Array[U8] val) ? =>
    """
    Allows for the reading of user supplied extensions to the
    MessagePack format.

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
  fun fixext_1(b: ZeroCopyReader): (U8, Array[U8] val) ? =>
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
  fun fixext_2(b: ZeroCopyReader): (U8, Array[U8] val) ? =>
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
  fun fixext_4(b: ZeroCopyReader): (U8, Array[U8] val) ? =>
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
  fun fixext_8(b: ZeroCopyReader): (U8, Array[U8] val) ? =>
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
  fun fixext_16(b: ZeroCopyReader): (U8, Array[U8] val) ? =>
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
  fun ext_8(b: ZeroCopyReader): (U8, Array[U8] val) ? =>
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
  fun ext_16(b: ZeroCopyReader): (U8, Array[U8] val) ? =>
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
  fun ext_32(b: ZeroCopyReader): (U8, Array[U8] val) ? =>
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
  // before calling this method. If the read sequence here
  // changes, update the size checks in _decode_fixext and
  // _decode_ext_variable.
  fun timestamp(b: ZeroCopyReader): (I64, U32) ? =>
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
  // skip
  //

  fun skip(b: ZeroCopyReader ref) ? =>
    """
    Advances past one complete MessagePack value without
    decoding it. For containers (arrays and maps), skips all
    contained elements.

    Errors if insufficient data is available or if the format
    byte is invalid (0xC1). On error, no bytes are consumed.

    This method has no limit on the number of values
    traversed. For protection against container amplification
    attacks, use `MessagePackStreamingDecoder.skip` which
    enforces a configurable `max_skip_values` limit.
    """
    var offset: USize = 0
    var remaining: USize = 1
    while remaining > 0 do
      remaining = remaining - 1
      let fb = b.peek_u8(offset)?
      if fb <= 0x7F then
        // positive fixint: 1 byte
        offset = offset + 1
      elseif fb <= 0x8F then
        // fixmap: 1 byte header, count * 2 values
        remaining = remaining
          + ((fb and 0x0F).usize() * 2)
        offset = offset + 1
      elseif fb <= 0x9F then
        // fixarray: 1 byte header, count values
        remaining = remaining
          + (fb and 0x0F).usize()
        offset = offset + 1
      elseif fb <= 0xBF then
        // fixstr: 1 byte header + data
        offset = offset + 1
          + (fb and 0x1F).usize()
      elseif fb == _FormatName.nil() then
        offset = offset + 1
      elseif fb == 0xC1 then
        error
      elseif fb <= _FormatName.truthy() then
        // bool: 1 byte
        offset = offset + 1
      elseif fb <= _FormatName.bin_32() then
        // bin_8/16/32
        if fb == _FormatName.bin_8() then
          let len = b.peek_u8(offset + 1)?.usize()
          offset = offset + 2 + len
        elseif fb == _FormatName.bin_16() then
          let len =
            b.peek_u16_be(offset + 1)?.usize()
          offset = offset + 3 + len
        else
          let len =
            b.peek_u32_be(offset + 1)?.usize()
          offset = offset + 5 + len
        end
      elseif fb <= _FormatName.ext_32() then
        // ext_8/16/32: header + 1 ext_type + data
        if fb == _FormatName.ext_8() then
          let len = b.peek_u8(offset + 1)?.usize()
          offset = offset + 3 + len
        elseif fb == _FormatName.ext_16() then
          let len =
            b.peek_u16_be(offset + 1)?.usize()
          offset = offset + 4 + len
        else
          let len =
            b.peek_u32_be(offset + 1)?.usize()
          offset = offset + 6 + len
        end
      elseif fb == _FormatName.float_32() then
        offset = offset + 5
      elseif fb == _FormatName.float_64() then
        offset = offset + 9
      elseif fb <= _FormatName.uint_64() then
        // uint_8/16/32/64
        if fb == _FormatName.uint_8() then
          offset = offset + 2
        elseif fb == _FormatName.uint_16() then
          offset = offset + 3
        elseif fb == _FormatName.uint_32() then
          offset = offset + 5
        else
          offset = offset + 9
        end
      elseif fb <= _FormatName.int_64() then
        // int_8/16/32/64
        if fb == _FormatName.int_8() then
          offset = offset + 2
        elseif fb == _FormatName.int_16() then
          offset = offset + 3
        elseif fb == _FormatName.int_32() then
          offset = offset + 5
        else
          offset = offset + 9
        end
      elseif fb <= _FormatName.fixext_16() then
        // fixext_1/2/4/8/16
        if fb == _FormatName.fixext_1() then
          offset = offset + 3
        elseif fb == _FormatName.fixext_2() then
          offset = offset + 4
        elseif fb == _FormatName.fixext_4() then
          offset = offset + 6
        elseif fb == _FormatName.fixext_8() then
          offset = offset + 10
        else
          offset = offset + 18
        end
      elseif fb <= _FormatName.str_32() then
        // str_8/16/32
        if fb == _FormatName.str_8() then
          let len = b.peek_u8(offset + 1)?.usize()
          offset = offset + 2 + len
        elseif fb == _FormatName.str_16() then
          let len =
            b.peek_u16_be(offset + 1)?.usize()
          offset = offset + 3 + len
        else
          let len =
            b.peek_u32_be(offset + 1)?.usize()
          offset = offset + 5 + len
        end
      elseif fb <= _FormatName.array_32() then
        // array_16/32
        if fb == _FormatName.array_16() then
          remaining = remaining
            + b.peek_u16_be(offset + 1)?.usize()
          offset = offset + 3
        else
          remaining = remaining
            + b.peek_u32_be(offset + 1)?.usize()
          offset = offset + 5
        end
      elseif fb <= _FormatName.map_32() then
        // map_16/32
        if fb == _FormatName.map_16() then
          remaining = remaining
            + (b.peek_u16_be(offset + 1)?.usize()
              * 2)
          offset = offset + 3
        else
          remaining = remaining
            + (b.peek_u32_be(offset + 1)?.usize()
              * 2)
          offset = offset + 5
        end
      else
        // negative fixint: 1 byte
        offset = offset + 1
      end
    end
    b.skip(offset)?

  //
  // support functions
  //

  fun _read_type(b: ZeroCopyReader): MessagePackType ? =>
    b.u8()?
