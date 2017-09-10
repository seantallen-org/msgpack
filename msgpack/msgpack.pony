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

primitive MessagePackEncoder
  //
  // nil format family
  //

  fun nil(b: Writer) =>
    _write_type(b, _FormatName.nil())

  //
  // bool format family
  //

  fun bool(b: Writer, t_or_f: Bool) =>
    if t_or_f then
      _write_type(b, _FormatName.truthy())
    else
      _write_type(b, _FormatName.falsey())
    end

  //
  // int format family
  //

  fun positive_fixint(b: Writer, v: U8) ? =>
    // this could really use some value dependent typing
    if v <= _Limit.positive_fixint() then
      _write_fixed_value(b, v)
    else
      error
    end

  fun negative_fixint(b: Writer, v: I8) ? =>
    // this could really use some value dependent typing
    if (v >= _Limit.negative_fixint_low()) and
      (v <= _Limit.negative_fixint_high())
    then
      _write_fixed_value(b, v.u8())
    else
      error
    end

  fun uint_8(b: Writer, v: U8) =>
    _write_type(b, _FormatName.uint_8())
    b.u8(v)

  fun uint_16(b: Writer, v: U16) =>
    _write_type(b, _FormatName.uint_16())
    b.u16_be(v)

  fun uint_32(b: Writer, v: U32) =>
    _write_type(b, _FormatName.uint_32())
    b.u32_be(v)

  fun uint_64(b: Writer, v: U64) =>
    _write_type(b, _FormatName.uint_64())
    b.u64_be(v)

  fun int_8(b: Writer, v: I8) =>
    _write_type(b, _FormatName.int_8())
    b.u8(v.u8())

  fun int_16(b: Writer, v: I16) =>
    _write_type(b, _FormatName.int_16())
    b.i16_be(v)

  fun int_32(b: Writer, v: I32) =>
    _write_type(b, _FormatName.int_32())
    b.i32_be(v)

  fun int_64(b: Writer, v: I64) =>
    _write_type(b, _FormatName.int_64())
    b.i64_be(v)

  //
  // float format family
  //

  fun float_32(b: Writer, v: F32) =>
    _write_type(b, _FormatName.float_32())
    b.f32_be(v)

  fun float_64(b: Writer, v: F64) =>
    _write_type(b, _FormatName.float_64())
    b.f64_be(v)

  //
  // str format family
  //

  fun fixstr(b: Writer, v: ByteSeq) ? =>
    if v.size() <= _Limit.fixstr() then
      _write_type(b, (_FormatName.fixstr() or v.size().u8()))
      b.write(v)
    else
      error
    end

  fun str_8(b: Writer, v: ByteSeq) ? =>
    _write_btye_array_8(b, v, _FormatName.str_8())?

  fun str_16(b: Writer, v: ByteSeq) ? =>
    _write_btye_array_16(b, v, _FormatName.str_16())?

   fun str_32(b: Writer, v: ByteSeq) ? =>
    _write_btye_array_32(b, v, _FormatName.str_32())?

  //
  // bin format family
  //

  fun bin_8(b: Writer, v: ByteSeq) ? =>
    _write_btye_array_8(b, v, _FormatName.bin_8())?

  fun bin_16(b: Writer, v: ByteSeq) ? =>
    _write_btye_array_16(b, v, _FormatName.bin_16())?

   fun bin_32(b: Writer, v: ByteSeq) ? =>
    _write_btye_array_32(b, v, _FormatName.bin_32())?

  //
  // array format family
  //

  fun fixarray(b: Writer, s: U8) ? =>
    """
    Creates a header for a MessagePack "fixarray". This only creates the
    header. `s` number of array items should be written via other methods
    after this is called.
    """
    if s <= _Limit.fixarray() then
      _write_type(b, (_FormatName.fixarray() or s))
    else
      error
    end

  fun array_16(b: Writer, s: U16) =>
    """
    Creates a header for a MessagePack "array_16". This only creates the
    header. `s` number of array items should be written via other methods
    after this is called.
    """
    _write_type(b, _FormatName.array_16())
    b.u16_be(s)

  //
  // support methods
  //

  fun _write_type(b: Writer, t: U8) =>
    b.u8(t)

  fun _write_fixed_value(b: Writer, v: U8) =>
    b.u8(v)

  fun _write_btye_array_8(b: Writer, v: ByteSeq, t: U8) ? =>
    if v.size() <= U8.max_value().usize() then
      _write_type(b, t)
      b.u8(v.size().u8())
      b.write(v)
    else
      error
    end

  fun _write_btye_array_16(b: Writer, v: ByteSeq, t: U8) ? =>
    if v.size() <= U16.max_value().usize() then
      _write_type(b, t)
      b.u16_be(v.size().u16())
      b.write(v)
    else
      error
    end

  fun _write_btye_array_32(b: Writer, v: ByteSeq, t: U8) ? =>
    if v.size() <= U32.max_value().usize() then
      _write_type(b, t)
      b.u32_be(v.size().u32())
      b.write(v)
    else
      error
    end
