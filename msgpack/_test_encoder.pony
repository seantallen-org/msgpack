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

actor \nodoc\ _TestEncoder is TestList
  """
  These tests include information from the [MessagePack specification](https://github.com/msgpack/msgpack/blob/master/spec.md).

  ### Notation in test diagrams.

    one byte:
    +--------+
    |        |
    +--------+

    a variable number of bytes:
    +========+
    |        |
    +========+

    variable number of objects stored in MessagePack format:
    +~~~~~~~~~~~~~~~~~+
    |                 |
    +~~~~~~~~~~~~~~~~~+
  """
  new make() =>
    None

  fun tag tests(test: PonyTest) =>
    test(_TestEncodeNil)
    test(_TestEncodeTrue)
    test(_TestEncodeFalse)
    test(_TestEncodePositiveFixint)
    test(_TestEncodePositiveFixintTooLarge)
    test(_TestEncodeNegativeFixint)
    test(_TestEncodeNegativeFixintOutOfRange)
    test(_TestEncodeUint8)
    test(_TestEncodeUint16)
    test(_TestEncodeUint32)
    test(_TestEncodeUint64)
    test(_TestEncodeInt8)
    test(_TestEncodeInt16)
    test(_TestEncodeInt32)
    test(_TestEncodeInt64)
    test(_TestEncodeFloat32)
    test(_TestEncodeFloat64)
    test(_TestEncodeFixstr)
    test(_TestEncodeFixstrTooLarge)
    test(_TestEncodeStr8)
    test(_TestEncodeStr8TooLarge)
    test(_TestEncodeStr16)
    test(_TestEncodeStr32)
    test(_TestEncodeBin8)
    test(_TestEncodeBin16)
    test(_TestEncodeBin32)
    test(_TestEncodeFixarray)
    test(_TestEncodeFixarrayTooLarge)
    test(_TestEncodeArray16)
    test(_TestEncodeArray32)
    test(_TestEncodeFixmap)
    test(_TestEncodeFixmapTooLarge)
    test(_TestEncodeMap16)
    test(_TestEncodeMap32)
    test(_TestEncodeFixext1)
    test(_TestEncodeFixext1IncorrectSize)
    test(_TestEncodeFixext2)
    test(_TestEncodeFixext2IncorrectSize)
    test(_TestEncodeFixext4)
    test(_TestEncodeFixext4IncorrectSize)
    test(_TestEncodeFixext8)
    test(_TestEncodeFixext8IncorrectSize)
    test(_TestEncodeFixext16)
    test(_TestEncodeFixext16IncorrectSize)
    test(_TestEncodeExt8)
    test(_TestEncodeExt8TooLarge)
    test(_TestEncodeExt16)
    test(_TestEncodeExt32)
    test(_TestEncodeTimestamp32)
    test(_TestEncodeTimestamp64)
    test(_TestEncodeTimestamp64SecsTooLarge)
    test(_TestEncodeTimestamp64NsecsTooLarge)
    test(_TestEncodeTimestamp96)
    test(_TestEncodeTimestamp96NsecsTooLarge)
    test(_TestEncodeCompactUint)
    test(_TestEncodeCompactInt)
    test(_TestEncodeCompactStr)
    test(_TestEncodeCompactBin)
    test(_TestEncodeCompactArray)
    test(_TestEncodeCompactMap)
    test(_TestEncodeCompactExt)
    test(_TestEncodeCompactTimestamp)
    // UTF-8 validating variants
    test(_TestEncodeFixstrUtf8)
    test(_TestEncodeFixstrUtf8Invalid)
    test(_TestEncodeStr8Utf8)
    test(_TestEncodeStr8Utf8Invalid)
    test(_TestEncodeStr16Utf8)
    test(_TestEncodeStr16Utf8Invalid)
    test(_TestEncodeStr32Utf8)
    test(_TestEncodeStr32Utf8Invalid)
    test(_TestEncodeCompactStrUtf8)
    test(_TestEncodeCompactStrUtf8Invalid)
    test(_TestEncodeStrUtf8ByteArray)
    test(Property1UnitTest[String](
      _PropertyCompactStrUtf8EncoderRoundtrip))
ifdef not "ci" then
    // These 2 tests take up a lot of memory.
    // CircleCI where CI is run only has 4 gigs of memory
    // The make "test-ci" target for the Makefile defines "ci" so that
    // these won't run and trigger the OOM killer
    test(_TestEncodeStr16TooLarge)
    test(_TestEncodeStr32TooLarge)
    test(_TestEncodeExt16TooLarge)
    test(_TestEncodeExt32TooLarge)
end

class \nodoc\ _TestEncodeNil is UnitTest
  """
  Nil format stores nil in 1 byte.

  nil:
  +--------+
  |  0xc0  |
  +--------+
  """
  fun name(): String =>
    "msgpack/EncodeNil"

  fun ref apply(h: TestHelper) ? =>
    let b = Reader
    let w: Writer ref = Writer

    MessagePackEncoder.nil(w)

    for bs in w.done().values() do
      b.append(bs)
    end

    h.assert_eq[USize](1, b.size())
    h.assert_eq[U8](_FormatName.nil(), b.peek_u8()?)

class \nodoc\ _TestEncodeTrue is UnitTest
  """
  Bool format family stores false or true in 1 byte.

  true:
  +--------+
  |  0xc3  |
  +--------+
  """
  fun name(): String =>
    "msgpack/EncodeTrue"

  fun ref apply(h: TestHelper) ? =>
    let b = Reader
    let w: Writer ref = Writer

    MessagePackEncoder.bool(w, true)

    for bs in w.done().values() do
      b.append(bs)
    end

    h.assert_eq[USize](1, b.size())
    h.assert_eq[U8](_FormatName.truthy(), b.peek_u8()?)

class \nodoc\ _TestEncodeFalse is UnitTest
  """
  Bool format family stores false or true in 1 byte.

  false:
  +--------+
  |  0xc2  |
  +--------+
  """
  fun name(): String =>
    "msgpack/EncodeFalse"

  fun ref apply(h: TestHelper) ? =>
    let b = Reader
    let w: Writer ref = Writer

    MessagePackEncoder.bool(w, false)

    for bs in w.done().values() do
      b.append(bs)
    end

    h.assert_eq[USize](1, b.size())
    h.assert_eq[U8](_FormatName.falsey(), b.peek_u8()?)

class \nodoc\ _TestEncodePositiveFixint is UnitTest
  """
  positive fixnum stores 7-bit positive integer
  +--------+
  |0XXXXXXX|
  +--------+
  """
  fun name(): String =>
    "msgpack/EncodePositiveFixint"

  fun ref apply(h: TestHelper) ? =>
    let value: U8 = 10
    let b = Reader
    let w: Writer ref = Writer

    MessagePackEncoder.positive_fixint(w, value)?

    for bs in w.done().values() do
      b.append(bs)
    end

    h.assert_true(value <= _Limit.positive_fixint())
    h.assert_eq[USize](1, b.size())
    h.assert_eq[U8](0x0a, b.peek_u8()?)

class \nodoc\ _TestEncodePositiveFixintTooLarge is UnitTest
  """
  Verify an exception is thrown if the user attempts to encode a value in a
  positive fixnum that is too large.
  """
  fun name(): String =>
    "msgpack/EncodePositiveFixintTooLarge"

  fun ref apply(h: TestHelper) =>
    let value: U8 = _Limit.positive_fixint() + 1
    let w: Writer ref = Writer

    try
      MessagePackEncoder.positive_fixint(w, value)?
      h.fail()
    end

class \nodoc\ _TestEncodeNegativeFixint is UnitTest
  """
  negative fixnum stores 5-bit negative integer
  +--------+
  |111YYYYY|
  +--------+
  """
  fun name(): String =>
    "msgpack/EncodeNegativeFixint"

  fun ref apply(h: TestHelper) ? =>
    let value: I8 = -10
    let b = Reader
    let w: Writer ref = Writer

    MessagePackEncoder.negative_fixint(w, value)?

    for bs in w.done().values() do
      b.append(bs)
    end

    h.assert_true(value <= _Limit.negative_fixint_high())
    h.assert_true(value >= _Limit.negative_fixint_low())
    h.assert_eq[USize](1, b.size())
    h.assert_eq[U8](0xF6, b.peek_u8()?)

class \nodoc\ _TestEncodeNegativeFixintOutOfRange is UnitTest
  """
  Verify an exception is thrown if the user attempts to encode a value in a
  negative fixnum is outside the valid range.
  """
  fun name(): String =>
    "msgpack/EncodeNegativeFixintOutOfRange"

  fun ref apply(h: TestHelper) =>
    let value: I8 = _Limit.negative_fixint_low() - 1
    let w: Writer ref = Writer

    try
      MessagePackEncoder.negative_fixint(w, value)?
      h.fail()
    end

class \nodoc\ _TestEncodeUint8 is UnitTest
  """
  uint 8 stores a 8-bit unsigned integer
  +--------+--------+
  |  0xcc  |ZZZZZZZZ|
  +--------+--------+
  """
  fun name(): String =>
    "msgpack/EncodeUint8"

  fun ref apply(h: TestHelper) ? =>
    let value: U8 = U8.max_value() - 1
    let b = Reader
    let w: Writer ref = Writer

    MessagePackEncoder.uint_8(w, value)

    for bs in w.done().values() do
      b.append(bs)
    end

    h.assert_eq[USize](2, b.size())
    h.assert_eq[U8](_FormatName.uint_8(), b.peek_u8()?)
    h.assert_eq[U8](value, b.peek_u8(1)?)

