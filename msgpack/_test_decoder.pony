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
use "collections"
use "pony_check"
use "pony_test"

actor \nodoc\ _TestDecoder is TestList
  new make() =>
    None

  fun tag tests(test: PonyTest) =>
    test(_TestDecodeNil)
    test(_TestDecodeTrue)
    test(_TestDecodeFalse)
    test(_TestDecodeU8)
    test(_TestDecodeU16)
    test(_TestDecodeU32)
    test(_TestDecodeU64)
    test(_TestDecodeI8)
    test(_TestDecodeI16)
    test(_TestDecodeI32)
    test(_TestDecodeI64)
    test(_TestDecodePositiveFixint)
    test(_TestDecodeNegativeFixint)
    test(_TestDecodeF32)
    test(_TestDecodeF64)
    test(_TestDecodeFixstr)
    test(_TestDecodeStr8)
    test(_TestDecodeStr16)
    test(_TestDecodeStr32)
    test(_TestDecodeBin8)
    test(_TestDecodeBin16)
    test(_TestDecodeBin32)
    test(_TestDecodeFixarray)
    test(_TestDecodeArray16)
    test(_TestDecodeArray32)
    test(_TestDecodeFixmap)
    test(_TestDecodeMap16)
    test(_TestDecodeMap32)
    test(_TestDecodeFixext1)
    test(_TestDecodeFixext2)
    test(_TestDecodeFixext4)
    test(_TestDecodeFixext8)
    test(_TestDecodeFixext16)
    test(_TestDecodeExt8)
    test(_TestDecodeExt16)
    test(_TestDecodeExt32)
    test(_TestDecodeTimestamp32)
    test(_TestDecodeTimestamp64)
    test(_TestDecodeTimestamp96)
    test(_TestDecodeCompactUint)
    test(_TestDecodeCompactInt)
    test(_TestDecodeCompactStr)
    test(_TestDecodeCompactArray)
    test(_TestDecodeCompactMap)
    test(_TestDecodeCompactExt)
    test(_TestDecodeCompactTimestamp)
    test(Property1UnitTest[U64](
      _PropertyCompactUintRoundtrip))
    test(Property1UnitTest[I64](
      _PropertyCompactIntRoundtrip))
    test(Property1UnitTest[String](
      _PropertyCompactStrRoundtrip))
    test(Property1UnitTest[U32](
      _PropertyCompactArrayRoundtrip))
    test(Property1UnitTest[U32](
      _PropertyCompactMapRoundtrip))
    test(Property1UnitTest[U64](
      _PropertyCompactUintSmallestSize))
    test(Property1UnitTest[I64](
      _PropertyCompactIntSmallestSize))
    test(Property1UnitTest[String](
      _PropertyCompactStrSmallestSize))
    test(Property1UnitTest[U32](
      _PropertyCompactArraySmallestSize))
    test(Property1UnitTest[U32](
      _PropertyCompactMapSmallestSize))
    test(_TestDecodeCompactUintRejects)
    test(_TestDecodeCompactIntRejects)
    test(_TestDecodeCompactArrayRejects)
    test(_TestDecodeCompactMapRejects)

class \nodoc\ _TestDecodeNil is UnitTest
  fun name(): String =>
    "msgpack/DecodeNil"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    let b: Reader ref = Reader

    MessagePackEncoder.nil(w)

    for bs in w.done().values() do
      try
        b.append(bs as Array[U8] val)
      end
    end

    MessagePackDecoder.nil(b)?

class \nodoc\ _TestDecodeTrue is UnitTest
  fun name(): String =>
    "msgpack/DecodeTrue"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    let b: Reader ref = Reader

    MessagePackEncoder.bool(w, true)

    for bs in w.done().values() do
      try
        b.append(bs as Array[U8] val)
      end
    end

    h.assert_true(MessagePackDecoder.bool(b)?)

class \nodoc\ _TestDecodeFalse is UnitTest
  fun name(): String =>
    "msgpack/DecodeFalse"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    let b: Reader ref = Reader

    MessagePackEncoder.bool(w, false)

    for bs in w.done().values() do
      try
        b.append(bs as Array[U8] val)
      end
    end

    h.assert_false(MessagePackDecoder.bool(b)?)

class \nodoc\ _TestDecodeU8 is UnitTest
  fun name(): String =>
    "msgpack/DecodeU8"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    let b: Reader ref = Reader

    MessagePackEncoder.uint_8(w, 9)

    for bs in w.done().values() do
      try
        b.append(bs as Array[U8] val)
      end
    end

    h.assert_eq[U8](9, MessagePackDecoder.u8(b)?)

class \nodoc\ _TestDecodeU16 is UnitTest
  fun name(): String =>
    "msgpack/DecodeU16"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    let b: Reader ref = Reader

    MessagePackEncoder.uint_16(w, 17)

    for bs in w.done().values() do
      try
        b.append(bs as Array[U8] val)
      end
    end

    h.assert_eq[U16](17, MessagePackDecoder.u16(b)?)

class \nodoc\ _TestDecodeU32 is UnitTest
  fun name(): String =>
    "msgpack/DecodeU32"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    let b: Reader ref = Reader

    MessagePackEncoder.uint_32(w, 33)

    for bs in w.done().values() do
      try
        b.append(bs as Array[U8] val)
      end
    end

    h.assert_eq[U32](33, MessagePackDecoder.u32(b)?)

class \nodoc\ _TestDecodeU64 is UnitTest
  fun name(): String =>
    "msgpack/DecodeU64"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    let b: Reader ref = Reader

    MessagePackEncoder.uint_64(w, 65)

    for bs in w.done().values() do
      try
        b.append(bs as Array[U8] val)
      end
    end

    h.assert_eq[U64](65, MessagePackDecoder.u64(b)?)

class \nodoc\ _TestDecodeI8 is UnitTest
  fun name(): String =>
    "msgpack/DecodeI8"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    let b: Reader ref = Reader

    MessagePackEncoder.int_8(w, 9)

    for bs in w.done().values() do
      try
        b.append(bs as Array[U8] val)
      end
    end

    h.assert_eq[I8](9, MessagePackDecoder.i8(b)?)

class \nodoc\ _TestDecodeI16 is UnitTest
  fun name(): String =>
    "msgpack/DecodeI16"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    let b: Reader ref = Reader

    MessagePackEncoder.int_16(w, 17)

    for bs in w.done().values() do
      try
        b.append(bs as Array[U8] val)
      end
    end

    h.assert_eq[I16](17, MessagePackDecoder.i16(b)?)

