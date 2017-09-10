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
use "ponytest"

actor Main is TestList
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
  new create(env: Env) =>
    PonyTest(env, this)

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
    test(_TestEncodeStr16TooLarge)
    test(_TestEncodeStr32)
    test(_TestEncodeStr32TooLarge)
    test(_TestEncodeBin8)
    test(_TestEncodeBin16)
    test(_TestEncodeBin32)
    test(_TestEncodeFixarray)
    test(_TestEncodeFixarrayTooLarge)

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
      try
        b.append(bs as Array[U8] val)
      end
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
      try
        b.append(bs as Array[U8] val)
      end
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
      try
        b.append(bs as Array[U8] val)
      end
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
      try
        b.append(bs as Array[U8] val)
      end
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
      try
        b.append(bs as Array[U8] val)
      end
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
      try
        b.append(bs as Array[U8] val)
      end
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
      try
        b.append(bs as Array[U8] val)
      end
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
      try
        b.append(bs as Array[U8] val)
      end
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
      try
        b.append(bs as Array[U8] val)
      end
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
      try
        b.append(bs as Array[U8] val)
      end
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
      try
        b.append(bs as Array[U8] val)
      end
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
      try
        b.append(bs as Array[U8] val)
      end
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
      try
        b.append(bs as Array[U8] val)
      end
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
      try
        b.append(bs as Array[U8] val)
      end
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
      try
        b.append(bs as Array[U8] val)
      end
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
      try
        b.append(bs as Array[U8] val)
      end
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
      try
        b.append(bs as Array[U8] val)
      end
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
  Verify that `str_8` and `bin_8` throw an error if supplied with a valid t
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
      try
        b.append(bs as Array[U8] val)
      end
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
  Verify that `str_16` and `bin_16` throw an error if supplied with a valid t
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
      try
        b.append(bs as Array[U8] val)
      end
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
  Verify that `str_32` and `bin_32` throw an error if supplied with a valid t
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
      try
        b.append(bs as Array[U8] val)
      end
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
      try
        b.append(bs as Array[U8] val)
      end
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
      try
        b.append(bs as Array[U8] val)
      end
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
      try
        b.append(bs as Array[U8] val)
      end
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