class \nodoc\ _TestEncodeUint16 is UnitTest
  """
  uint 16 stores a 16-bit big-endian unsigned integer
  +--------+--------+--------+
  |  0xcd  |ZZZZZZZZ|ZZZZZZZZ|
  +--------+--------+--------+
  """
  fun name(): String =>
    "msgpack/EncodeUint16"

  fun ref apply(h: TestHelper) ? =>
    let value: U16 = U16.max_value() - 1
    let b = Reader
    let w: Writer ref = Writer

    MessagePackEncoder.uint_16(w, value)

    for bs in w.done().values() do
      b.append(bs)
    end

    h.assert_eq[USize](3, b.size())
    h.assert_eq[U8](_FormatName.uint_16(), b.peek_u8()?)
    h.assert_eq[U16](value, b.peek_u16_be(1)?)

class \nodoc\ _TestEncodeUint32 is UnitTest
  """
  uint 32 stores a 32-bit big-endian unsigned integer
  +--------+--------+--------+--------+--------+
  |  0xce  |ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|
  +--------+--------+--------+--------+--------+
  """
  fun name(): String =>
    "msgpack/EncodeUint32"

  fun ref apply(h: TestHelper) ? =>
    let value: U32 = U32.max_value() - 1
    let b = Reader
    let w: Writer ref = Writer

    MessagePackEncoder.uint_32(w, value)

    for bs in w.done().values() do
      b.append(bs)
    end

    h.assert_eq[USize](5, b.size())
    h.assert_eq[U8](_FormatName.uint_32(), b.peek_u8()?)
    h.assert_eq[U32](value, b.peek_u32_be(1)?)

class \nodoc\ _TestEncodeUint64 is UnitTest
  """
  uint 64 stores a 64-bit big-endian unsigned integer
  +--------+--------+--------+--------+--------+--------+--------+--------+--------+
  |  0xcf  |ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|
  +--------+--------+--------+--------+--------+--------+--------+--------+--------+
  """
  fun name(): String =>
    "msgpack/EncodeUint64"

  fun ref apply(h: TestHelper) ? =>
    let value: U64 = U64.max_value() - 1
    let b = Reader
    let w: Writer ref = Writer

    MessagePackEncoder.uint_64(w, value)

    for bs in w.done().values() do
      b.append(bs)
    end

    h.assert_eq[USize](9, b.size())
    h.assert_eq[U8](_FormatName.uint_64(), b.peek_u8()?)
    h.assert_eq[U64](value, b.peek_u64_be(1)?)

class \nodoc\ _TestEncodeInt8 is UnitTest
  """
  int 8 stores a 8-bit signed integer
  +--------+--------+
  |  0xd0  |ZZZZZZZZ|
  +--------+--------+
  """
  fun name(): String =>
    "msgpack/EncodeInt8"

  fun ref apply(h: TestHelper) ? =>
    let value: I8 = I8.max_value() - 1
    let b = Reader
    let w: Writer ref = Writer

    MessagePackEncoder.int_8(w, value)

    for bs in w.done().values() do
      b.append(bs)
    end

    h.assert_eq[USize](2, b.size())
    h.assert_eq[U8](_FormatName.int_8(), b.peek_u8()?)
    h.assert_eq[I8](value, b.peek_i8(1)?)

class \nodoc\ _TestEncodeInt16 is UnitTest
  """
  int 16 stores a 16-bit big-endian signed integer
  +--------+--------+--------+
  |  0xd1  |ZZZZZZZZ|ZZZZZZZZ|
  +--------+--------+--------+
  """
  fun name(): String =>
    "msgpack/EncodeInt16"

  fun ref apply(h: TestHelper) ? =>
    let value: I16 = I16.max_value() - 1
    let b = Reader
    let w: Writer ref = Writer

    MessagePackEncoder.int_16(w, value)

    for bs in w.done().values() do
      b.append(bs)
    end

    h.assert_eq[USize](3, b.size())
    h.assert_eq[U8](_FormatName.int_16(), b.peek_u8()?)
    h.assert_eq[I16](value, b.peek_i16_be(1)?)

class \nodoc\ _TestEncodeInt32 is UnitTest
  """
  int 32 stores a 32-bit big-endian signed integer
  +--------+--------+--------+--------+--------+
  |  0xd2  |ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|
  +--------+--------+--------+--------+--------+
  """
  fun name(): String =>
    "msgpack/EncodeInt32"

  fun ref apply(h: TestHelper) ? =>
    let value: I32 = I32.max_value() - 1
    let b = Reader
    let w: Writer ref = Writer

    MessagePackEncoder.int_32(w, value)

    for bs in w.done().values() do
      b.append(bs)
    end

    h.assert_eq[USize](5, b.size())
    h.assert_eq[U8](_FormatName.int_32(), b.peek_u8()?)
    h.assert_eq[I32](value, b.peek_i32_be(1)?)

class \nodoc\ _TestEncodeInt64 is UnitTest
  """
  int 64 stores a 64-bit big-endian signed integer
  +--------+--------+--------+--------+--------+--------+--------+--------+--------+
  |  0xd3  |ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|
  +--------+--------+--------+--------+--------+--------+--------+--------+--------+
  """
  fun name(): String =>
    "msgpack/EncodeInt64"

  fun ref apply(h: TestHelper) ? =>
    let value: I64 = I64.max_value() - 1
    let b = Reader
    let w: Writer ref = Writer

    MessagePackEncoder.int_64(w, value)

    for bs in w.done().values() do
      b.append(bs)
    end

    h.assert_eq[USize](9, b.size())
    h.assert_eq[U8](_FormatName.int_64(), b.peek_u8()?)
    h.assert_eq[I64](value, b.peek_i64_be(1)?)

class \nodoc\ _TestEncodeFloat32 is UnitTest
  """
  float 32 stores a floating point number in IEEE 754 single precision
  floating point number format:
  +--------+--------+--------+--------+--------+
  |  0xca  |XXXXXXXX|XXXXXXXX|XXXXXXXX|XXXXXXXX|
  +--------+--------+--------+--------+--------+
  """
  fun name(): String =>
    "msgpack/EncodeFloat32"

  fun ref apply(h: TestHelper) ? =>
    let value: F32 = F32.max_value() - 1.5
    let b = Reader
    let w: Writer ref = Writer

    MessagePackEncoder.float_32(w, value)

    for bs in w.done().values() do
      b.append(bs)
    end

    h.assert_eq[USize](5, b.size())
    h.assert_eq[U8](_FormatName.float_32(), b.peek_u8()?)
    h.assert_eq[F32](value, b.peek_f32_be(1)?)

class \nodoc\ _TestEncodeFloat64 is UnitTest
  """
  float 64 stores a floating point number in IEEE 754 double precision
  floating point number format:
  +--------+--------+--------+--------+--------+--------+--------+--------+--------+
  |  0xcb  |YYYYYYYY|YYYYYYYY|YYYYYYYY|YYYYYYYY|YYYYYYYY|YYYYYYYY|YYYYYYYY|YYYYYYYY|
  +--------+--------+--------+--------+--------+--------+--------+--------+--------+
  """
  fun name(): String =>
    "msgpack/EncodeFloat64"

  fun ref apply(h: TestHelper) ? =>
    let value: F64 = F64.max_value() - 1.5
    let b = Reader
    let w: Writer ref = Writer

    MessagePackEncoder.float_64(w, value)

    for bs in w.done().values() do
      b.append(bs)
    end

    h.assert_eq[USize](9, b.size())
    h.assert_eq[U8](_FormatName.float_64(), b.peek_u8()?)
    h.assert_eq[F64](value, b.peek_f64_be(1)?)

class \nodoc\ _TestEncodeFixstr is UnitTest
  """
  fixstr stores a byte array whose length is upto 31 bytes:
  +--------+========+
  |101XXXXX|  data  |
  +--------+========+
  """
  fun name(): String =>
    "msgpack/EncodeFixstr"

  fun ref apply(h: TestHelper) ? =>
    let value = recover val [as U8: 'H'; 'e'; 'l'; 'l'; 'o'] end
    let b = Reader
    let w: Writer ref = Writer

    MessagePackEncoder.fixstr(w, value)?

    for bs in w.done().values() do
      b.append(bs)
    end

    h.assert_true(value.size() <= _Limit.fixstr())
    h.assert_eq[USize](6, b.size())
    h.assert_eq[U8](0xA5, b.peek_u8()?)
    h.assert_eq[U8]('H', b.peek_u8(1)?)
    h.assert_eq[U8]('e', b.peek_u8(2)?)
    h.assert_eq[U8]('l', b.peek_u8(3)?)
    h.assert_eq[U8]('l', b.peek_u8(4)?)
    h.assert_eq[U8]('o', b.peek_u8(5)?)