class \nodoc\ _TestDecodeI32 is UnitTest
  fun name(): String =>
    "msgpack/DecodeI32"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    let b: Reader ref = Reader

    MessagePackEncoder.int_32(w, 33)

    for bs in w.done().values() do
      try
        b.append(bs as Array[U8] val)
      end
    end

    h.assert_eq[I32](33, MessagePackDecoder.i32(b)?)

class \nodoc\ _TestDecodeI64 is UnitTest
  fun name(): String =>
    "msgpack/DecodeI64"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    let b: Reader ref = Reader

    MessagePackEncoder.int_64(w, 65)

    for bs in w.done().values() do
      try
        b.append(bs as Array[U8] val)
      end
    end

    h.assert_eq[I64](65, MessagePackDecoder.i64(b)?)

class \nodoc\ _TestDecodePositiveFixint is UnitTest
  fun name(): String =>
    "msgpack/DecodePositiveFixint"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    let b: Reader ref = Reader

    MessagePackEncoder.positive_fixint(w, 17)?

    for bs in w.done().values() do
      try
        b.append(bs as Array[U8] val)
      end
    end

    h.assert_eq[U8](17, MessagePackDecoder.positive_fixint(b)?)

class \nodoc\ _TestDecodeNegativeFixint is UnitTest
  fun name(): String =>
    "msgpack/DecodeNegativeFixint"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    let b: Reader ref = Reader

    MessagePackEncoder.negative_fixint(w, -17)?

    for bs in w.done().values() do
      try
        b.append(bs as Array[U8] val)
      end
    end

    h.assert_eq[I8](-17, MessagePackDecoder.negative_fixint(b)?)

class \nodoc\ _TestDecodeF32 is UnitTest
  fun name(): String =>
    "msgpack/DecodeF32"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    let b: Reader ref = Reader

    MessagePackEncoder.float_32(w, 33.33)

    for bs in w.done().values() do
      try
        b.append(bs as Array[U8] val)
      end
    end

    h.assert_eq[F32](33.33, MessagePackDecoder.f32(b)?)

class \nodoc\ _TestDecodeF64 is UnitTest
  fun name(): String =>
    "msgpack/DecodeF64"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    let b: Reader ref = Reader

    MessagePackEncoder.float_64(w, 65.65)

    for bs in w.done().values() do
      try
        b.append(bs as Array[U8] val)
      end
    end

    h.assert_eq[F64](65.65, MessagePackDecoder.f64(b)?)

class \nodoc\ _TestDecodeFixstr is UnitTest
  fun name(): String =>
    "msgpack/DecodeFixstr"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    let b: Reader ref = Reader

    MessagePackEncoder.fixstr(w, "fixstr")?

    for bs in w.done().values() do
      b.append(bs)
    end

    h.assert_eq[String]("fixstr", MessagePackDecoder.fixstr(b)?)

class \nodoc\ _TestDecodeStr8 is UnitTest
  fun name(): String =>
    "msgpack/DecodeStr8"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    let b: Reader ref = Reader

    MessagePackEncoder.str_8(w, "str8")?

    for bs in w.done().values() do
      b.append(bs)
    end

    h.assert_eq[String]("str8", MessagePackDecoder.str(b)?)

class \nodoc\ _TestDecodeStr16 is UnitTest
  fun name(): String =>
    "msgpack/DecodeStr16"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    let b: Reader ref = Reader

    MessagePackEncoder.str_16(w, "str16")?

    for bs in w.done().values() do
      b.append(bs)
    end

    h.assert_eq[String]("str16", MessagePackDecoder.str(b)?)

class \nodoc\ _TestDecodeStr32 is UnitTest
  fun name(): String =>
    "msgpack/DecodeStr32"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    let b: Reader ref = Reader

    MessagePackEncoder.str_32(w, "str32")?

    for bs in w.done().values() do
      b.append(bs)
    end

    h.assert_eq[String]("str32", MessagePackDecoder.str(b)?)

class \nodoc\ _TestDecodeBin8 is UnitTest
  fun name(): String =>
    "msgpack/DecodeBin8"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    let b: Reader ref = Reader

    let value = recover val [as U8: 'H'; 'e'; 'l'; 'l'; 'o'] end
    MessagePackEncoder.bin_8(w, value)?

    for bs in w.done().values() do
      b.append(bs)
    end

    let decoded = MessagePackDecoder.byte_array(b)?
    h.assert_eq[U8]('H', decoded(0)?)
    h.assert_eq[U8]('e', decoded(1)?)
    h.assert_eq[U8]('l', decoded(2)?)
    h.assert_eq[U8]('l', decoded(3)?)
    h.assert_eq[U8]('o', decoded(4)?)

class \nodoc\ _TestDecodeBin16 is UnitTest
  fun name(): String =>
    "msgpack/DecodeBin16"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    let b: Reader ref = Reader

    let value = recover val [as U8: 'H'; 'e'; 'l'; 'l'; 'o'] end
    MessagePackEncoder.bin_16(w, value)?

    for bs in w.done().values() do
      b.append(bs)
    end

    let decoded = MessagePackDecoder.byte_array(b)?
    h.assert_eq[U8]('H', decoded(0)?)
    h.assert_eq[U8]('e', decoded(1)?)
    h.assert_eq[U8]('l', decoded(2)?)
    h.assert_eq[U8]('l', decoded(3)?)
    h.assert_eq[U8]('o', decoded(4)?)

class \nodoc\ _TestDecodeBin32 is UnitTest
  fun name(): String =>
    "msgpack/DecodeBin32"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    let b: Reader ref = Reader

    let value = recover val [as U8: 'H'; 'e'; 'l'; 'l'; 'o'] end
    MessagePackEncoder.bin_32(w, value)?

    for bs in w.done().values() do
      b.append(bs)
    end

    let decoded = MessagePackDecoder.byte_array(b)?
    h.assert_eq[U8]('H', decoded(0)?)
    h.assert_eq[U8]('e', decoded(1)?)
    h.assert_eq[U8]('l', decoded(2)?)
    h.assert_eq[U8]('l', decoded(3)?)
    h.assert_eq[U8]('o', decoded(4)?)

class \nodoc\ _TestDecodeFixarray is UnitTest
  fun name(): String =>
    "msgpack/DecodeFixarray"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    let b: Reader ref = Reader

    MessagePackEncoder.fixarray(w, 8)?

    for bs in w.done().values() do
      b.append(bs)
    end

    h.assert_eq[U8](8, MessagePackDecoder.fixarray(b)?)

class \nodoc\ _TestDecodeArray16 is UnitTest
  fun name(): String =>
    "msgpack/DecodeArray16"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    let b: Reader ref = Reader

    MessagePackEncoder.array_16(w, 17)

    for bs in w.done().values() do
      b.append(bs)
    end

    h.assert_eq[U16](17, MessagePackDecoder.array_16(b)?)

