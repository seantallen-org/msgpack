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

  You should be familiar with how MessagePack encodes messages if you use this
  API directly. There are very few guardrails preventing you from incorrectly
  decoding documents. This is particularly true when using the `array` and
  `map` format family encoding methods.
  """
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

  fun fixstr(b: Reader): String iso^ ? =>
    let len = (b.u8()?.usize() and _Limit.fixstr())
    String.from_iso_array(b.block(len)?)

  // Note: MessagePackStreamingDecoder pre-validates total size
  // before calling this method. If the read sequence here changes,
  // update the size checks in _decode_str.
  fun str(b: Reader): String iso^ ? =>
    let t = _read_type(b)?

    let len = if t == _FormatName.str_8() then
      b.u8()?
    elseif t == _FormatName.str_16() then
      b.u16_be()?.usize()
    elseif t == _FormatName.str_32() then
      b.u32_be()?.usize()
    else
      error
    end

    String.from_iso_array(b.block(len.usize())?)

  //
  // byte array family
  //

  // Note: MessagePackStreamingDecoder pre-validates total size
  // before calling this method. If the read sequence here changes,
  // update the size checks in _decode_bin.
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

  // Note: MessagePackStreamingDecoder pre-validates total size
  // before calling this method. If the read sequence here changes,
  // update the size checks in _decode_fixext and
  // _decode_ext_variable.
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