class \nodoc\ _TestEncodeFixstrTooLarge is UnitTest
  """
  Verify that `fixstr` throws an error if supplied with a value too large to
  encode within the available space.
  """
  fun name(): String =>
    "msgpack/EncodeFixstrTooLarge"

  fun ref apply(h: TestHelper) =>
    let size = _Limit.fixstr() + 1
    let value = recover val Array[U8].init('Z', size) end
    let w: Writer ref = Writer

    try
      MessagePackEncoder.fixstr(w, value)?
      h.fail()
    end

class \nodoc\ _TestEncodeStr8 is UnitTest
  """
  str 8 stores a byte array whose length is upto (2^8)-1 bytes:
  +--------+--------+========+
  |  0xd9  |YYYYYYYY|  data  |
  +--------+--------+========+
  """
  fun name(): String =>
    "msgpack/EncodeStr8"

  fun ref apply(h: TestHelper) ? =>
    let value = recover val [as U8: 'H'; 'e'; 'l'; 'l'; 'o'] end
    let b = Reader
    let w: Writer ref = Writer

    MessagePackEncoder.str_8(w, value)?

    for bs in w.done().values() do
      b.append(bs)
    end

    h.assert_true(value.size() <= U8.max_value().usize())
    h.assert_eq[USize](7, b.size())
    h.assert_eq[U8](_FormatName.str_8(), b.peek_u8()?)
    h.assert_eq[U8](value.size().u8(), b.peek_u8(1)?)
    h.assert_eq[U8]('H', b.peek_u8(2)?)
    h.assert_eq[U8]('e', b.peek_u8(3)?)
    h.assert_eq[U8]('l', b.peek_u8(4)?)
    h.assert_eq[U8]('l', b.peek_u8(5)?)
    h.assert_eq[U8]('o', b.peek_u8(6)?)

class \nodoc\ _TestEncodeStr8TooLarge is UnitTest
  """
  Verify that `str_8` and `bin_8` throw an error if supplied with a value
  too large to encode within the available space.
  """
  fun name(): String =>
    "msgpack/EncodeStr8TooLarge"

  fun ref apply(h: TestHelper) =>
    let size = U8.max_value().usize() + 1
    let value = recover val Array[U8].init('Z', size) end
    let w: Writer ref = Writer

    try
      MessagePackEncoder.str_8(w, value)?
      h.fail()
    end

class \nodoc\ _TestEncodeStr16 is UnitTest
  """
  str 16 stores a byte array whose length is upto (2^16)-1 bytes:
  +--------+--------+--------+========+
  |  0xda  |ZZZZZZZZ|ZZZZZZZZ|  data  |
  +--------+--------+--------+========+
  """
  fun name(): String =>
    "msgpack/EncodeStr16"

  fun ref apply(h: TestHelper) ? =>
    let value = recover val [as U8: 'H'; 'e'; 'l'; 'l'; 'o'] end
    let b = Reader
    let w: Writer ref = Writer

    MessagePackEncoder.str_16(w, value)?

    for bs in w.done().values() do
      b.append(bs)
    end

    h.assert_eq[USize](8, b.size())
    h.assert_eq[U8](_FormatName.str_16(), b.peek_u8()?)
    h.assert_eq[U16](value.size().u16(), b.peek_u16_be(1)?)
    h.assert_eq[U8]('H', b.peek_u8(3)?)
    h.assert_eq[U8]('e', b.peek_u8(4)?)
    h.assert_eq[U8]('l', b.peek_u8(5)?)
    h.assert_eq[U8]('l', b.peek_u8(6)?)
    h.assert_eq[U8]('o', b.peek_u8(7)?)

class \nodoc\ _TestEncodeStr16TooLarge is UnitTest
  """
  Verify that `str_16` and `bin_16` throw an error if supplied with a value
  too large to encode within the available space.
  """
  fun name(): String =>
    "msgpack/EncodeStr16TooLarge"

  fun ref apply(h: TestHelper) =>
    let size = U16.max_value().usize() + 1
    let value = recover val Array[U8].init('Z', size) end
    let w: Writer ref = Writer

    try
      MessagePackEncoder.str_16(w, value)?
      h.fail()
    end

class \nodoc\ _TestEncodeStr32 is UnitTest
  """
  str 32 stores a byte array whose length is upto (2^32)-1 bytes:
  +--------+--------+--------+--------+--------+========+
  |  0xdb  |AAAAAAAA|AAAAAAAA|AAAAAAAA|AAAAAAAA|  data  |
  +--------+--------+--------+--------+--------+========+
  """
  fun name(): String =>
    "msgpack/EncodeStr32"

  fun ref apply(h: TestHelper) ? =>
    let value = recover val [as U8: 'H'; 'e'; 'l'; 'l'; 'o'] end
    let b = Reader
    let w: Writer ref = Writer

    MessagePackEncoder.str_32(w, value)?

    for bs in w.done().values() do
      b.append(bs)
    end

    h.assert_eq[USize](10, b.size())
    h.assert_eq[U8](_FormatName.str_32(), b.peek_u8()?)
    h.assert_eq[U32](value.size().u32(), b.peek_u32_be(1)?)
    h.assert_eq[U8]('H', b.peek_u8(5)?)
    h.assert_eq[U8]('e', b.peek_u8(6)?)
    h.assert_eq[U8]('l', b.peek_u8(7)?)
    h.assert_eq[U8]('l', b.peek_u8(8)?)
    h.assert_eq[U8]('o', b.peek_u8(9)?)

class \nodoc\ _TestEncodeStr32TooLarge is UnitTest
  """
  Verify that `str_32` and `bin_32` throw an error if supplied with a value
  too large to encode within the available space.
  """
  fun name(): String =>
    "msgpack/EncodeStr32TooLarge"

  fun ref apply(h: TestHelper) =>
    let size = U32.max_value().usize() + 1
    let value = recover val Array[U8].init('Z', size) end
    let w: Writer ref = Writer

    try
      MessagePackEncoder.str_32(w, value)?
      h.fail()
    end

class \nodoc\ _TestEncodeBin8 is UnitTest
  """
  bin 8 stores a byte array whose length is upto (2^8)-1 bytes:
  +--------+--------+========+
  |  0xc4  |XXXXXXXX|  data  |
  +--------+--------+========+
  """
  fun name(): String =>
    "msgpack/EncodeBin8"

  fun ref apply(h: TestHelper) ? =>
    let value = recover val [as U8: 'H'; 'e'; 'l'; 'l'; 'o'] end
    let b = Reader
    let w: Writer ref = Writer

    MessagePackEncoder.bin_8(w, value)?

    for bs in w.done().values() do
      b.append(bs)
    end

    h.assert_true(value.size() <= U8.max_value().usize())
    h.assert_eq[USize](7, b.size())
    h.assert_eq[U8](_FormatName.bin_8(), b.peek_u8()?)
    h.assert_eq[U8](value.size().u8(), b.peek_u8(1)?)
    h.assert_eq[U8]('H', b.peek_u8(2)?)
    h.assert_eq[U8]('e', b.peek_u8(3)?)
    h.assert_eq[U8]('l', b.peek_u8(4)?)
    h.assert_eq[U8]('l', b.peek_u8(5)?)
    h.assert_eq[U8]('o', b.peek_u8(6)?)

class \nodoc\ _TestEncodeBin16 is UnitTest
  """
  bin 16 stores a byte array whose length is upto (2^16)-1 bytes:
  +--------+--------+--------+========+
  |  0xc5  |YYYYYYYY|YYYYYYYY|  data  |
  +--------+--------+--------+========+
  """
  fun name(): String =>
    "msgpack/EncodeBin16"

  fun ref apply(h: TestHelper) ? =>
    let value = recover val [as U8: 'H'; 'e'; 'l'; 'l'; 'o'] end
    let b = Reader
    let w: Writer ref = Writer

    MessagePackEncoder.bin_16(w, value)?

    for bs in w.done().values() do
      b.append(bs)
    end

    h.assert_eq[USize](8, b.size())
    h.assert_eq[U8](_FormatName.bin_16(), b.peek_u8()?)
    h.assert_eq[U16](value.size().u16(), b.peek_u16_be(1)?)
    h.assert_eq[U8]('H', b.peek_u8(3)?)
    h.assert_eq[U8]('e', b.peek_u8(4)?)
    h.assert_eq[U8]('l', b.peek_u8(5)?)
    h.assert_eq[U8]('l', b.peek_u8(6)?)
    h.assert_eq[U8]('o', b.peek_u8(7)?)

class \nodoc\ _TestEncodeBin32 is UnitTest
  """
  bin 32 stores a byte array whose length is upto (2^32)-1 bytes:
  +--------+--------+--------+--------+--------+========+
  |  0xc6  |ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|  data  |
  +--------+--------+--------+--------+--------+========+
  """
  fun name(): String =>
    "msgpack/EncodeBin32"

  fun ref apply(h: TestHelper) ? =>
    let value = recover val [as U8: 'H'; 'e'; 'l'; 'l'; 'o'] end
    let b = Reader
    let w: Writer ref = Writer

    MessagePackEncoder.bin_32(w, value)?

    for bs in w.done().values() do
      b.append(bs)
    end

    h.assert_eq[USize](10, b.size())
    h.assert_eq[U8](_FormatName.bin_32(), b.peek_u8()?)
    h.assert_eq[U32](value.size().u32(), b.peek_u32_be(1)?)
    h.assert_eq[U8]('H', b.peek_u8(5)?)
    h.assert_eq[U8]('e', b.peek_u8(6)?)
    h.assert_eq[U8]('l', b.peek_u8(7)?)
    h.assert_eq[U8]('l', b.peek_u8(8)?)
    h.assert_eq[U8]('o', b.peek_u8(9)?)