class \nodoc\ _TestDecodeArray32 is UnitTest
  fun name(): String =>
    "msgpack/DecodeArray32"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    let b: Reader ref = Reader

    MessagePackEncoder.array_32(w, 33)

    for bs in w.done().values() do
      b.append(bs)
    end

    h.assert_eq[U32](33, MessagePackDecoder.array_32(b)?)

class \nodoc\ _TestDecodeFixmap is UnitTest
  fun name(): String =>
    "msgpack/DecodeFixmap"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    let b: Reader ref = Reader

    MessagePackEncoder.fixmap(w, 8)?

    for bs in w.done().values() do
      b.append(bs)
    end

    h.assert_eq[U8](8, MessagePackDecoder.fixmap(b)?)

class \nodoc\ _TestDecodeMap16 is UnitTest
  fun name(): String =>
    "msgpack/DecodeMap16"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    let b: Reader ref = Reader

    MessagePackEncoder.map_16(w, 17)

    for bs in w.done().values() do
      b.append(bs)
    end

    h.assert_eq[U16](17, MessagePackDecoder.map_16(b)?)

class \nodoc\ _TestDecodeMap32 is UnitTest
  fun name(): String =>
    "msgpack/DecodeMap32"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    let b: Reader ref = Reader

    MessagePackEncoder.map_32(w, 33)

    for bs in w.done().values() do
      b.append(bs)
    end

    h.assert_eq[U32](33, MessagePackDecoder.map_32(b)?)

class \nodoc\ _TestDecodeFixext1 is UnitTest
  fun name(): String =>
    "msgpack/DecodeFixext1"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    let b: Reader ref = Reader

    let size = _Size.fixext_1()
    let user_type: U8 = 8
    let value = recover val Array[U8].init('V', size) end

    MessagePackEncoder.fixext_1(w, user_type, value)?

    for bs in w.done().values() do
      b.append(bs)
    end

    (let decoded_type, let decoded_value) = MessagePackDecoder.ext(b)?
    h.assert_eq[U8](user_type, decoded_type)
    h.assert_eq[USize](size, decoded_value.size())
    for i in Range(0, size) do
      h.assert_eq[U8]('V', decoded_value(i)?)
    end

class \nodoc\ _TestDecodeFixext2 is UnitTest
  fun name(): String =>
    "msgpack/DecodeFixext2"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    let b: Reader ref = Reader

    let size = _Size.fixext_2()
    let user_type: U8 = 8
    let value = recover val Array[U8].init('V', size) end

    MessagePackEncoder.fixext_2(w, user_type, value)?

    for bs in w.done().values() do
      b.append(bs)
    end

    (let decoded_type, let decoded_value) = MessagePackDecoder.ext(b)?
    h.assert_eq[U8](user_type, decoded_type)
    h.assert_eq[USize](size, decoded_value.size())
    for i in Range(0, size) do
      h.assert_eq[U8]('V', decoded_value(i)?)
    end

class \nodoc\ _TestDecodeFixext4 is UnitTest
  fun name(): String =>
    "msgpack/DecodeFixext4"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    let b: Reader ref = Reader

    let size = _Size.fixext_4()
    let user_type: U8 = 8
    let value = recover val Array[U8].init('V', size) end

    MessagePackEncoder.fixext_4(w, user_type, value)?

    for bs in w.done().values() do
      b.append(bs)
    end

    (let decoded_type, let decoded_value) = MessagePackDecoder.ext(b)?
    h.assert_eq[U8](user_type, decoded_type)
    h.assert_eq[USize](size, decoded_value.size())
    for i in Range(0, size) do
      h.assert_eq[U8]('V', decoded_value(i)?)
    end

class \nodoc\ _TestDecodeFixext8 is UnitTest
  fun name(): String =>
    "msgpack/DecodeFixext8"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    let b: Reader ref = Reader

    let size = _Size.fixext_8()
    let user_type: U8 = 8
    let value = recover val Array[U8].init('V', size) end

    MessagePackEncoder.fixext_8(w, user_type, value)?

    for bs in w.done().values() do
      b.append(bs)
    end

    (let decoded_type, let decoded_value) = MessagePackDecoder.ext(b)?
    h.assert_eq[U8](user_type, decoded_type)
    h.assert_eq[USize](size, decoded_value.size())
    for i in Range(0, size) do
      h.assert_eq[U8]('V', decoded_value(i)?)
    end

class \nodoc\ _TestDecodeFixext16 is UnitTest
  fun name(): String =>
    "msgpack/DecodeFixext16"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    let b: Reader ref = Reader

    let size = _Size.fixext_16()
    let user_type: U8 = 8
    let value = recover val Array[U8].init('V', size) end

    MessagePackEncoder.fixext_16(w, user_type, value)?

    for bs in w.done().values() do
      b.append(bs)
    end

    (let decoded_type, let decoded_value) = MessagePackDecoder.ext(b)?
    h.assert_eq[U8](user_type, decoded_type)
    h.assert_eq[USize](size, decoded_value.size())
    for i in Range(0, size) do
      h.assert_eq[U8]('V', decoded_value(i)?)
    end

class \nodoc\ _TestDecodeExt8 is UnitTest
  fun name(): String =>
    "msgpack/DecodeExt8"

  fun ref apply(h: TestHelper) ? =>
    let value = recover val [as U8: 'Y'; 'e'; 'l'; 'l'; 'o'] end
    let ext_type: U8 = 18
    let b: Reader ref = Reader
    let w: Writer ref = Writer

    MessagePackEncoder.ext_8(w, ext_type, value)?

    for bs in w.done().values() do
      b.append(bs)
    end

    (let decoded_type, let decoded_value) = MessagePackDecoder.ext(b)?
    h.assert_eq[U8](ext_type, decoded_type)
    h.assert_eq[U8]('Y', decoded_value(0)?)
    h.assert_eq[U8]('e', decoded_value(1)?)
    h.assert_eq[U8]('l', decoded_value(2)?)
    h.assert_eq[U8]('l', decoded_value(3)?)
    h.assert_eq[U8]('o', decoded_value(4)?)

