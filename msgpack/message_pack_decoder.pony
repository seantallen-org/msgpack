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
  """
  //
  // nil format family
  //

  fun nil(b: Reader ref): None ? =>
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

  fun _read_type(b: Reader ref): MessagePackType ? =>
    b.u8()?

  //
  // str family
  //

  fun fixstr(b: Reader): String iso^ ? =>
    let len = (b.u8()?.usize() and _Limit.fixstr())
    String.from_iso_array(b.block(len)?)

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
