use "buffered"
use "ponytest"

actor Main is TestList
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

class _TestEncodeNil is UnitTest
  """
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
  Covers both str_8 and bin_8.
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
  Covers both str_16 and bin_16.
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
  Covers both str_32 and bin_32.
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