class \nodoc\ _TestDecodeExt16 is UnitTest
  fun name(): String =>
    "msgpack/DecodeExt16"

  fun ref apply(h: TestHelper) ? =>
    let value = recover val [as U8: 'H'; 'e'; 'l'; 'l'; 'o'] end
    let ext_type: U8 = 99
    let b: Reader ref = Reader
    let w: Writer ref = Writer

    MessagePackEncoder.ext_16(w, ext_type, value)?

    for bs in w.done().values() do
      b.append(bs)
    end

    (let decoded_type, let decoded_value) = MessagePackDecoder.ext(b)?
    h.assert_eq[U8](ext_type, decoded_type)
    h.assert_eq[U8]('H', decoded_value(0)?)
    h.assert_eq[U8]('e', decoded_value(1)?)
    h.assert_eq[U8]('l', decoded_value(2)?)
    h.assert_eq[U8]('l', decoded_value(3)?)
    h.assert_eq[U8]('o', decoded_value(4)?)

class \nodoc\ _TestDecodeExt32 is UnitTest
  fun name(): String =>
    "msgpack/DecodeExt32"

  fun ref apply(h: TestHelper) ? =>
    let value = recover val [as U8: 'Y'; 'e'; 'x'; 'x'; 'o'] end
    let ext_type: U8 = 127
    let b: Reader ref = Reader
    let w: Writer ref = Writer

    MessagePackEncoder.ext_32(w, ext_type, value)?

    for bs in w.done().values() do
      b.append(bs)
    end

    (let decoded_type, let decoded_value) = MessagePackDecoder.ext(b)?
    h.assert_eq[U8](ext_type, decoded_type)
    h.assert_eq[U8]('Y', decoded_value(0)?)
    h.assert_eq[U8]('e', decoded_value(1)?)
    h.assert_eq[U8]('x', decoded_value(2)?)
    h.assert_eq[U8]('x', decoded_value(3)?)
    h.assert_eq[U8]('o', decoded_value(4)?)

class \nodoc\ _TestDecodeTimestamp32 is UnitTest
  fun name(): String =>
    "msgpack/DecodeTimestamp32"

  fun ref apply(h: TestHelper)? =>
    let encoded_sec: U32 = 500
    let b: Reader ref = Reader
    let w: Writer ref = Writer

    MessagePackEncoder.timestamp_32(w, encoded_sec)

    for bs in w.done().values() do
      b.append(bs)
    end

    (let decoded_sec, let decoded_nsec) = MessagePackDecoder.timestamp(b)?
    h.assert_eq[I64](decoded_sec, encoded_sec.i64())
    h.assert_eq[U32](decoded_nsec, 0)

class \nodoc\ _TestDecodeTimestamp64 is UnitTest
  fun name(): String =>
    "msgpack/DecodeTimestamp64"

  fun ref apply(h: TestHelper)? =>
    let encoded_sec = U64(_Limit.sec_34())
    let encoded_nsec = U32(_Limit.nsec())
    let b: Reader ref = Reader
    let w: Writer ref = Writer

    MessagePackEncoder.timestamp_64(w, encoded_sec, encoded_nsec)?

    for bs in w.done().values() do
      b.append(bs)
    end

    (let decoded_sec, let decoded_nsec) = MessagePackDecoder.timestamp(b)?
    h.assert_eq[I64](decoded_sec, _Limit.sec_34().i64())
    h.assert_eq[U32](decoded_nsec, _Limit.nsec())

class \nodoc\ _TestDecodeTimestamp96 is UnitTest
  fun name(): String =>
    "msgpack/DecodeTimestamp96"

  fun ref apply(h: TestHelper)? =>
    let encoded_sec = 0 - _Limit.sec_34().i64()
    let encoded_nsec = _Limit.nsec()
    let b: Reader ref = Reader
    let w: Writer ref = Writer

    MessagePackEncoder.timestamp_96(w, encoded_sec, encoded_nsec)?

    for bs in w.done().values() do
      b.append(bs)
    end

    (let decoded_sec, let decoded_nsec) = MessagePackDecoder.timestamp(b)?
    h.assert_eq[I64](decoded_sec, 0 - _Limit.sec_34().i64())
    h.assert_eq[U32](decoded_nsec, _Limit.nsec())

class \nodoc\ _TestDecodeCompactUint is UnitTest
  """
  Compact uint encode-then-decode roundtrip at each format
  boundary.
  """
  fun name(): String =>
    "msgpack/DecodeCompactUint"

  fun ref apply(h: TestHelper) ? =>
    _check(h, 0)?
    _check(h, 127)?
    _check(h, 128)?
    _check(h, 255)?
    _check(h, 256)?
    _check(h, 65535)?
    _check(h, 65536)?
    _check(h, U64.max_value())?

  fun _check(h: TestHelper, v: U64) ? =>
    let w: Writer ref = Writer
    let b: Reader ref = Reader

    MessagePackEncoder.uint(w, v)

    for bs in w.done().values() do
      b.append(bs)
    end

    h.assert_eq[U64](v, MessagePackDecoder.uint(b)?,
      "roundtrip " + v.string())

class \nodoc\ _TestDecodeCompactInt is UnitTest
  """
  Compact int encode-then-decode roundtrip at each format
  boundary.
  """
  fun name(): String =>
    "msgpack/DecodeCompactInt"

  fun ref apply(h: TestHelper) ? =>
    _check(h, 0)?
    _check(h, 127)?
    _check(h, -1)?
    _check(h, -32)?
    _check(h, 128)?
    _check(h, 255)?
    _check(h, -33)?
    _check(h, -128)?
    _check(h, 256)?
    _check(h, 65535)?
    _check(h, -129)?
    _check(h, -32768)?
    _check(h, 65536)?
    _check(h, U32.max_value().i64())?
    _check(h, -32769)?
    _check(h, I64.max_value())?
    _check(h, I64.min_value())?

  fun _check(h: TestHelper, v: I64) ? =>
    let w: Writer ref = Writer
    let b: Reader ref = Reader

    MessagePackEncoder.int(w, v)

    for bs in w.done().values() do
      b.append(bs)
    end

    h.assert_eq[I64](v, MessagePackDecoder.int(b)?,
      "roundtrip " + v.string())

class \nodoc\ _TestDecodeCompactStr is UnitTest
  """
  Compact str encode-then-decode roundtrip across format
  boundaries (fixstr and str_8).
  """
  fun name(): String =>
    "msgpack/DecodeCompactStr"

  fun ref apply(h: TestHelper) ? =>
    // fixstr (short string)
    _check(h, "Hello")?
    // str_8 (32 bytes, above fixstr limit)
    let medium = recover val
      String.from_array(
        recover val Array[U8].init('M', 32) end)
    end
    _check(h, medium)?

  fun _check(h: TestHelper, v: String val) ? =>
    let w: Writer ref = Writer
    let b: Reader ref = Reader

    MessagePackEncoder.str(w, v)?

    for bs in w.done().values() do
      b.append(bs)
    end

    h.assert_eq[String](v,
      MessagePackDecoder.str(b)?,
      "roundtrip len=" + v.size().string())

