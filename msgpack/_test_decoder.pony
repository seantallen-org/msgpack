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
    h.assert_eq[I64](decoded_nsec, I64(0))

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
    h.assert_eq[I64](decoded_nsec, _Limit.nsec().i64())

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
    h.assert_eq[I64](decoded_nsec, _Limit.nsec().i64())