class \nodoc\ _TestEncodeFixarray is UnitTest
  """
  fixarray stores an array whose length is upto 15 elements:
  +--------+~~~~~~~~~~~~~~~~~+
  |1001XXXX|    N objects    |
  +--------+~~~~~~~~~~~~~~~~~+

  This test is only verifying the header creation. Not the writing of
  "N objects".
  """
  fun name(): String =>
    "msgpack/EncodeFixarray"

  fun ref apply(h: TestHelper) ? =>
    let value = recover val [as U8: 'H'; 'e'; 'l'; 'l'; 'o'] end
    let b = Reader
    let w: Writer ref = Writer

    h.assert_true(value.size().u8() <= _Limit.fixarray())

    MessagePackEncoder.fixarray(w, value.size().u8())?

    for bs in w.done().values() do
      b.append(bs)
    end

    h.assert_eq[USize](1, b.size())
    h.assert_eq[U8](0x95, b.peek_u8()?)

class \nodoc\ _TestEncodeFixarrayTooLarge is UnitTest
  """
  Verify that `fixarray` throws an error if supplied with a value too large to
  encode within the available space.
  """
  fun name(): String =>
    "msgpack/EncodeFixarrayTooLarge"

  fun ref apply(h: TestHelper) =>
    let size = _Limit.fixarray() + 1
    let w: Writer ref = Writer

    try
      MessagePackEncoder.fixarray(w, size)?
      h.fail()
    end

class \nodoc\ _TestEncodeArray16 is UnitTest
  """
  array 16 stores an array whose length is upto (2^16)-1 elements:
  +--------+--------+--------+~~~~~~~~~~~~~~~~~+
  |  0xdc  |YYYYYYYY|YYYYYYYY|    N objects    |
  +--------+--------+--------+~~~~~~~~~~~~~~~~~+

  This test is only verifying the header creation. Not the writing of
  "N objects".
  """
  fun name(): String =>
    "msgpack/EncodeArray16"

  fun ref apply(h: TestHelper) ? =>
    let value = recover val [as U8: 'H'; 'e'; 'l'; 'l'; 'o'] end
    let b = Reader
    let w: Writer ref = Writer

    MessagePackEncoder.array_16(w, value.size().u16())

    for bs in w.done().values() do
      b.append(bs)
    end

    h.assert_eq[USize](3, b.size())
    h.assert_eq[U8](_FormatName.array_16(), b.peek_u8()?)
    h.assert_eq[U16](value.size().u16(), b.peek_u16_be(1)?)

class \nodoc\ _TestEncodeArray32 is UnitTest
  """
  array 32 stores an array whose length is upto (2^32)-1 elements:
  +--------+--------+--------+--------+--------+~~~~~~~~~~~~~~~~~+
  |  0xdd  |ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|    N objects    |
  +--------+--------+--------+--------+--------+~~~~~~~~~~~~~~~~~+

  This test is only verifying the header creation. Not the writing of
  "N objects".
  """
  fun name(): String =>
    "msgpack/EncodeArray32"

  fun ref apply(h: TestHelper) ? =>
    let value = recover val [as U8: 'H'; 'e'; 'l'; 'l'; 'o'] end
    let b = Reader
    let w: Writer ref = Writer

    MessagePackEncoder.array_32(w, value.size().u32())

    for bs in w.done().values() do
      b.append(bs)
    end

    h.assert_eq[USize](5, b.size())
    h.assert_eq[U8](_FormatName.array_32(), b.peek_u8()?)
    h.assert_eq[U32](value.size().u32(), b.peek_u32_be(1)?)

class \nodoc\ _TestEncodeFixmap is UnitTest
  """
  fixmap stores a map whose length is upto 15 elements
  +--------+~~~~~~~~~~~~~~~~~+
  |1000XXXX|   N*2 objects   |
  +--------+~~~~~~~~~~~~~~~~~+

  This test is only verifying the header creation. Not the writing of
  "N*2 objects".
  """
  fun name(): String =>
    "msgpack/EncodeFixmap"

  fun ref apply(h: TestHelper) ? =>
    let size = _Limit.fixmap() - 1
    let b = Reader
    let w: Writer ref = Writer

    MessagePackEncoder.fixmap(w, size)?

    for bs in w.done().values() do
      b.append(bs)
    end

    h.assert_eq[USize](1, b.size())
    h.assert_eq[U8](0x8E, b.peek_u8()?)

class \nodoc\ _TestEncodeFixmapTooLarge is UnitTest
  """
  Verify that `fixmap` throws an error if supplied with a value too large to
  encode within the available space.
  """
  fun name(): String =>
    "msgpack/EncodeFixmapTooLarge"

  fun ref apply(h: TestHelper) =>
    let size = _Limit.fixmap() + 1
    let w: Writer ref = Writer

    try
      MessagePackEncoder.fixmap(w, size)?
      h.fail()
    end

class \nodoc\ _TestEncodeMap16 is UnitTest
  """
  map 16 stores a map whose length is upto (2^16)-1 elements
  +--------+--------+--------+~~~~~~~~~~~~~~~~~+
  |  0xde  |YYYYYYYY|YYYYYYYY|   N*2 objects   |
  +--------+--------+--------+~~~~~~~~~~~~~~~~~+

  This test is only verifying the header creation. Not the writing of
  "N*2 objects".
  """
  fun name(): String =>
    "msgpack/EncodeMap16"

  fun ref apply(h: TestHelper) ? =>
    let size: U16 = 42
    let b = Reader
    let w: Writer ref = Writer

    MessagePackEncoder.map_16(w, size)

    for bs in w.done().values() do
      b.append(bs)
    end

    h.assert_eq[USize](3, b.size())
    h.assert_eq[U8](_FormatName.map_16(), b.peek_u8()?)
    h.assert_eq[U16](size, b.peek_u16_be(1)?)

class \nodoc\ _TestEncodeMap32 is UnitTest
  """
  map 32 stores a map whose length is upto (2^32)-1 elements
  +--------+--------+--------+--------+--------+~~~~~~~~~~~~~~~~~+
  |  0xdf  |ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|   N*2 objects   |
  +--------+--------+--------+--------+--------+~~~~~~~~~~~~~~~~~+

  This test is only verifying the header creation. Not the writing of
  "N*2 objects".
  """
  fun name(): String =>
    "msgpack/EncodeMap32"

  fun ref apply(h: TestHelper) ? =>
    let size: U32 = 1492
    let b = Reader
    let w: Writer ref = Writer

    MessagePackEncoder.map_32(w, size)

    for bs in w.done().values() do
      b.append(bs)
    end

    h.assert_eq[USize](5, b.size())
    h.assert_eq[U8](_FormatName.map_32(), b.peek_u8()?)
    h.assert_eq[U32](size, b.peek_u32_be(1)?)

class \nodoc\ _TestEncodeFixext1 is UnitTest
  """
  fixext 1 stores an integer and a byte array whose length is 1 byte
  +--------+--------+--------+
  |  0xd4  |  type  |  data  |
  +--------+--------+--------+
  """
  fun name(): String =>
    "msgpack/EncodeFixext1"

  fun ref apply(h: TestHelper) ? =>
    let size = _Size.fixext_1()
    let user_type: U8 = 8
    let value = recover val Array[U8].init('V', size) end
    let b = Reader
    let w: Writer ref = Writer

    MessagePackEncoder.fixext_1(w, user_type, value)?

    for bs in w.done().values() do
      b.append(bs)
    end

    h.assert_eq[USize](2 + size, b.size())
    h.assert_eq[U8](0xD4, b.peek_u8()?)
    h.assert_eq[U8](user_type, b.peek_u8(1)?)
    h.assert_eq[U8]('V', b.peek_u8(2)?)

class \nodoc\ _TestEncodeFixext1IncorrectSize is UnitTest
  """
  Verify that `fixext_1` throws an error if supplied with a value either
  too large or too small to encode within the available space.

  This would be ideal for a property based test rather than the standard
  unit test it currently is.
  """
  fun name(): String =>
    "msgpack/EncodeFixext1IncorrectSize"

  fun ref apply(h: TestHelper) =>
    let w: Writer ref = Writer
    let user_type: U8 = 8
    let too_big = recover val Array[U8].init('Z', _Size.fixext_1() + 1) end
    let too_small = recover val Array[U8].init('a', _Size.fixext_1() - 1) end

    try
      MessagePackEncoder.fixext_1(w, user_type, too_big)?
      h.fail()
    end

    try
      MessagePackEncoder.fixext_1(w, user_type, too_small)?
      h.fail()
    end