class \nodoc\ _TestDecodeCompactArray is UnitTest
  """
  Compact array encode-then-decode roundtrip across format
  boundaries.
  """
  fun name(): String =>
    "msgpack/DecodeCompactArray"

  fun ref apply(h: TestHelper) ? =>
    _check(h, 5)?      // fixarray
    _check(h, 300)?     // array_16
    _check(h, 70000)?   // array_32

  fun _check(h: TestHelper, v: U32) ? =>
    let w: Writer ref = Writer
    let b: Reader ref = Reader

    MessagePackEncoder.array(w, v)

    for bs in w.done().values() do
      b.append(bs)
    end

    h.assert_eq[U32](v, MessagePackDecoder.array(b)?,
      "roundtrip " + v.string())

class \nodoc\ _TestDecodeCompactMap is UnitTest
  """
  Compact map encode-then-decode roundtrip across format
  boundaries.
  """
  fun name(): String =>
    "msgpack/DecodeCompactMap"

  fun ref apply(h: TestHelper) ? =>
    _check(h, 5)?      // fixmap
    _check(h, 400)?     // map_16
    _check(h, 80000)?   // map_32

  fun _check(h: TestHelper, v: U32) ? =>
    let w: Writer ref = Writer
    let b: Reader ref = Reader

    MessagePackEncoder.map(w, v)

    for bs in w.done().values() do
      b.append(bs)
    end

    h.assert_eq[U32](v, MessagePackDecoder.map(b)?,
      "roundtrip " + v.string())

class \nodoc\ _TestDecodeCompactExt is UnitTest
  """
  Compact ext encode-then-decode roundtrip across fixext and
  variable-length formats.
  """
  fun name(): String =>
    "msgpack/DecodeCompactExt"

  fun ref apply(h: TestHelper) ? =>
    _check(h, 42, 1)?    // fixext_1
    _check(h, 42, 2)?    // fixext_2
    _check(h, 42, 4)?    // fixext_4
    _check(h, 42, 8)?    // fixext_8
    _check(h, 42, 16)?   // fixext_16
    _check(h, 42, 3)?    // ext_8 (non-fixext size)
    _check(h, 42, 0)?    // ext_8 (zero-length)

  fun _check(
    h: TestHelper,
    t: U8,
    data_size: USize)
    ?
  =>
    let value = recover val
      Array[U8].init('X', data_size)
    end
    let w: Writer ref = Writer
    let b: Reader ref = Reader

    MessagePackEncoder.ext(w, t, value)?

    for bs in w.done().values() do
      b.append(bs)
    end

    (let dt, let dv) = MessagePackDecoder.ext(b)?
    h.assert_eq[U8](t, dt,
      "type for size=" + data_size.string())
    h.assert_eq[USize](data_size, dv.size(),
      "data size for size=" + data_size.string())
    for i in Range(0, data_size) do
      h.assert_eq[U8]('X', dv(i)?,
        "data byte " + i.string())
    end

class \nodoc\ _TestDecodeCompactTimestamp is UnitTest
  """
  Compact timestamp encode-then-decode roundtrip across all
  three timestamp formats.
  """
  fun name(): String =>
    "msgpack/DecodeCompactTimestamp"

  fun ref apply(h: TestHelper) ? =>
    // timestamp_32: nsec=0, sec fits in U32
    _check(h, 500, 0)?
    // timestamp_64: nsec != 0, sec fits in 34 bits
    _check(h, 500, 100)?
    // timestamp_96: negative sec
    _check(h, -1000, 500)?

  fun _check(
    h: TestHelper,
    sec: I64,
    nsec: U32)
    ?
  =>
    let w: Writer ref = Writer
    let b: Reader ref = Reader

    MessagePackEncoder.timestamp(w, sec, nsec)?

    for bs in w.done().values() do
      b.append(bs)
    end

    (let ds, let dn) = MessagePackDecoder.timestamp(b)?
    h.assert_eq[I64](sec, ds,
      "sec for (" + sec.string() + ", "
        + nsec.string() + ")")
    h.assert_eq[U32](nsec, dn,
      "nsec for (" + sec.string() + ", "
        + nsec.string() + ")")

class \nodoc\ _TestDecodeCompactUintRejects is UnitTest
  """
  Compact uint errors on format bytes outside the unsigned
  integer family.
  """
  fun name(): String =>
    "msgpack/DecodeCompactUintRejects"

  fun ref apply(h: TestHelper) =>
    // nil (0xC0)
    _rejects(h, _FormatName.nil())
    // bool (0xC3)
    _rejects(h, _FormatName.truthy())
    // str_8 (0xD9)
    _rejects(h, _FormatName.str_8())
    // fixstr (0xA5)
    _rejects(h, _FormatName.fixstr() or 0x05)
    // negative fixint (0xE0)
    _rejects(h, _FormatName.negative_fixint())

  fun _rejects(h: TestHelper, format_byte: U8) =>
    let b: Reader ref = Reader
    b.append(
      recover val [as U8: format_byte] end)
    try
      MessagePackDecoder.uint(b)?
      h.fail("uint accepted 0x"
        + format_byte.string())
    end

class \nodoc\ _TestDecodeCompactIntRejects is UnitTest
  """
  Compact int errors on format bytes outside the integer
  family (signed + unsigned + fixint).
  """
  fun name(): String =>
    "msgpack/DecodeCompactIntRejects"

  fun ref apply(h: TestHelper) =>
    // nil (0xC0)
    _rejects(h, _FormatName.nil())
    // float_32 (0xCA)
    _rejects(h, _FormatName.float_32())
    // str_8 (0xD9)
    _rejects(h, _FormatName.str_8())
    // fixarray (0x95)
    _rejects(h, _FormatName.fixarray() or 0x05)

  fun _rejects(h: TestHelper, format_byte: U8) =>
    let b: Reader ref = Reader
    b.append(
      recover val [as U8: format_byte] end)
    try
      MessagePackDecoder.int(b)?
      h.fail("int accepted 0x"
        + format_byte.string())
    end

class \nodoc\ _TestDecodeCompactArrayRejects is UnitTest
  """
  Compact array errors on format bytes outside the array
  family.
  """
  fun name(): String =>
    "msgpack/DecodeCompactArrayRejects"

  fun ref apply(h: TestHelper) =>
    // nil (0xC0)
    _rejects(h, _FormatName.nil())
    // uint_8 (0xCC)
    _rejects(h, _FormatName.uint_8())
    // fixmap (0x85)
    _rejects(h, _FormatName.fixmap() or 0x05)

  fun _rejects(h: TestHelper, format_byte: U8) =>
    let b: Reader ref = Reader
    b.append(
      recover val [as U8: format_byte] end)
    try
      MessagePackDecoder.array(b)?
      h.fail("array accepted 0x"
        + format_byte.string())
    end

