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

    h.assert_eq[USize](b.size(), 1)
    h.assert_eq[U8](b.peek_u8()?, _FormatName.nil())

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

    h.assert_eq[USize](b.size(), 1)
    h.assert_eq[U8](b.peek_u8()?, _FormatName.truthy())

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

    h.assert_eq[USize](b.size(), 1)
    h.assert_eq[U8](b.peek_u8()?, _FormatName.falsey())

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
    h.assert_eq[USize](b.size(), 1)
    h.assert_eq[U8](b.peek_u8()?, 0x0a)

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
    h.assert_eq[USize](b.size(), 1)
    h.assert_eq[U8](b.peek_u8()?, 0xF6)

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