class \nodoc\ _TestEncodeFixext2 is UnitTest
  """
  fixext 2 stores an integer and a byte array whose length is 2 bytes
  +--------+--------+--------+
  |  0xd5  |  type  |  data  |
  +--------+--------+--------+
  """
  fun name(): String =>
    "msgpack/EncodeFixext2"

  fun ref apply(h: TestHelper) ? =>
    let size = _Size.fixext_2()
    let user_type: U8 = 8
    let value = recover val Array[U8].init('V', size) end
    let b = Reader
    let w: Writer ref = Writer

    MessagePackEncoder.fixext_2(w, user_type, value)?

    for bs in w.done().values() do
      b.append(bs)
    end

    h.assert_eq[USize](2 + size, b.size())
    h.assert_eq[U8](0xD5, b.peek_u8()?)
    h.assert_eq[U8](user_type, b.peek_u8(1)?)
    for i in Range(2, (2 + size)) do
      h.assert_eq[U8]('V', b.peek_u8(i)?)
    end

class \nodoc\ _TestEncodeFixext2IncorrectSize is UnitTest
  """
  Verify that `fixext_2` throws an error if supplied with a value either
  too large or too small to encode within the available space.

  This would be ideal for a property based test rather than the standard
  unit test it currently is.
  """
  fun name(): String =>
    "msgpack/EncodeFixext2IncorrectSize"

  fun ref apply(h: TestHelper) =>
    let w: Writer ref = Writer
    let user_type: U8 = 8
    let too_big = recover val Array[U8].init('Z', _Size.fixext_2() + 1) end
    let too_small = recover val Array[U8].init('a', _Size.fixext_2() - 1) end

    try
      MessagePackEncoder.fixext_2(w, user_type, too_big)?
      h.fail()
    end

    try
      MessagePackEncoder.fixext_2(w, user_type, too_small)?
      h.fail()
    end

class \nodoc\ _TestEncodeFixext4 is UnitTest
  """
  fixext 4 stores an integer and a byte array whose length is 4 bytes
  +--------+--------+--------+
  |  0xd6  |  type  |  data  |
  +--------+--------+--------+
  """
  fun name(): String =>
    "msgpack/EncodeFixext4"

  fun ref apply(h: TestHelper) ? =>
    let size = _Size.fixext_4()
    let user_type: U8 = 8
    let value = recover val Array[U8].init('V', size) end
    let b = Reader
    let w: Writer ref = Writer

    MessagePackEncoder.fixext_4(w, user_type, value)?

    for bs in w.done().values() do
      b.append(bs)
    end

    h.assert_eq[USize](2 + size, b.size())
    h.assert_eq[U8](0xD6, b.peek_u8()?)
    h.assert_eq[U8](user_type, b.peek_u8(1)?)
    for i in Range(2, (2 + size)) do
      h.assert_eq[U8]('V', b.peek_u8(i)?)
    end

class \nodoc\ _TestEncodeFixext4IncorrectSize is UnitTest
  """
  Verify that `fixext_4` throws an error if supplied with a value either
  too large or too small to encode within the available space.

  This would be ideal for a property based test rather than the standard
  unit test it currently is.
  """
  fun name(): String =>
    "msgpack/EncodeFixext4IncorrectSize"

  fun ref apply(h: TestHelper) =>
    let w: Writer ref = Writer
    let user_type: U8 = 8
    let too_big = recover val Array[U8].init('Z', _Size.fixext_4() + 1) end
    let too_small = recover val Array[U8].init('a', _Size.fixext_4() - 1) end

    try
      MessagePackEncoder.fixext_4(w, user_type, too_big)?
      h.fail()
    end

    try
      MessagePackEncoder.fixext_4(w, user_type, too_small)?
      h.fail()
    end

class \nodoc\ _TestEncodeFixext8 is UnitTest
  """
  fixext 8 stores an integer and a byte array whose length is 8 bytes
  +--------+--------+--------+
  |  0xd7  |  type  |  data  |
  +--------+--------+--------+
  """
  fun name(): String =>
    "msgpack/EncodeFixext8"

  fun ref apply(h: TestHelper) ? =>
    let size = _Size.fixext_8()
    let user_type: U8 = 8
    let value = recover val Array[U8].init('V', size) end
    let b = Reader
    let w: Writer ref = Writer

    MessagePackEncoder.fixext_8(w, user_type, value)?

    for bs in w.done().values() do
      b.append(bs)
    end

    h.assert_eq[USize](2 + size, b.size())
    h.assert_eq[U8](0xD7, b.peek_u8()?)
    h.assert_eq[U8](user_type, b.peek_u8(1)?)
    for i in Range(2, (2 + size)) do
      h.assert_eq[U8]('V', b.peek_u8(i)?)
    end

class \nodoc\ _TestEncodeFixext8IncorrectSize is UnitTest
  """
  Verify that `fixext_8` throws an error if supplied with a value either
  too large or too small to encode within the available space.

  This would be ideal for a property based test rather than the standard
  unit test it currently is.
  """
  fun name(): String =>
    "msgpack/EncodeFixext8IncorrectSize"

  fun ref apply(h: TestHelper) =>
    let w: Writer ref = Writer
    let user_type: U8 = 8
    let too_big = recover val Array[U8].init('Z', _Size.fixext_8() + 1) end
    let too_small = recover val Array[U8].init('a', _Size.fixext_8() - 1) end

    try
      MessagePackEncoder.fixext_8(w, user_type, too_big)?
      h.fail()
    end

    try
      MessagePackEncoder.fixext_8(w, user_type, too_small)?
      h.fail()
    end

class \nodoc\ _TestEncodeFixext16 is UnitTest
  """
  fixext 16 stores an integer and a byte array whose length is 16 bytes
  +--------+--------+--------+
  |  0xd8  |  type  |  data  |
  +--------+--------+--------+
  """
  fun name(): String =>
    "msgpack/EncodeFixext16"

  fun ref apply(h: TestHelper) ? =>
    let size = _Size.fixext_16()
    let user_type: U8 = 8
    let value = recover val Array[U8].init('V', size) end
    let b = Reader
    let w: Writer ref = Writer

    MessagePackEncoder.fixext_16(w, user_type, value)?

    for bs in w.done().values() do
      b.append(bs)
    end

    h.assert_eq[USize](2 + size, b.size())
    h.assert_eq[U8](0xD8, b.peek_u8()?)
    h.assert_eq[U8](user_type, b.peek_u8(1)?)
    for i in Range(2, (2 + size)) do
      h.assert_eq[U8]('V', b.peek_u8(i)?)
    end

class \nodoc\ _TestEncodeFixext16IncorrectSize is UnitTest
  """
  Verify that `fixext_16` throws an error if supplied with a value either
  too large or too small to encode within the available space.

  This would be ideal for a property based test rather than the standard
  unit test it currently is.
  """
  fun name(): String =>
    "msgpack/EncodeFixext16IncorrectSize"

  fun ref apply(h: TestHelper) =>
    let w: Writer ref = Writer
    let user_type: U8 = 8
    let too_big = recover val Array[U8].init('Z', _Size.fixext_16() + 1) end
    let too_small = recover val Array[U8].init('a', _Size.fixext_16() - 1) end

    try
      MessagePackEncoder.fixext_16(w, user_type, too_big)?
      h.fail()
    end

    try
      MessagePackEncoder.fixext_16(w, user_type, too_small)?
      h.fail()
    end

class \nodoc\ _TestEncodeExt8 is UnitTest
  """
  ext 8 stores an integer and a byte array whose length is upto (2^8)-1 bytes:
  +--------+--------+--------+========+
  |  0xc7  |XXXXXXXX|  type  |  data  |
  +--------+--------+--------+========+
  """
  fun name(): String =>
    "msgpack/EncodeExt8"

  fun ref apply(h: TestHelper) ? =>
    let value = recover val [as U8: 'H'; 'e'; 'l'; 'l'; 'o'] end
    let ext_type: U8 = 99
    let b = Reader
    let w: Writer ref = Writer

    MessagePackEncoder.ext_8(w, ext_type, value)?

    for bs in w.done().values() do
      b.append(bs)
    end

    h.assert_true(value.size() <= U8.max_value().usize())
    h.assert_eq[USize](8, b.size())
    h.assert_eq[U8](_FormatName.ext_8(), b.peek_u8()?)
    h.assert_eq[U8](value.size().u8(), b.peek_u8(1)?)
    h.assert_eq[U8](ext_type, b.peek_u8(2)?)
    h.assert_eq[U8]('H', b.peek_u8(3)?)
    h.assert_eq[U8]('e', b.peek_u8(4)?)
    h.assert_eq[U8]('l', b.peek_u8(5)?)
    h.assert_eq[U8]('l', b.peek_u8(6)?)
    h.assert_eq[U8]('o', b.peek_u8(7)?)

class \nodoc\ _TestEncodeExt8TooLarge is UnitTest
  """
  Verify that `ext_8` throws an error if supplied with a value
  too large to encode within the available space.
  """
  fun name(): String =>
    "msgpack/EncodeExt8TooLarge"

  fun ref apply(h: TestHelper) =>
    let size = U8.max_value().usize() + 1
    let value = recover val Array[U8].init('Z', size) end
    let ext_type: U8 = 99
    let w: Writer ref = Writer

    try
      MessagePackEncoder.ext_8(w, ext_type, value)?
      h.fail()
    end