class \nodoc\ _TestDecodeCompactMapRejects is UnitTest
  """
  Compact map errors on format bytes outside the map family.
  """
  fun name(): String =>
    "msgpack/DecodeCompactMapRejects"

  fun ref apply(h: TestHelper) =>
    // nil (0xC0)
    _rejects(h, _FormatName.nil())
    // uint_8 (0xCC)
    _rejects(h, _FormatName.uint_8())
    // fixarray (0x95)
    _rejects(h, _FormatName.fixarray() or 0x05)

  fun _rejects(h: TestHelper, format_byte: U8) =>
    let b: Reader ref = Reader
    b.append(
      recover val [as U8: format_byte] end)
    try
      MessagePackDecoder.map(b)?
      h.fail("map accepted 0x"
        + format_byte.string())
    end

class \nodoc\ _PropertyCompactUintRoundtrip
  is Property1[U64]
  """
  For any U64, compact uint encode then decode returns the
  original value. Generator covers all five format ranges.
  """
  fun name(): String =>
    "msgpack/PropertyCompactUintRoundtrip"

  fun gen(): Generator[U64] =>
    Generators.frequency[U64]([
      as WeightedGenerator[U64]:
      (2, Generators.u8().map[U64]({(v) =>
        (v and 0x7F).u64()}))              // fixint
      (2, Generators.u8().map[U64]({(v) =>
        (v or 0x80).u64()}))               // uint_8
      (2, Generators.u16().map[U64]({(v) =>
        v.u64() + 256}))                   // uint_16
      (2, Generators.u32().map[U64]({(v) =>
        v.u64() + 65536}))                 // uint_32
      (2, Generators.u64())                // uint_64
    ])

  fun ref property(arg1: U64, h: PropertyHelper) ? =>
    let w: Writer ref = Writer
    let b: Reader ref = Reader

    MessagePackEncoder.uint(w, arg1)

    for bs in w.done().values() do
      b.append(bs)
    end

    h.assert_eq[U64](arg1, MessagePackDecoder.uint(b)?)

class \nodoc\ _PropertyCompactIntRoundtrip
  is Property1[I64]
  """
  For any I64, compact int encode then decode returns the
  original value. Generator covers all ten format ranges.
  """
  fun name(): String =>
    "msgpack/PropertyCompactIntRoundtrip"

  fun gen(): Generator[I64] =>
    Generators.frequency[I64]([
      as WeightedGenerator[I64]:
      (2, Generators.u8().map[I64]({(v) =>
        (v and 0x7F).i64()}))              // pos fixint
      (2, Generators.u8().map[I64]({(v) =>
        -((v % 32).i64() + 1)}))           // neg fixint
      (1, Generators.u8().map[I64]({(v) =>
        (v or 0x80).i64()}))               // uint_8
      (1, Generators.u8().map[I64]({(v) =>
        -((v % 96).i64() + 33)}))          // int_8
      (1, Generators.u16().map[I64]({(v) =>
        v.i64() + 256}))                   // uint_16
      (1, Generators.u16().map[I64]({(v) =>
        -(v.i64() + 129)}))                // int_16
      (1, Generators.u32().map[I64]({(v) =>
        v.i64() + 65536}))                 // uint_32
      (1, Generators.u32().map[I64]({(v) =>
        -(v.i64() + 32769)}))              // int_32
      (1, Generators.i64())                // int_64/uint_64
    ])

  fun ref property(arg1: I64, h: PropertyHelper) ? =>
    let w: Writer ref = Writer
    let b: Reader ref = Reader

    MessagePackEncoder.int(w, arg1)

    for bs in w.done().values() do
      b.append(bs)
    end

    h.assert_eq[I64](arg1, MessagePackDecoder.int(b)?)

class \nodoc\ _PropertyCompactStrRoundtrip
  is Property1[String]
  """
  For any ASCII string, compact str encode then decode returns
  the original string. Generator covers all three format
  boundaries: fixstr (0-31), str_8 (32-255), str_16 (256+).
  """
  fun name(): String =>
    "msgpack/PropertyCompactStrRoundtrip"

  fun gen(): Generator[String] =>
    Generators.frequency[String]([
      as WeightedGenerator[String]:
      (5, Generators.ascii_printable(
        0, _Limit.fixstr()))
      (3, Generators.ascii_printable(
        _Limit.fixstr() + 1,
        U8.max_value().usize()))
      (2, Generators.ascii_printable(
        U8.max_value().usize() + 1, 300))
    ])

  fun ref property(arg1: String, h: PropertyHelper) ? =>
    let s: String val = arg1.clone()
    let w: Writer ref = Writer
    let b: Reader ref = Reader

    MessagePackEncoder.str(w, s)?

    for bs in w.done().values() do
      b.append(bs)
    end

    h.assert_eq[String](s, MessagePackDecoder.str(b)?)

class \nodoc\ _PropertyCompactArrayRoundtrip
  is Property1[U32]
  """
  For any U32, compact array encode then decode returns the
  original count. Generator covers all three format ranges.
  """
  fun name(): String =>
    "msgpack/PropertyCompactArrayRoundtrip"

  fun gen(): Generator[U32] =>
    Generators.frequency[U32]([
      as WeightedGenerator[U32]:
      (3, Generators.u8().map[U32]({(v) =>
        (v and 0x0F).u32()}))              // fixarray
      (3, Generators.u16().map[U32]({(v) =>
        v.u32() + 16}))                    // array_16
      (4, Generators.u32().map[U32]({(v) =>
        if v < 65536 then v + 65536
        else v end}))                      // array_32
    ])

  fun ref property(arg1: U32, h: PropertyHelper) ? =>
    let w: Writer ref = Writer
    let b: Reader ref = Reader

    MessagePackEncoder.array(w, arg1)

    for bs in w.done().values() do
      b.append(bs)
    end

    h.assert_eq[U32](arg1, MessagePackDecoder.array(b)?)

