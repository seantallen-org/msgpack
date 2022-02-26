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

actor _TestEncoder is TestList
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

class _TestEncodeNil is UnitTest
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

class _TestEncodeTrue is UnitTest
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

class _TestEncodeFalse is UnitTest
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

class _TestEncodePositiveFixint is UnitTest
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

class _TestEncodePositiveFixintTooLarge is UnitTest
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

class _TestEncodeNegativeFixint is UnitTest
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

class _TestEncodeNegativeFixintOutOfRange is UnitTest
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

class _TestEncodeUint8 is UnitTest
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

class _TestEncodeUint16 is UnitTest
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

class _TestEncodeUint32 is UnitTest
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

class _TestEncodeUint64 is UnitTest
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

class _TestEncodeInt8 is UnitTest
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

class _TestEncodeInt16 is UnitTest
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

class _TestEncodeInt32 is UnitTest
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

class _TestEncodeInt64 is UnitTest
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

class _TestEncodeFloat32 is UnitTest
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

class _TestEncodeFloat64 is UnitTest
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

class _TestEncodeFixstr is UnitTest
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

class _TestEncodeFixstrTooLarge is UnitTest
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

class _TestEncodeStr8 is UnitTest
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

class _TestEncodeStr8TooLarge is UnitTest
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

class _TestEncodeStr16 is UnitTest
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

class _TestEncodeStr16TooLarge is UnitTest
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

class _TestEncodeStr32 is UnitTest
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

class _TestEncodeStr32TooLarge is UnitTest
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

class _TestEncodeBin8 is UnitTest
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

class _TestEncodeBin16 is UnitTest
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

class _TestEncodeBin32 is UnitTest
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

class _TestEncodeFixarray is UnitTest
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

class _TestEncodeFixarrayTooLarge is UnitTest
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

class _TestEncodeArray16 is UnitTest
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

class _TestEncodeArray32 is UnitTest
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

class _TestEncodeFixmap is UnitTest
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

class _TestEncodeFixmapTooLarge is UnitTest
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

class _TestEncodeMap16 is UnitTest
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

class _TestEncodeMap32 is UnitTest
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

class _TestEncodeFixext1 is UnitTest
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

class _TestEncodeFixext1IncorrectSize is UnitTest
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

class _TestEncodeFixext2 is UnitTest
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

class _TestEncodeFixext2IncorrectSize is UnitTest
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

class _TestEncodeFixext4 is UnitTest
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

class _TestEncodeFixext4IncorrectSize is UnitTest
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

class _TestEncodeFixext8 is UnitTest
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

class _TestEncodeFixext8IncorrectSize is UnitTest
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

class _TestEncodeFixext16 is UnitTest
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

class _TestEncodeFixext16IncorrectSize is UnitTest
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

class _TestEncodeExt8 is UnitTest
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

class _TestEncodeExt8TooLarge is UnitTest
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

class _TestEncodeExt16 is UnitTest
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

class _TestEncodeExt16TooLarge is UnitTest
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

class _TestEncodeExt32 is UnitTest
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

class _TestEncodeExt32TooLarge is UnitTest
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

class _TestEncodeTimestamp32 is UnitTest
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

class _TestEncodeTimestamp64 is UnitTest
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

class _TestEncodeTimestamp64SecsTooLarge is UnitTest
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

class _TestEncodeTimestamp64NsecsTooLarge is UnitTest
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

class _TestEncodeTimestamp96 is UnitTest
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

class _TestEncodeTimestamp96NsecsTooLarge is UnitTest
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