class \nodoc\ _TestEncodeExt16 is UnitTest
  """
  ext 16 stores an integer and a byte array whose length is
  upto (2^16)-1 bytes:
  +--------+--------+--------+--------+========+
  |  0xc8  |YYYYYYYY|YYYYYYYY|  type  |  data  |
  +--------+--------+--------+--------+========+
  """
  fun name(): String =>
    "msgpack/EncodeExt16"

  fun ref apply(h: TestHelper) ? =>
    let value = recover val [as U8: 'H'; 'e'; 'l'; 'l'; 'o'] end
    let ext_type: U8 = 99
    let b = Reader
    let w: Writer ref = Writer

    MessagePackEncoder.ext_16(w, ext_type, value)?

    for bs in w.done().values() do
      b.append(bs)
    end

    h.assert_true(value.size() <= U8.max_value().usize())
    h.assert_eq[USize](9, b.size())
    h.assert_eq[U8](_FormatName.ext_16(), b.peek_u8()?)
    h.assert_eq[U16](value.size().u16(), b.peek_u16_be(1)?)
    h.assert_eq[U8](ext_type, b.peek_u8(3)?)
    h.assert_eq[U8]('H', b.peek_u8(4)?)
    h.assert_eq[U8]('e', b.peek_u8(5)?)
    h.assert_eq[U8]('l', b.peek_u8(6)?)
    h.assert_eq[U8]('l', b.peek_u8(7)?)
    h.assert_eq[U8]('o', b.peek_u8(8)?)

class \nodoc\ _TestEncodeExt16TooLarge is UnitTest
  """
  Verify that `ext_16` throws an error if supplied with a value
  too large to encode within the available space.
  """
  fun name(): String =>
    "msgpack/EncodeExt16TooLarge"

  fun ref apply(h: TestHelper) =>
    let size = U16.max_value().usize() + 1
    let value = recover val Array[U8].init('Z', size) end
    let ext_type: U8 = 99
    let w: Writer ref = Writer

    try
      MessagePackEncoder.ext_16(w, ext_type, value)?
      h.fail()
    end

class \nodoc\ _TestEncodeExt32 is UnitTest
  """
  ext 32 stores an integer and a byte array whose length is
  upto (2^32)-1 bytes:
  +--------+--------+--------+--------+--------+--------+========+
  |  0xc9  |ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|  type  |  data  |
  +--------+--------+--------+--------+--------+--------+========+
  """
  fun name(): String =>
    "msgpack/EncodeExt32"

  fun ref apply(h: TestHelper) ? =>
    let value = recover val [as U8: 'H'; 'e'; 'l'; 'l'; 'o'] end
    let ext_type: U8 = 99
    let b = Reader
    let w: Writer ref = Writer

    MessagePackEncoder.ext_32(w, ext_type, value)?

    for bs in w.done().values() do
      b.append(bs)
    end

    h.assert_true(value.size() <= U8.max_value().usize())
    h.assert_eq[USize](11, b.size())
    h.assert_eq[U8](_FormatName.ext_32(), b.peek_u8()?)
    h.assert_eq[U32](value.size().u32(), b.peek_u32_be(1)?)
    h.assert_eq[U8](ext_type, b.peek_u8(5)?)
    h.assert_eq[U8]('H', b.peek_u8(6)?)
    h.assert_eq[U8]('e', b.peek_u8(7)?)
    h.assert_eq[U8]('l', b.peek_u8(8)?)
    h.assert_eq[U8]('l', b.peek_u8(9)?)
    h.assert_eq[U8]('o', b.peek_u8(10)?)

class \nodoc\ _TestEncodeExt32TooLarge is UnitTest
  """
  Verify that `ext_16` throws an error if supplied with a value
  too large to encode within the available space.
  """
  fun name(): String =>
    "msgpack/EncodeExt32TooLarge"

  fun ref apply(h: TestHelper) =>
    let size = U32.max_value().usize() + 1
    let value = recover val Array[U8].init('Z', size) end
    let ext_type: U8 = 99
    let w: Writer ref = Writer

    try
      MessagePackEncoder.ext_32(w, ext_type, value)?
      h.fail()
    end

class \nodoc\ _TestEncodeTimestamp32 is UnitTest
  """
  timestamp 32 stores the number of seconds that have elapsed since 1970-01-01
  00:00:00 UTC in an 32-bit unsigned integer:
  +--------+--------+--------+--------+--------+--------+
  |  0xd6  |   -1   |   seconds in 32-bit unsigned int  |
  +--------+--------+--------+--------+--------+--------+
  """
  fun name(): String =>
    "msgpack/EncodeTimestamp32"

  fun ref apply(h: TestHelper) ? =>
    let size = _Size.fixext_4()
    let secs: U32 = 500
    let b = Reader
    let w: Writer ref = Writer

    MessagePackEncoder.timestamp_32(w, secs)

    for bs in w.done().values() do
      b.append(bs)
    end

    h.assert_eq[USize](2 + size, b.size())
    h.assert_eq[U8](0xD6, b.u8()?)
    h.assert_eq[I8](-1, b.i8()?)
    h.assert_eq[U32](secs, b.u32_be()?)

class \nodoc\ _TestEncodeTimestamp64 is UnitTest
  """
  timestamp 64 stores the number of seconds and nanoseconds that have elapsed
  since 1970-01-01 00:00:00 UTC in 32-bit unsigned integers:
  +--------+--------+--------+--------+--------+--------+
  |  0xd7  |   -1   |nanoseconds in 30-bit unsigned int |
  +--------+--------+--------+--------+--------+--------+
  +--------+--------+--------+--------+
     seconds in 34-bit unsigned int   |
  +--------+--------+--------+--------+
  """
  fun name(): String =>
    "msgpack/EncodeTimestamp64"

  fun ref apply(h: TestHelper) ? =>
    let size = _Size.fixext_8()
    let secs: U64 = 500
    let nsecs: U32 = 600
    let expect: U64 = (nsecs.u64() << 34) + secs
    let b = Reader
    let w: Writer ref = Writer

    MessagePackEncoder.timestamp_64(w, secs, nsecs)?

    for bs in w.done().values() do
      b.append(bs)
    end

    h.assert_eq[USize](2 + size, b.size())
    h.assert_eq[U8](0xD7, b.u8()?)
    h.assert_eq[I8](-1, b.i8()?)
    h.assert_eq[U64](expect, b.u64_be()?)

class \nodoc\ _TestEncodeTimestamp64SecsTooLarge is UnitTest
  """
  Verify that `timestamp_64` throws an error if supplied a seconds value larger
  than what can fit within 34 bits.
  """
  fun name(): String =>
    "msgpack/EncodeTimestamp64SecsTooLarge"

  fun ref apply(h: TestHelper) =>
    let w: Writer ref = Writer

    try
      MessagePackEncoder.timestamp_64(w, (_Limit.sec_34().u64() + 1), 0)?
      h.fail()
    end

class \nodoc\ _TestEncodeTimestamp64NsecsTooLarge is UnitTest
  """
  Verify that `timestamp_64` throws an error if supplied a nanoseconds value
  larger than 99999999.
  """
  fun name(): String =>
    "msgpack/EncodeTimestamp64NsecsTooLarge"

  fun ref apply(h: TestHelper) =>
    let w: Writer ref = Writer

    try
      MessagePackEncoder.timestamp_64(w, 0, (_Limit.nsec() + 1))?
      h.fail()
    end

class \nodoc\ _TestEncodeTimestamp96 is UnitTest
  """
  timestamp 96 stores the number of seconds and nanoseconds that have elapsed
  since 1970-01-01 00:00:00 UTC in 64-bit signed integer and 32-bit unsigned
  integer:
  +--------+--------+--------+--------+--------+--------+--------+
  |  0xc7  |   12   |   -1   |nanoseconds in 32-bit unsigned int |
  +--------+--------+--------+--------+--------+--------+--------+
  +--------+--------+--------+--------+--------+--------+--------+--------+
                      seconds in 64-bit signed int                        |
  +--------+--------+--------+--------+--------+--------+--------+--------+
  """
  fun name(): String =>
    "msgpack/EncodeTimestamp96"

  fun ref apply(h: TestHelper) ? =>
    let size: USize = 12
    let secs: I64 = 500
    let nsecs: U32 = 600
    let b = Reader
    let w: Writer ref = Writer

    MessagePackEncoder.timestamp_96(w, secs, nsecs)?

    for bs in w.done().values() do
      b.append(bs)
    end

    h.assert_eq[USize](3 + size, b.size())
    h.assert_eq[U8](0xC7, b.u8()?)
    h.assert_eq[U8](12, b.u8()?)
    h.assert_eq[I8](-1, b.i8()?)
    h.assert_eq[U32](nsecs, b.u32_be()?)
    h.assert_eq[I64](secs, b.i64_be()?)

class \nodoc\ _TestEncodeTimestamp96NsecsTooLarge is UnitTest
  """
  Verify that `timestamp_96` throws an error if supplied a nanoseconds value larger
  than 99999999.
  """
  fun name(): String =>
    "msgpack/EncodeTimestamp96NsecsTooLarge"

  fun ref apply(h: TestHelper) =>
    let w: Writer ref = Writer

    try
      MessagePackEncoder.timestamp_96(w, 0, (_Limit.nsec() + 1))?
      h.fail()
    end