class \nodoc\ _PropertyCompactMapRoundtrip
  is Property1[U32]
  """
  For any U32, compact map encode then decode returns the
  original count. Generator covers all three format ranges.
  """
  fun name(): String =>
    "msgpack/PropertyCompactMapRoundtrip"

  fun gen(): Generator[U32] =>
    Generators.frequency[U32]([
      as WeightedGenerator[U32]:
      (3, Generators.u8().map[U32]({(v) =>
        (v and 0x0F).u32()}))              // fixmap
      (3, Generators.u16().map[U32]({(v) =>
        v.u32() + 16}))                    // map_16
      (4, Generators.u32().map[U32]({(v) =>
        if v < 65536 then v + 65536
        else v end}))                      // map_32
    ])

  fun ref property(arg1: U32, h: PropertyHelper) ? =>
    let w: Writer ref = Writer
    let b: Reader ref = Reader

    MessagePackEncoder.map(w, arg1)

    for bs in w.done().values() do
      b.append(bs)
    end

    h.assert_eq[U32](arg1, MessagePackDecoder.map(b)?)

class \nodoc\ _PropertyCompactUintSmallestSize
  is Property1[U64]
  """
  For any U64, compact uint encoding produces output whose
  size is <= every format-specific encoding that could
  represent the same value. This verifies format selection
  independently of decode correctness.
  """
  fun name(): String =>
    "msgpack/PropertyCompactUintSmallestSize"

  fun gen(): Generator[U64] =>
    Generators.frequency[U64]([
      as WeightedGenerator[U64]:
      (2, Generators.u8().map[U64]({(v) =>
        (v and 0x7F).u64()}))              // fixint
      (2, Generators.u8().map[U64]({(v) =>
        (v or 0x80).u64()}))               // uint_8
      (2, Generators.u16().map[U64]({(v) =>
        v.u64() + 256}))                   // uint_16
      (2, Generators.u32().map[U64]({(v) =>
        v.u64() + 65536}))                 // uint_32
      (2, Generators.u64())                // uint_64
    ])

  fun ref property(arg1: U64, h: PropertyHelper) ? =>
    let wc: Writer ref = Writer
    MessagePackEncoder.uint(wc, arg1)
    let compact = _writer_size(wc)

    // uint_64 is always applicable
    let w64: Writer ref = Writer
    MessagePackEncoder.uint_64(w64, arg1)
    h.assert_true(compact <= _writer_size(w64),
      "compact <= uint_64 for " + arg1.string())

    if arg1 <= U32.max_value().u64() then
      let w32: Writer ref = Writer
      MessagePackEncoder.uint_32(w32, arg1.u32())
      h.assert_true(compact <= _writer_size(w32),
        "compact <= uint_32 for "
          + arg1.string())
    end

    if arg1 <= U16.max_value().u64() then
      let w16: Writer ref = Writer
      MessagePackEncoder.uint_16(w16, arg1.u16())
      h.assert_true(compact <= _writer_size(w16),
        "compact <= uint_16 for "
          + arg1.string())
    end

    if arg1 <= U8.max_value().u64() then
      let w8: Writer ref = Writer
      MessagePackEncoder.uint_8(w8, arg1.u8())
      h.assert_true(compact <= _writer_size(w8),
        "compact <= uint_8 for "
          + arg1.string())
    end

    if arg1 <= _Limit.positive_fixint().u64() then
      let wf: Writer ref = Writer
      MessagePackEncoder.positive_fixint(wf,
        arg1.u8())?
      h.assert_true(compact <= _writer_size(wf),
        "compact <= fixint for "
          + arg1.string())
    end

  fun _writer_size(w: Writer ref): USize =>
    let b = Reader
    for bs in w.done().values() do
      b.append(bs)
    end
    b.size()

class \nodoc\ _PropertyCompactIntSmallestSize
  is Property1[I64]
  """
  For any I64, compact int encoding produces output whose
  size is <= every format-specific encoding that could
  represent the same value.
  """
  fun name(): String =>
    "msgpack/PropertyCompactIntSmallestSize"

  fun gen(): Generator[I64] =>
    Generators.frequency[I64]([
      as WeightedGenerator[I64]:
      (2, Generators.u8().map[I64]({(v) =>
        (v and 0x7F).i64()}))              // pos fixint
      (2, Generators.u8().map[I64]({(v) =>
        -((v % 32).i64() + 1)}))           // neg fixint
      (1, Generators.u8().map[I64]({(v) =>
        (v or 0x80).i64()}))               // uint_8
      (1, Generators.u8().map[I64]({(v) =>
        -((v % 96).i64() + 33)}))          // int_8
      (1, Generators.u16().map[I64]({(v) =>
        v.i64() + 256}))                   // uint_16
      (1, Generators.u16().map[I64]({(v) =>
        -(v.i64() + 129)}))                // int_16
      (1, Generators.u32().map[I64]({(v) =>
        v.i64() + 65536}))                 // uint_32
      (1, Generators.u32().map[I64]({(v) =>
        -(v.i64() + 32769)}))              // int_32
      (1, Generators.i64())                // int_64/uint_64
    ])

  fun ref property(arg1: I64, h: PropertyHelper) =>
    let wc: Writer ref = Writer
    MessagePackEncoder.int(wc, arg1)
    let compact = _writer_size(wc)

    // int_64 is always applicable
    let w64: Writer ref = Writer
    MessagePackEncoder.int_64(w64, arg1)
    h.assert_true(compact <= _writer_size(w64),
      "compact <= int_64 for " + arg1.string())

    if (arg1 >= I32.min_value().i64())
      and (arg1 <= I32.max_value().i64())
    then
      let w32: Writer ref = Writer
      MessagePackEncoder.int_32(w32, arg1.i32())
      h.assert_true(compact <= _writer_size(w32),
        "compact <= int_32 for "
          + arg1.string())
    end

    if (arg1 >= I16.min_value().i64())
      and (arg1 <= I16.max_value().i64())
    then
      let w16: Writer ref = Writer
      MessagePackEncoder.int_16(w16, arg1.i16())
      h.assert_true(compact <= _writer_size(w16),
        "compact <= int_16 for "
          + arg1.string())
    end

    if (arg1 >= I8.min_value().i64())
      and (arg1 <= I8.max_value().i64())
    then
      let w8: Writer ref = Writer
      MessagePackEncoder.int_8(w8, arg1.i8())
      h.assert_true(compact <= _writer_size(w8),
        "compact <= int_8 for "
          + arg1.string())
    end

    if arg1 >= 0 then
      if arg1 <= U8.max_value().i64() then
        let wu8: Writer ref = Writer
        MessagePackEncoder.uint_8(wu8, arg1.u8())
        h.assert_true(
          compact <= _writer_size(wu8),
          "compact <= uint_8 for "
            + arg1.string())
      end
      if arg1 <= U16.max_value().i64() then
        let wu16: Writer ref = Writer
        MessagePackEncoder.uint_16(wu16,
          arg1.u16())
        h.assert_true(
          compact <= _writer_size(wu16),
          "compact <= uint_16 for "
            + arg1.string())
      end
      if arg1 <= U32.max_value().i64() then
        let wu32: Writer ref = Writer
        MessagePackEncoder.uint_32(wu32,
          arg1.u32())
        h.assert_true(
          compact <= _writer_size(wu32),
          "compact <= uint_32 for "
            + arg1.string())
      end
      let wu64: Writer ref = Writer
      MessagePackEncoder.uint_64(wu64, arg1.u64())
      h.assert_true(
        compact <= _writer_size(wu64),
        "compact <= uint_64 for "
          + arg1.string())
    end

  fun _writer_size(w: Writer ref): USize =>
    let b = Reader
    for bs in w.done().values() do
      b.append(bs)
    end
    b.size()

class \nodoc\ _PropertyCompactStrSmallestSize
  is Property1[String]
  """
  For any string, compact str encoding produces output whose
  size is <= every format-specific encoding that could
  represent the same value.
  """
  fun name(): String =>
    "msgpack/PropertyCompactStrSmallestSize"

  fun gen(): Generator[String] =>
    Generators.frequency[String]([
      as WeightedGenerator[String]:
      (5, Generators.ascii_printable(
        0, _Limit.fixstr()))
      (3, Generators.ascii_printable(
        _Limit.fixstr() + 1,
        U8.max_value().usize()))
      (2, Generators.ascii_printable(
        U8.max_value().usize() + 1, 300))
    ])

  fun ref property(arg1: String, h: PropertyHelper)
    ?
  =>
    let s: String val = arg1.clone()
    let wc: Writer ref = Writer
    MessagePackEncoder.str(wc, s)?
    let compact = _writer_size(wc)

    // str_32 is always applicable for test sizes
    let w32: Writer ref = Writer
    MessagePackEncoder.str_32(w32, s)?
    h.assert_true(compact <= _writer_size(w32),
      "compact <= str_32 for len="
        + s.size().string())

    if s.size() <= U16.max_value().usize() then
      let w16: Writer ref = Writer
      MessagePackEncoder.str_16(w16, s)?
      h.assert_true(compact <= _writer_size(w16),
        "compact <= str_16 for len="
          + s.size().string())
    end

    if s.size() <= U8.max_value().usize() then
      let w8: Writer ref = Writer
      MessagePackEncoder.str_8(w8, s)?
      h.assert_true(compact <= _writer_size(w8),
        "compact <= str_8 for len="
          + s.size().string())
    end

    if s.size() <= _Limit.fixstr() then
      let wf: Writer ref = Writer
      MessagePackEncoder.fixstr(wf, s)?
      h.assert_true(compact <= _writer_size(wf),
        "compact <= fixstr for len="
          + s.size().string())
    end

  fun _writer_size(w: Writer ref): USize =>
    let b = Reader
    for bs in w.done().values() do
      b.append(bs)
    end
    b.size()

class \nodoc\ _PropertyCompactArraySmallestSize
  is Property1[U32]
  """
  For any U32, compact array encoding produces output whose
  size is <= every format-specific encoding that could
  represent the same value.
  """
  fun name(): String =>
    "msgpack/PropertyCompactArraySmallestSize"

  fun gen(): Generator[U32] =>
    Generators.frequency[U32]([
      as WeightedGenerator[U32]:
      (3, Generators.u8().map[U32]({(v) =>
        (v and 0x0F).u32()}))              // fixarray
      (3, Generators.u16().map[U32]({(v) =>
        v.u32() + 16}))                    // array_16
      (4, Generators.u32().map[U32]({(v) =>
        if v < 65536 then v + 65536
        else v end}))                      // array_32
    ])

  fun ref property(arg1: U32, h: PropertyHelper) ? =>
    let wc: Writer ref = Writer
    MessagePackEncoder.array(wc, arg1)
    let compact = _writer_size(wc)

    // array_32 is always applicable
    let w32: Writer ref = Writer
    MessagePackEncoder.array_32(w32, arg1)
    h.assert_true(compact <= _writer_size(w32),
      "compact <= array_32 for "
        + arg1.string())

    if arg1 <= U16.max_value().u32() then
      let w16: Writer ref = Writer
      MessagePackEncoder.array_16(w16, arg1.u16())
      h.assert_true(compact <= _writer_size(w16),
        "compact <= array_16 for "
          + arg1.string())
    end

    if arg1 <= _Limit.fixarray().u32() then
      let wf: Writer ref = Writer
      MessagePackEncoder.fixarray(wf, arg1.u8())?
      h.assert_true(compact <= _writer_size(wf),
        "compact <= fixarray for "
          + arg1.string())
    end

  fun _writer_size(w: Writer ref): USize =>
    let b = Reader
    for bs in w.done().values() do
      b.append(bs)
    end
    b.size()

class \nodoc\ _PropertyCompactMapSmallestSize
  is Property1[U32]
  """
  For any U32, compact map encoding produces output whose
  size is <= every format-specific encoding that could
  represent the same value.
  """
  fun name(): String =>
    "msgpack/PropertyCompactMapSmallestSize"

  fun gen(): Generator[U32] =>
    Generators.frequency[U32]([
      as WeightedGenerator[U32]:
      (3, Generators.u8().map[U32]({(v) =>
        (v and 0x0F).u32()}))              // fixmap
      (3, Generators.u16().map[U32]({(v) =>
        v.u32() + 16}))                    // map_16
      (4, Generators.u32().map[U32]({(v) =>
        if v < 65536 then v + 65536
        else v end}))                      // map_32
    ])

  fun ref property(arg1: U32, h: PropertyHelper) ? =>
    let wc: Writer ref = Writer
    MessagePackEncoder.map(wc, arg1)
    let compact = _writer_size(wc)

    // map_32 is always applicable
    let w32: Writer ref = Writer
    MessagePackEncoder.map_32(w32, arg1)
    h.assert_true(compact <= _writer_size(w32),
      "compact <= map_32 for "
        + arg1.string())

    if arg1 <= U16.max_value().u32() then
      let w16: Writer ref = Writer
      MessagePackEncoder.map_16(w16, arg1.u16())
      h.assert_true(compact <= _writer_size(w16),
        "compact <= map_16 for "
          + arg1.string())
    end

    if arg1 <= _Limit.fixmap().u32() then
      let wf: Writer ref = Writer
      MessagePackEncoder.fixmap(wf, arg1.u8())?
      h.assert_true(compact <= _writer_size(wf),
        "compact <= fixmap for "
          + arg1.string())
    end

  fun _writer_size(w: Writer ref): USize =>
    let b = Reader
    for bs in w.done().values() do
      b.append(bs)
    end
    b.size()