class \nodoc\ _TestEncodeCompactUint is UnitTest
  """
  Verify that compact uint selects the smallest format at each
  boundary.
  """
  fun name(): String =>
    "msgpack/EncodeCompactUint"

  fun ref apply(h: TestHelper) ? =>
    _check(h, 0, 1, 0x00)?                      // fixint
    _check(h, 127, 1, 127)?                      // fixint max
    _check(h, 128, 2, _FormatName.uint_8())?     // uint_8 min
    _check(h, 255, 2, _FormatName.uint_8())?     // uint_8 max
    _check(h, 256, 3, _FormatName.uint_16())?    // uint_16 min
    _check(h, 65535, 3, _FormatName.uint_16())?  // uint_16 max
    _check(h, 65536, 5, _FormatName.uint_32())?  // uint_32 min
    _check(h, U32.max_value().u64(), 5,
      _FormatName.uint_32())?                    // uint_32 max
    _check(h, U32.max_value().u64() + 1, 9,
      _FormatName.uint_64())?                    // uint_64 min
    _check(h, U64.max_value(), 9,
      _FormatName.uint_64())?                    // uint_64 max

  fun _check(
    h: TestHelper,
    v: U64,
    expected_size: USize,
    expected_format: U8)
    ?
  =>
    let w: Writer ref = Writer
    let b = Reader

    MessagePackEncoder.uint(w, v)

    for bs in w.done().values() do
      b.append(bs)
    end

    h.assert_eq[USize](expected_size, b.size(),
      "size for " + v.string())
    h.assert_eq[U8](expected_format, b.peek_u8()?,
      "format for " + v.string())

class \nodoc\ _TestEncodeCompactInt is UnitTest
  """
  Verify that compact int selects the smallest format at each
  boundary. Positive values use unsigned formats.
  """
  fun name(): String =>
    "msgpack/EncodeCompactInt"

  fun ref apply(h: TestHelper) ? =>
    // positive fixint
    _check(h, 0, 1, 0x00)?
    _check(h, 127, 1, 127)?
    // negative fixint
    _check(h, -1, 1, 0xFF)?
    _check(h, -32, 1, 0xE0)?
    // uint_8
    _check(h, 128, 2, _FormatName.uint_8())?
    // int_8
    _check(h, -33, 2, _FormatName.int_8())?
    _check(h, -128, 2, _FormatName.int_8())?
    // uint_16
    _check(h, 256, 3, _FormatName.uint_16())?
    // int_16
    _check(h, -129, 3, _FormatName.int_16())?
    _check(h, -32768, 3, _FormatName.int_16())?
    // uint_32
    _check(h, 65536, 5, _FormatName.uint_32())?
    // int_32
    _check(h, -32769, 5, _FormatName.int_32())?
    // uint_64
    _check(h, U32.max_value().i64() + 1, 9,
      _FormatName.uint_64())?
    // int_64
    _check(h, I64.min_value(), 9,
      _FormatName.int_64())?

  fun _check(
    h: TestHelper,
    v: I64,
    expected_size: USize,
    expected_format: U8)
    ?
  =>
    let w: Writer ref = Writer
    let b = Reader

    MessagePackEncoder.int(w, v)

    for bs in w.done().values() do
      b.append(bs)
    end

    h.assert_eq[USize](expected_size, b.size(),
      "size for " + v.string())
    h.assert_eq[U8](expected_format, b.peek_u8()?,
      "format for " + v.string())

class \nodoc\ _TestEncodeCompactStr is UnitTest
  """
  Verify that compact str selects the correct format by size.
  """
  fun name(): String =>
    "msgpack/EncodeCompactStr"

  fun ref apply(h: TestHelper) ? =>
    // fixstr boundaries
    let empty = recover val Array[U8] end
    _check(h, empty, 1, 0xA0)?                  // 0: fixstr
    let fix5 = recover val
      Array[U8].init('A', 5)
    end
    _check(h, fix5, 6, 0xA5)?                   // 5: fixstr
    let fix31 = recover val
      Array[U8].init('A', 31)
    end
    _check(h, fix31, 32, 0xBF)?                  // 31: fixstr max

    // str_8 boundaries
    let s8_32 = recover val
      Array[U8].init('B', 32)
    end
    _check(h, s8_32, 34, _FormatName.str_8())?   // 32: str_8 min
    let s8_255 = recover val
      Array[U8].init('B', 255)
    end
    _check(h, s8_255, 257, _FormatName.str_8())? // 255: str_8 max

    // str_16 boundary
    let s16_256 = recover val
      Array[U8].init('C', 256)
    end
    _check(h, s16_256, 259, _FormatName.str_16())? // 256: str_16 min

  fun _check(
    h: TestHelper,
    v: ByteSeq,
    expected_size: USize,
    expected_format: U8)
    ?
  =>
    let w: Writer ref = Writer
    let b = Reader

    MessagePackEncoder.str(w, v)?

    for bs in w.done().values() do
      b.append(bs)
    end

    h.assert_eq[USize](expected_size, b.size(),
      "size for len=" + v.size().string())
    h.assert_eq[U8](expected_format, b.peek_u8()?,
      "format for len=" + v.size().string())

class \nodoc\ _TestEncodeCompactBin is UnitTest
  """
  Verify that compact bin selects the correct format by size.
  """
  fun name(): String =>
    "msgpack/EncodeCompactBin"

  fun ref apply(h: TestHelper) ? =>
    // bin_8 boundaries
    let empty = recover val Array[U8] end
    _check(h, empty, 2, _FormatName.bin_8())?     // 0: bin_8 min
    let b8_5 = recover val
      Array[U8].init('A', 5)
    end
    _check(h, b8_5, 7, _FormatName.bin_8())?      // 5: bin_8
    let b8_255 = recover val
      Array[U8].init('A', 255)
    end
    _check(h, b8_255, 257, _FormatName.bin_8())?  // 255: bin_8 max

    // bin_16 boundary
    let b16_256 = recover val
      Array[U8].init('B', 256)
    end
    _check(h, b16_256, 259, _FormatName.bin_16())? // 256: bin_16 min

  fun _check(
    h: TestHelper,
    v: ByteSeq,
    expected_size: USize,
    expected_format: U8)
    ?
  =>
    let w: Writer ref = Writer
    let b = Reader

    MessagePackEncoder.bin(w, v)?

    for bs in w.done().values() do
      b.append(bs)
    end

    h.assert_eq[USize](expected_size, b.size(),
      "size for len=" + v.size().string())
    h.assert_eq[U8](expected_format, b.peek_u8()?,
      "format for len=" + v.size().string())

class \nodoc\ _TestEncodeCompactArray is UnitTest
  """
  Verify that compact array selects the correct format by count.
  """
  fun name(): String =>
    "msgpack/EncodeCompactArray"

  fun ref apply(h: TestHelper) ? =>
    // fixarray boundaries
    _check(h, 0, 1, 0x90)?                          // 0: fixarray
    _check(h, 5, 1, 0x95)?                          // 5: fixarray
    _check(h, 15, 1, 0x9F)?                         // 15: fixarray max
    // array_16 boundaries
    _check(h, 16, 3, _FormatName.array_16())?       // 16: array_16 min
    _check(h, 65535, 3, _FormatName.array_16())?    // 65535: array_16 max
    // array_32 boundary
    _check(h, 65536, 5, _FormatName.array_32())?    // 65536: array_32 min

  fun _check(
    h: TestHelper,
    s: U32,
    expected_size: USize,
    expected_format: U8)
    ?
  =>
    let w: Writer ref = Writer
    let b = Reader

    MessagePackEncoder.array(w, s)

    for bs in w.done().values() do
      b.append(bs)
    end

    h.assert_eq[USize](expected_size, b.size(),
      "size for " + s.string())
    h.assert_eq[U8](expected_format, b.peek_u8()?,
      "format for " + s.string())

class \nodoc\ _TestEncodeCompactMap is UnitTest
  """
  Verify that compact map selects the correct format by count.
  """
  fun name(): String =>
    "msgpack/EncodeCompactMap"

  fun ref apply(h: TestHelper) ? =>
    // fixmap boundaries
    _check(h, 0, 1, 0x80)?                        // 0: fixmap
    _check(h, 5, 1, 0x85)?                        // 5: fixmap
    _check(h, 15, 1, 0x8F)?                       // 15: fixmap max
    // map_16 boundaries
    _check(h, 16, 3, _FormatName.map_16())?       // 16: map_16 min
    _check(h, 65535, 3, _FormatName.map_16())?    // 65535: map_16 max
    // map_32 boundary
    _check(h, 65536, 5, _FormatName.map_32())?    // 65536: map_32 min

  fun _check(
    h: TestHelper,
    s: U32,
    expected_size: USize,
    expected_format: U8)
    ?
  =>
    let w: Writer ref = Writer
    let b = Reader

    MessagePackEncoder.map(w, s)

    for bs in w.done().values() do
      b.append(bs)
    end

    h.assert_eq[USize](expected_size, b.size(),
      "size for " + s.string())
    h.assert_eq[U8](expected_format, b.peek_u8()?,
      "format for " + s.string())

class \nodoc\ _TestEncodeCompactExt is UnitTest
  """
  Verify that compact ext prefers fixext formats for matching
  sizes and falls back to ext_8 for non-fixext sizes.
  """
  fun name(): String =>
    "msgpack/EncodeCompactExt"

  fun ref apply(h: TestHelper) ? =>
    let t: U8 = 42
    // fixext sizes
    _check(h, t, 1, _FormatName.fixext_1())?
    _check(h, t, 2, _FormatName.fixext_2())?
    _check(h, t, 4, _FormatName.fixext_4())?
    _check(h, t, 8, _FormatName.fixext_8())?
    _check(h, t, 16, _FormatName.fixext_16())?
    // ext_8 for non-fixext sizes
    _check(h, t, 3, _FormatName.ext_8())?
    _check(h, t, 0, _FormatName.ext_8())?

  fun _check(
    h: TestHelper,
    t: U8,
    data_size: USize,
    expected_format: U8)
    ?
  =>
    let value = recover val
      Array[U8].init('X', data_size)
    end
    let w: Writer ref = Writer
    let b = Reader

    MessagePackEncoder.ext(w, t, value)?

    for bs in w.done().values() do
      b.append(bs)
    end

    h.assert_eq[U8](expected_format, b.peek_u8()?,
      "format for size=" + data_size.string())

class \nodoc\ _TestEncodeCompactTimestamp is UnitTest
  """
  Verify that compact timestamp selects the correct format.
  """
  fun name(): String =>
    "msgpack/EncodeCompactTimestamp"

  fun ref apply(h: TestHelper) ? =>
    // timestamp_32 boundaries
    _check(h, 0, 0, _FormatName.fixext_4(),
      "ts32: sec=0 nsec=0")?
    _check(h, 500, 0, _FormatName.fixext_4(),
      "ts32: sec=500 nsec=0")?
    _check(h, U32.max_value().i64(), 0,
      _FormatName.fixext_4(),
      "ts32: sec=U32.max nsec=0")?

    // timestamp_64 boundaries
    // nsec != 0 pushes to timestamp_64
    _check(h, 500, 100, _FormatName.fixext_8(),
      "ts64: sec=500 nsec=100")?
    // sec > U32.max pushes to timestamp_64 even with nsec=0
    _check(h, U32.max_value().i64() + 1, 0,
      _FormatName.fixext_8(),
      "ts64: sec=U32.max+1 nsec=0")?
    // sec at 34-bit max
    _check(h, _Limit.sec_34().i64(), 0,
      _FormatName.fixext_8(),
      "ts64: sec=2^34-1 nsec=0")?

    // timestamp_96 boundaries
    // sec exceeds 34-bit max
    _check(h, _Limit.sec_34().i64() + 1, 0,
      _FormatName.ext_8(),
      "ts96: sec=2^34 nsec=0")?
    // negative sec
    _check(h, -1000, 500, _FormatName.ext_8(),
      "ts96: sec=-1000 nsec=500")?

  fun _check(
    h: TestHelper,
    sec: I64,
    nsec: U32,
    expected_format: U8,
    label: String)
    ?
  =>
    let w: Writer ref = Writer
    let b = Reader
    MessagePackEncoder.timestamp(w, sec, nsec)?
    for bs in w.done().values() do
      b.append(bs)
    end
    h.assert_eq[U8](expected_format, b.peek_u8()?,
      label)

class \nodoc\ _TestEncodeFixstrUtf8 is UnitTest
  fun name(): String =>
    "msgpack/EncodeFixstrUtf8"

  fun ref apply(h: TestHelper) ? =>
    let value = "Hello"
    let b = Reader
    let w: Writer ref = Writer
    MessagePackEncoder.fixstr_utf8(w, value)?
    for bs in w.done().values() do
      b.append(bs)
    end
    h.assert_eq[USize](6, b.size())
    h.assert_eq[U8](0xA5, b.peek_u8()?)

class \nodoc\ _TestEncodeFixstrUtf8Invalid is UnitTest
  fun name(): String =>
    "msgpack/EncodeFixstrUtf8Invalid"

  fun ref apply(h: TestHelper) =>
    let invalid = recover val [as U8: 0xFF; 0xFE] end
    let w: Writer ref = Writer
    try
      MessagePackEncoder.fixstr_utf8(w, invalid)?
      h.fail("expected error for invalid UTF-8")
    end

class \nodoc\ _TestEncodeStr8Utf8 is UnitTest
  fun name(): String =>
    "msgpack/EncodeStr8Utf8"

  fun ref apply(h: TestHelper) ? =>
    let value = "Hello"
    let b = Reader
    let w: Writer ref = Writer
    MessagePackEncoder.str_8_utf8(w, value)?
    for bs in w.done().values() do
      b.append(bs)
    end
    h.assert_eq[USize](7, b.size())
    h.assert_eq[U8](_FormatName.str_8(), b.peek_u8()?)

class \nodoc\ _TestEncodeStr8Utf8Invalid is UnitTest
  fun name(): String =>
    "msgpack/EncodeStr8Utf8Invalid"

  fun ref apply(h: TestHelper) =>
    let invalid = recover val [as U8: 0xFF; 0xFE] end
    let w: Writer ref = Writer
    try
      MessagePackEncoder.str_8_utf8(w, invalid)?
      h.fail("expected error for invalid UTF-8")
    end

class \nodoc\ _TestEncodeStr16Utf8 is UnitTest
  fun name(): String =>
    "msgpack/EncodeStr16Utf8"

  fun ref apply(h: TestHelper) ? =>
    let value = "Hello"
    let b = Reader
    let w: Writer ref = Writer
    MessagePackEncoder.str_16_utf8(w, value)?
    for bs in w.done().values() do
      b.append(bs)
    end
    h.assert_eq[USize](8, b.size())
    h.assert_eq[U8](_FormatName.str_16(), b.peek_u8()?)

class \nodoc\ _TestEncodeStr16Utf8Invalid is UnitTest
  fun name(): String =>
    "msgpack/EncodeStr16Utf8Invalid"

  fun ref apply(h: TestHelper) =>
    let invalid = recover val [as U8: 0xFF; 0xFE] end
    let w: Writer ref = Writer
    try
      MessagePackEncoder.str_16_utf8(w, invalid)?
      h.fail("expected error for invalid UTF-8")
    end

class \nodoc\ _TestEncodeStr32Utf8 is UnitTest
  fun name(): String =>
    "msgpack/EncodeStr32Utf8"

  fun ref apply(h: TestHelper) ? =>
    let value = "Hello"
    let b = Reader
    let w: Writer ref = Writer
    MessagePackEncoder.str_32_utf8(w, value)?
    for bs in w.done().values() do
      b.append(bs)
    end
    h.assert_eq[USize](10, b.size())
    h.assert_eq[U8](_FormatName.str_32(), b.peek_u8()?)

class \nodoc\ _TestEncodeStr32Utf8Invalid is UnitTest
  fun name(): String =>
    "msgpack/EncodeStr32Utf8Invalid"

  fun ref apply(h: TestHelper) =>
    let invalid = recover val [as U8: 0xFF; 0xFE] end
    let w: Writer ref = Writer
    try
      MessagePackEncoder.str_32_utf8(w, invalid)?
      h.fail("expected error for invalid UTF-8")
    end

class \nodoc\ _TestEncodeCompactStrUtf8 is UnitTest
  fun name(): String =>
    "msgpack/EncodeCompactStrUtf8"

  fun ref apply(h: TestHelper) ? =>
    let value = "Hello"
    let b = Reader
    let w: Writer ref = Writer
    MessagePackEncoder.str_utf8(w, value)?
    for bs in w.done().values() do
      b.append(bs)
    end
    h.assert_eq[USize](6, b.size())
    h.assert_eq[U8](0xA5, b.peek_u8()?)

class \nodoc\ _TestEncodeCompactStrUtf8Invalid is UnitTest
  fun name(): String =>
    "msgpack/EncodeCompactStrUtf8Invalid"

  fun ref apply(h: TestHelper) =>
    let invalid = recover val [as U8: 0xFF; 0xFE] end
    let w: Writer ref = Writer
    try
      MessagePackEncoder.str_utf8(w, invalid)?
      h.fail("expected error for invalid UTF-8")
    end

class \nodoc\ _TestEncodeStrUtf8ByteArray is UnitTest
  """
  Tests the Array[U8] val match arm in encoder _utf8 methods.
  """
  fun name(): String =>
    "msgpack/EncodeStrUtf8ByteArray"

  fun ref apply(h: TestHelper) ? =>
    // Valid UTF-8 as Array[U8] val
    let valid = recover val [as U8: 'H'; 'i'] end
    let w1: Writer ref = Writer
    MessagePackEncoder.str_utf8(w1, valid)?
    let b1 = Reader
    for bs in w1.done().values() do
      b1.append(bs)
    end
    h.assert_eq[USize](3, b1.size())

    // Invalid UTF-8 as Array[U8] val
    let invalid = recover val [as U8: 0xFF] end
    let w2: Writer ref = Writer
    try
      MessagePackEncoder.str_utf8(w2, invalid)?
      h.fail("expected error for invalid UTF-8 array")
    end

class \nodoc\ _PropertyCompactStrUtf8EncoderRoundtrip
  is Property1[String]
  """
  For any ASCII string, compact str_utf8 encode then str_utf8
  decode returns the original string.
  """
  fun name(): String =>
    "msgpack/PropertyCompactStrUtf8EncoderRoundtrip"

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

    MessagePackEncoder.str_utf8(w, s)?

    for bs in w.done().values() do
      b.append(bs)
    end

    h.assert_eq[String](s, MessagePackDecoder.str_utf8(b)?)
