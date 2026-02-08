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
use "pony_check"
use "pony_test"

primitive _ZeroCopyBytes
  """
  Collects Writer output into a ZeroCopyReader as a single
  contiguous chunk.
  """
  fun apply(w: Writer ref): ZeroCopyReader ref =>
    let b = ZeroCopyReader
    let out = recover val
      let a = Array[U8]
      for chunk in w.done().values() do
        match chunk
        | let arr: Array[U8] val => a.append(arr)
        | let s: String val => a.append(s.array())
        end
      end
      a
    end
    b.append(out)
    b

actor \nodoc\ _TestZeroCopyDecoder is TestList
  new make() =>
    None

  fun tag tests(test: PonyTest) =>
    // ZeroCopyReader tests
    test(_TestZCReaderBlockSingleChunk)
    test(_TestZCReaderBlockMultiChunk)
    test(_TestZCReaderNumericReads)
    test(_TestZCReaderPeek)
    test(_TestZCReaderSkip)
    test(_TestZCReaderEmpty)
    test(_TestZCReaderExactBoundary)
    // Roundtrip tests
    test(_TestZCDecodeNil)
    test(_TestZCDecodeTrue)
    test(_TestZCDecodeFalse)
    test(_TestZCDecodeU8)
    test(_TestZCDecodeU16)
    test(_TestZCDecodeU32)
    test(_TestZCDecodeU64)
    test(_TestZCDecodeI8)
    test(_TestZCDecodeI16)
    test(_TestZCDecodeI32)
    test(_TestZCDecodeI64)
    test(_TestZCDecodePositiveFixint)
    test(_TestZCDecodeNegativeFixint)
    test(_TestZCDecodeF32)
    test(_TestZCDecodeF64)
    test(_TestZCDecodeFixstr)
    test(_TestZCDecodeStr8)
    test(_TestZCDecodeStr16)
    test(_TestZCDecodeStr32)
    test(_TestZCDecodeBin8)
    test(_TestZCDecodeBin16)
    test(_TestZCDecodeBin32)
    test(_TestZCDecodeFixarray)
    test(_TestZCDecodeArray16)
    test(_TestZCDecodeArray32)
    test(_TestZCDecodeFixmap)
    test(_TestZCDecodeMap16)
    test(_TestZCDecodeMap32)
    test(_TestZCDecodeFixext1)
    test(_TestZCDecodeFixext2)
    test(_TestZCDecodeFixext4)
    test(_TestZCDecodeFixext8)
    test(_TestZCDecodeFixext16)
    test(_TestZCDecodeExt8)
    test(_TestZCDecodeExt16)
    test(_TestZCDecodeExt32)
    test(_TestZCDecodeTimestamp32)
    test(_TestZCDecodeTimestamp64)
    test(_TestZCDecodeTimestamp96)
    test(_TestZCDecodeCompactUint)
    test(_TestZCDecodeCompactInt)
    test(_TestZCDecodeCompactStr)
    test(_TestZCDecodeCompactArray)
    test(_TestZCDecodeCompactMap)
    test(_TestZCDecodeCompactExt)
    test(_TestZCDecodeCompactTimestamp)
    // Property-based roundtrip tests
    test(Property1UnitTest[U64](
      _PropertyZCCompactUintRoundtrip))
    test(Property1UnitTest[I64](
      _PropertyZCCompactIntRoundtrip))
    test(Property1UnitTest[String](
      _PropertyZCCompactStrRoundtrip))
    test(Property1UnitTest[U32](
      _PropertyZCCompactArrayRoundtrip))
    test(Property1UnitTest[U32](
      _PropertyZCCompactMapRoundtrip))
    test(Property1UnitTest[String](
      _PropertyZCStr8Roundtrip))
    test(Property1UnitTest[String](
      _PropertyZCStr16Roundtrip))
    test(Property1UnitTest[
      (U8, Array[U8] val)](
      _PropertyZCBin8Roundtrip))
    test(Property1UnitTest[
      (U8, Array[U8] val)](
      _PropertyZCBin16Roundtrip))
    test(Property1UnitTest[
      (U8, Array[U8] val)](
      _PropertyZCFixext1Roundtrip))
    test(Property1UnitTest[
      (U8, Array[U8] val)](
      _PropertyZCFixext2Roundtrip))
    test(Property1UnitTest[
      (U8, Array[U8] val)](
      _PropertyZCFixext4Roundtrip))
    test(Property1UnitTest[
      (U8, Array[U8] val)](
      _PropertyZCFixext8Roundtrip))
    test(Property1UnitTest[
      (U8, Array[U8] val)](
      _PropertyZCFixext16Roundtrip))
    test(Property1UnitTest[
      (U8, Array[U8] val)](
      _PropertyZCExt8Roundtrip))
    test(Property1UnitTest[
      (U8, Array[U8] val)](
      _PropertyZCExt16Roundtrip))
    // Cross-decoder equivalence
    test(Property1UnitTest[String](
      _PropertyZCCrossDecoderStr))
    test(Property1UnitTest[
      (U8, Array[U8] val)](
      _PropertyZCCrossDecoderBin))

//
// ZeroCopyReader tests
//

class \nodoc\ _TestZCReaderBlockSingleChunk is UnitTest
  fun name(): String => "msgpack/ZCReaderBlockSingleChunk"

  fun ref apply(h: TestHelper) ? =>
    let data: Array[U8] val =
      recover val [as U8: 1; 2; 3; 4; 5] end
    let b = ZeroCopyReader
    b.append(data)
    let result = b.block(3)?
    h.assert_eq[USize](3, result.size())
    h.assert_eq[U8](1, result(0)?)
    h.assert_eq[U8](2, result(1)?)
    h.assert_eq[U8](3, result(2)?)
    h.assert_eq[USize](2, b.size())

class \nodoc\ _TestZCReaderBlockMultiChunk is UnitTest
  fun name(): String => "msgpack/ZCReaderBlockMultiChunk"

  fun ref apply(h: TestHelper) ? =>
    let b = ZeroCopyReader
    b.append(recover val [as U8: 1; 2] end)
    b.append(recover val [as U8: 3; 4; 5] end)
    let result = b.block(4)?
    h.assert_eq[USize](4, result.size())
    h.assert_eq[U8](1, result(0)?)
    h.assert_eq[U8](2, result(1)?)
    h.assert_eq[U8](3, result(2)?)
    h.assert_eq[U8](4, result(3)?)
    h.assert_eq[USize](1, b.size())

class \nodoc\ _TestZCReaderNumericReads is UnitTest
  fun name(): String => "msgpack/ZCReaderNumericReads"

  fun ref apply(h: TestHelper) ? =>
    // Encode known values using Writer, read back with
    // ZeroCopyReader
    let w: Writer ref = Writer
    w.u8(42)
    w.u16_be(1000)
    w.u32_be(100000)
    w.u64_be(10000000000)
    w.u8(I8(-5).u8())
    w.i16_be(-1000)
    w.i32_be(-100000)
    w.i64_be(-10000000000)
    w.f32_be(3.14)
    w.f64_be(2.71828)

    let b = ZeroCopyReader
    let out = recover val
      let a = Array[U8]
      for chunk in w.done().values() do
        match chunk
        | let arr: Array[U8] val => a.append(arr)
        | let s: String val => a.append(s.array())
        end
      end
      a
    end
    b.append(out)

    h.assert_eq[U8](42, b.u8()?)
    h.assert_eq[U16](1000, b.u16_be()?)
    h.assert_eq[U32](100000, b.u32_be()?)
    h.assert_eq[U64](10000000000, b.u64_be()?)
    h.assert_eq[I8](-5, b.i8()?)
    h.assert_eq[I16](-1000, b.i16_be()?)
    h.assert_eq[I32](-100000, b.i32_be()?)
    h.assert_eq[I64](-10000000000, b.i64_be()?)
    h.assert_eq[F32](3.14, b.f32_be()?)
    h.assert_eq[F64](2.71828, b.f64_be()?)

class \nodoc\ _TestZCReaderPeek is UnitTest
  fun name(): String => "msgpack/ZCReaderPeek"

  fun ref apply(h: TestHelper) ? =>
    let b = ZeroCopyReader
    b.append(recover val
      [as U8: 0xCA; 0xFE; 0xBA; 0xBE; 0xDE; 0xAD]
    end)
    // peek_u8
    h.assert_eq[U8](0xCA, b.peek_u8()?)
    h.assert_eq[U8](0xFE, b.peek_u8(1)?)
    h.assert_eq[U8](0xDE, b.peek_u8(4)?)
    // peek_u16_be
    h.assert_eq[U16](0xCAFE, b.peek_u16_be()?)
    h.assert_eq[U16](0xFEBA, b.peek_u16_be(1)?)
    // peek_u32_be
    h.assert_eq[U32](0xCAFEBABE, b.peek_u32_be()?)
    h.assert_eq[U32](0xFEBABEDE, b.peek_u32_be(1)?)
    // Verify nothing was consumed
    h.assert_eq[USize](6, b.size())

class \nodoc\ _TestZCReaderSkip is UnitTest
  fun name(): String => "msgpack/ZCReaderSkip"

  fun ref apply(h: TestHelper) ? =>
    let b = ZeroCopyReader
    b.append(
      recover val [as U8: 1; 2; 3; 4; 5] end)
    b.skip(3)?
    h.assert_eq[USize](2, b.size())
    h.assert_eq[U8](4, b.u8()?)
    h.assert_eq[U8](5, b.u8()?)

class \nodoc\ _TestZCReaderEmpty is UnitTest
  fun name(): String => "msgpack/ZCReaderEmpty"

  fun ref apply(h: TestHelper) =>
    let b = ZeroCopyReader
    h.assert_eq[USize](0, b.size())
    h.assert_error({()? => ZeroCopyReader.block(1)? })
    h.assert_error({()? => ZeroCopyReader.u8()? })
    h.assert_error({()? => ZeroCopyReader.skip(1)? })

class \nodoc\ _TestZCReaderExactBoundary is UnitTest
  fun name(): String =>
    "msgpack/ZCReaderExactBoundary"

  fun ref apply(h: TestHelper) ? =>
    let b = ZeroCopyReader
    b.append(recover val [as U8: 1; 2; 3] end)
    b.append(recover val [as U8: 4; 5; 6] end)
    // Read exactly the first chunk
    let r1 = b.block(3)?
    h.assert_eq[USize](3, r1.size())
    h.assert_eq[U8](1, r1(0)?)
    // Read exactly the second chunk
    let r2 = b.block(3)?
    h.assert_eq[USize](3, r2.size())
    h.assert_eq[U8](4, r2(0)?)
    h.assert_eq[USize](0, b.size())

//
// Roundtrip tests
//

class \nodoc\ _TestZCDecodeNil is UnitTest
  fun name(): String => "msgpack/ZCDecodeNil"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.nil(w)
    MessagePackZeroCopyDecoder.nil(_ZeroCopyBytes(w))?

class \nodoc\ _TestZCDecodeTrue is UnitTest
  fun name(): String => "msgpack/ZCDecodeTrue"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.bool(w, true)
    h.assert_true(
      MessagePackZeroCopyDecoder.bool(
        _ZeroCopyBytes(w))?)

class \nodoc\ _TestZCDecodeFalse is UnitTest
  fun name(): String => "msgpack/ZCDecodeFalse"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.bool(w, false)
    h.assert_false(
      MessagePackZeroCopyDecoder.bool(
        _ZeroCopyBytes(w))?)

class \nodoc\ _TestZCDecodeU8 is UnitTest
  fun name(): String => "msgpack/ZCDecodeU8"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.uint_8(w, 9)
    h.assert_eq[U8](9,
      MessagePackZeroCopyDecoder.u8(
        _ZeroCopyBytes(w))?)

class \nodoc\ _TestZCDecodeU16 is UnitTest
  fun name(): String => "msgpack/ZCDecodeU16"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.uint_16(w, 17)
    h.assert_eq[U16](17,
      MessagePackZeroCopyDecoder.u16(
        _ZeroCopyBytes(w))?)

class \nodoc\ _TestZCDecodeU32 is UnitTest
  fun name(): String => "msgpack/ZCDecodeU32"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.uint_32(w, 33)
    h.assert_eq[U32](33,
      MessagePackZeroCopyDecoder.u32(
        _ZeroCopyBytes(w))?)

class \nodoc\ _TestZCDecodeU64 is UnitTest
  fun name(): String => "msgpack/ZCDecodeU64"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.uint_64(w, 65)
    h.assert_eq[U64](65,
      MessagePackZeroCopyDecoder.u64(
        _ZeroCopyBytes(w))?)

class \nodoc\ _TestZCDecodeI8 is UnitTest
  fun name(): String => "msgpack/ZCDecodeI8"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.int_8(w, 9)
    h.assert_eq[I8](9,
      MessagePackZeroCopyDecoder.i8(
        _ZeroCopyBytes(w))?)

class \nodoc\ _TestZCDecodeI16 is UnitTest
  fun name(): String => "msgpack/ZCDecodeI16"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.int_16(w, 17)
    h.assert_eq[I16](17,
      MessagePackZeroCopyDecoder.i16(
        _ZeroCopyBytes(w))?)

class \nodoc\ _TestZCDecodeI32 is UnitTest
  fun name(): String => "msgpack/ZCDecodeI32"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.int_32(w, 33)
    h.assert_eq[I32](33,
      MessagePackZeroCopyDecoder.i32(
        _ZeroCopyBytes(w))?)

class \nodoc\ _TestZCDecodeI64 is UnitTest
  fun name(): String => "msgpack/ZCDecodeI64"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.int_64(w, 65)
    h.assert_eq[I64](65,
      MessagePackZeroCopyDecoder.i64(
        _ZeroCopyBytes(w))?)

class \nodoc\ _TestZCDecodePositiveFixint is UnitTest
  fun name(): String =>
    "msgpack/ZCDecodePositiveFixint"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.positive_fixint(w, 17)?
    h.assert_eq[U8](17,
      MessagePackZeroCopyDecoder.positive_fixint(
        _ZeroCopyBytes(w))?)

class \nodoc\ _TestZCDecodeNegativeFixint is UnitTest
  fun name(): String =>
    "msgpack/ZCDecodeNegativeFixint"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.negative_fixint(w, -17)?
    h.assert_eq[I8](-17,
      MessagePackZeroCopyDecoder.negative_fixint(
        _ZeroCopyBytes(w))?)

class \nodoc\ _TestZCDecodeF32 is UnitTest
  fun name(): String => "msgpack/ZCDecodeF32"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.float_32(w, 33.33)
    h.assert_eq[F32](33.33,
      MessagePackZeroCopyDecoder.f32(
        _ZeroCopyBytes(w))?)

class \nodoc\ _TestZCDecodeF64 is UnitTest
  fun name(): String => "msgpack/ZCDecodeF64"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.float_64(w, 65.65)
    h.assert_eq[F64](65.65,
      MessagePackZeroCopyDecoder.f64(
        _ZeroCopyBytes(w))?)

class \nodoc\ _TestZCDecodeFixstr is UnitTest
  fun name(): String => "msgpack/ZCDecodeFixstr"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.fixstr(w, "fixstr")?
    h.assert_eq[String]("fixstr",
      MessagePackZeroCopyDecoder.fixstr(
        _ZeroCopyBytes(w))?)

class \nodoc\ _TestZCDecodeStr8 is UnitTest
  fun name(): String => "msgpack/ZCDecodeStr8"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.str_8(w, "str8")?
    h.assert_eq[String]("str8",
      MessagePackZeroCopyDecoder.str_8(
        _ZeroCopyBytes(w))?)

class \nodoc\ _TestZCDecodeStr16 is UnitTest
  fun name(): String => "msgpack/ZCDecodeStr16"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.str_16(w, "str16")?
    h.assert_eq[String]("str16",
      MessagePackZeroCopyDecoder.str_16(
        _ZeroCopyBytes(w))?)

class \nodoc\ _TestZCDecodeStr32 is UnitTest
  fun name(): String => "msgpack/ZCDecodeStr32"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.str_32(w, "str32")?
    h.assert_eq[String]("str32",
      MessagePackZeroCopyDecoder.str_32(
        _ZeroCopyBytes(w))?)

class \nodoc\ _TestZCDecodeBin8 is UnitTest
  fun name(): String => "msgpack/ZCDecodeBin8"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    let value =
      recover val [as U8: 'H'; 'e'; 'l'; 'l'; 'o'] end
    MessagePackEncoder.bin_8(w, value)?
    let decoded =
      MessagePackZeroCopyDecoder.bin_8(
        _ZeroCopyBytes(w))?
    h.assert_eq[U8]('H', decoded(0)?)
    h.assert_eq[U8]('o', decoded(4)?)

class \nodoc\ _TestZCDecodeBin16 is UnitTest
  fun name(): String => "msgpack/ZCDecodeBin16"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    let value =
      recover val [as U8: 'H'; 'e'; 'l'; 'l'; 'o'] end
    MessagePackEncoder.bin_16(w, value)?
    let decoded =
      MessagePackZeroCopyDecoder.bin_16(
        _ZeroCopyBytes(w))?
    h.assert_eq[U8]('H', decoded(0)?)
    h.assert_eq[U8]('o', decoded(4)?)

class \nodoc\ _TestZCDecodeBin32 is UnitTest
  fun name(): String => "msgpack/ZCDecodeBin32"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    let value =
      recover val [as U8: 'H'; 'e'; 'l'; 'l'; 'o'] end
    MessagePackEncoder.bin_32(w, value)?
    let decoded =
      MessagePackZeroCopyDecoder.bin_32(
        _ZeroCopyBytes(w))?
    h.assert_eq[U8]('H', decoded(0)?)
    h.assert_eq[U8]('o', decoded(4)?)

class \nodoc\ _TestZCDecodeFixarray is UnitTest
  fun name(): String => "msgpack/ZCDecodeFixarray"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.fixarray(w, 8)?
    h.assert_eq[U8](8,
      MessagePackZeroCopyDecoder.fixarray(
        _ZeroCopyBytes(w))?)

class \nodoc\ _TestZCDecodeArray16 is UnitTest
  fun name(): String => "msgpack/ZCDecodeArray16"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.array_16(w, 17)
    h.assert_eq[U16](17,
      MessagePackZeroCopyDecoder.array_16(
        _ZeroCopyBytes(w))?)

class \nodoc\ _TestZCDecodeArray32 is UnitTest
  fun name(): String => "msgpack/ZCDecodeArray32"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.array_32(w, 33)
    h.assert_eq[U32](33,
      MessagePackZeroCopyDecoder.array_32(
        _ZeroCopyBytes(w))?)

class \nodoc\ _TestZCDecodeFixmap is UnitTest
  fun name(): String => "msgpack/ZCDecodeFixmap"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.fixmap(w, 8)?
    h.assert_eq[U8](8,
      MessagePackZeroCopyDecoder.fixmap(
        _ZeroCopyBytes(w))?)

class \nodoc\ _TestZCDecodeMap16 is UnitTest
  fun name(): String => "msgpack/ZCDecodeMap16"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.map_16(w, 17)
    h.assert_eq[U16](17,
      MessagePackZeroCopyDecoder.map_16(
        _ZeroCopyBytes(w))?)

class \nodoc\ _TestZCDecodeMap32 is UnitTest
  fun name(): String => "msgpack/ZCDecodeMap32"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.map_32(w, 33)
    h.assert_eq[U32](33,
      MessagePackZeroCopyDecoder.map_32(
        _ZeroCopyBytes(w))?)

class \nodoc\ _TestZCDecodeFixext1 is UnitTest
  fun name(): String => "msgpack/ZCDecodeFixext1"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.fixext_1(w, 7,
      recover val [as U8: 0xAB] end)?
    (let t, let d) =
      MessagePackZeroCopyDecoder.fixext_1(
        _ZeroCopyBytes(w))?
    h.assert_eq[U8](7, t)
    h.assert_eq[U8](0xAB, d(0)?)

class \nodoc\ _TestZCDecodeFixext2 is UnitTest
  fun name(): String => "msgpack/ZCDecodeFixext2"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.fixext_2(w, 7,
      recover val [as U8: 0xAB; 0xCD] end)?
    (let t, let d) =
      MessagePackZeroCopyDecoder.fixext_2(
        _ZeroCopyBytes(w))?
    h.assert_eq[U8](7, t)
    h.assert_eq[USize](2, d.size())

class \nodoc\ _TestZCDecodeFixext4 is UnitTest
  fun name(): String => "msgpack/ZCDecodeFixext4"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.fixext_4(w, 7,
      recover val [as U8: 1; 2; 3; 4] end)?
    (let t, let d) =
      MessagePackZeroCopyDecoder.fixext_4(
        _ZeroCopyBytes(w))?
    h.assert_eq[U8](7, t)
    h.assert_eq[USize](4, d.size())

class \nodoc\ _TestZCDecodeFixext8 is UnitTest
  fun name(): String => "msgpack/ZCDecodeFixext8"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.fixext_8(w, 7,
      recover val
        [as U8: 1; 2; 3; 4; 5; 6; 7; 8]
      end)?
    (let t, let d) =
      MessagePackZeroCopyDecoder.fixext_8(
        _ZeroCopyBytes(w))?
    h.assert_eq[U8](7, t)
    h.assert_eq[USize](8, d.size())

class \nodoc\ _TestZCDecodeFixext16 is UnitTest
  fun name(): String => "msgpack/ZCDecodeFixext16"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    let data = recover val
      let a = Array[U8]
      var i: USize = 0
      while i < 16 do
        a.push(i.u8())
        i = i + 1
      end
      a
    end
    MessagePackEncoder.fixext_16(w, 7, data)?
    (let t, let d) =
      MessagePackZeroCopyDecoder.fixext_16(
        _ZeroCopyBytes(w))?
    h.assert_eq[U8](7, t)
    h.assert_eq[USize](16, d.size())

class \nodoc\ _TestZCDecodeExt8 is UnitTest
  fun name(): String => "msgpack/ZCDecodeExt8"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    let data =
      recover val [as U8: 1; 2; 3; 4; 5] end
    MessagePackEncoder.ext_8(w, 7, data)?
    (let t, let d) =
      MessagePackZeroCopyDecoder.ext_8(
        _ZeroCopyBytes(w))?
    h.assert_eq[U8](7, t)
    h.assert_eq[USize](5, d.size())

class \nodoc\ _TestZCDecodeExt16 is UnitTest
  fun name(): String => "msgpack/ZCDecodeExt16"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    let data =
      recover val [as U8: 1; 2; 3; 4; 5] end
    MessagePackEncoder.ext_16(w, 7, data)?
    (let t, let d) =
      MessagePackZeroCopyDecoder.ext_16(
        _ZeroCopyBytes(w))?
    h.assert_eq[U8](7, t)
    h.assert_eq[USize](5, d.size())

class \nodoc\ _TestZCDecodeExt32 is UnitTest
  fun name(): String => "msgpack/ZCDecodeExt32"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    let data =
      recover val [as U8: 1; 2; 3; 4; 5] end
    MessagePackEncoder.ext_32(w, 7, data)?
    (let t, let d) =
      MessagePackZeroCopyDecoder.ext_32(
        _ZeroCopyBytes(w))?
    h.assert_eq[U8](7, t)
    h.assert_eq[USize](5, d.size())

class \nodoc\ _TestZCDecodeTimestamp32 is UnitTest
  fun name(): String =>
    "msgpack/ZCDecodeTimestamp32"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.timestamp_32(w, 1000)
    (let sec, let nsec) =
      MessagePackZeroCopyDecoder.timestamp(
        _ZeroCopyBytes(w))?
    h.assert_eq[I64](1000, sec)
    h.assert_eq[U32](0, nsec)

class \nodoc\ _TestZCDecodeTimestamp64 is UnitTest
  fun name(): String =>
    "msgpack/ZCDecodeTimestamp64"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.timestamp_64(w, 1000, 500)?
    (let sec, let nsec) =
      MessagePackZeroCopyDecoder.timestamp(
        _ZeroCopyBytes(w))?
    h.assert_eq[I64](1000, sec)
    h.assert_eq[U32](500, nsec)

class \nodoc\ _TestZCDecodeTimestamp96 is UnitTest
  fun name(): String =>
    "msgpack/ZCDecodeTimestamp96"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.timestamp_96(w, -1000, 500)?
    (let sec, let nsec) =
      MessagePackZeroCopyDecoder.timestamp(
        _ZeroCopyBytes(w))?
    h.assert_eq[I64](-1000, sec)
    h.assert_eq[U32](500, nsec)

class \nodoc\ _TestZCDecodeCompactUint is UnitTest
  fun name(): String =>
    "msgpack/ZCDecodeCompactUint"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.uint(w, 42)
    h.assert_eq[U64](42,
      MessagePackZeroCopyDecoder.uint(
        _ZeroCopyBytes(w))?)

class \nodoc\ _TestZCDecodeCompactInt is UnitTest
  fun name(): String =>
    "msgpack/ZCDecodeCompactInt"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.int(w, -42)
    h.assert_eq[I64](-42,
      MessagePackZeroCopyDecoder.int(
        _ZeroCopyBytes(w))?)

class \nodoc\ _TestZCDecodeCompactStr is UnitTest
  fun name(): String =>
    "msgpack/ZCDecodeCompactStr"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.str(w, "hello")?
    h.assert_eq[String]("hello",
      MessagePackZeroCopyDecoder.str(
        _ZeroCopyBytes(w))?)

class \nodoc\ _TestZCDecodeCompactArray is UnitTest
  fun name(): String =>
    "msgpack/ZCDecodeCompactArray"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.array(w, 5)
    h.assert_eq[U32](5,
      MessagePackZeroCopyDecoder.array(
        _ZeroCopyBytes(w))?)

class \nodoc\ _TestZCDecodeCompactMap is UnitTest
  fun name(): String =>
    "msgpack/ZCDecodeCompactMap"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.map(w, 3)
    h.assert_eq[U32](3,
      MessagePackZeroCopyDecoder.map(
        _ZeroCopyBytes(w))?)

class \nodoc\ _TestZCDecodeCompactExt is UnitTest
  fun name(): String =>
    "msgpack/ZCDecodeCompactExt"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    let data =
      recover val [as U8: 1; 2; 3; 4; 5] end
    MessagePackEncoder.ext(w, 7, data)?
    (let t, let d) =
      MessagePackZeroCopyDecoder.ext(
        _ZeroCopyBytes(w))?
    h.assert_eq[U8](7, t)
    h.assert_eq[USize](5, d.size())

class \nodoc\ _TestZCDecodeCompactTimestamp is UnitTest
  fun name(): String =>
    "msgpack/ZCDecodeCompactTimestamp"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.timestamp(w, 1234567890, 0)?
    (let sec, let nsec) =
      MessagePackZeroCopyDecoder.timestamp(
        _ZeroCopyBytes(w))?
    h.assert_eq[I64](1234567890, sec)
    h.assert_eq[U32](0, nsec)

//
// Property-based roundtrip tests
//

class \nodoc\ _PropertyZCCompactUintRoundtrip
  is Property1[U64]
  fun name(): String =>
    "msgpack/PropertyZCCompactUintRoundtrip"

  fun gen(): Generator[U64] =>
    Generators.u64()

  fun property(sample: U64, h: PropertyHelper) ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.uint(w, sample)
    h.assert_eq[U64](sample,
      MessagePackZeroCopyDecoder.uint(
        _ZeroCopyBytes(w))?)

class \nodoc\ _PropertyZCCompactIntRoundtrip
  is Property1[I64]
  fun name(): String =>
    "msgpack/PropertyZCCompactIntRoundtrip"

  fun gen(): Generator[I64] =>
    Generators.i64()

  fun property(sample: I64, h: PropertyHelper) ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.int(w, sample)
    h.assert_eq[I64](sample,
      MessagePackZeroCopyDecoder.int(
        _ZeroCopyBytes(w))?)

class \nodoc\ _PropertyZCCompactStrRoundtrip
  is Property1[String]
  fun name(): String =>
    "msgpack/PropertyZCCompactStrRoundtrip"

  fun gen(): Generator[String] =>
    Generators.ascii(
      where min = 0, max = 100)

  fun property(
    sample: String,
    h: PropertyHelper)
  ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.str(w, sample)?
    h.assert_eq[String](sample,
      MessagePackZeroCopyDecoder.str(
        _ZeroCopyBytes(w))?)

class \nodoc\ _PropertyZCCompactArrayRoundtrip
  is Property1[U32]
  fun name(): String =>
    "msgpack/PropertyZCCompactArrayRoundtrip"

  fun gen(): Generator[U32] =>
    Generators.u32()

  fun property(sample: U32, h: PropertyHelper) ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.array(w, sample)
    h.assert_eq[U32](sample,
      MessagePackZeroCopyDecoder.array(
        _ZeroCopyBytes(w))?)

class \nodoc\ _PropertyZCCompactMapRoundtrip
  is Property1[U32]
  fun name(): String =>
    "msgpack/PropertyZCCompactMapRoundtrip"

  fun gen(): Generator[U32] =>
    Generators.u32()

  fun property(sample: U32, h: PropertyHelper) ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.map(w, sample)
    h.assert_eq[U32](sample,
      MessagePackZeroCopyDecoder.map(
        _ZeroCopyBytes(w))?)

class \nodoc\ _PropertyZCStr8Roundtrip
  is Property1[String]
  fun name(): String =>
    "msgpack/PropertyZCStr8Roundtrip"

  fun gen(): Generator[String] =>
    Generators.ascii(
      where min = 0, max = 255)

  fun property(
    sample: String,
    h: PropertyHelper)
  ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.str_8(w, sample)?
    h.assert_eq[String](sample,
      MessagePackZeroCopyDecoder.str_8(
        _ZeroCopyBytes(w))?)

class \nodoc\ _PropertyZCStr16Roundtrip
  is Property1[String]
  fun name(): String =>
    "msgpack/PropertyZCStr16Roundtrip"

  fun gen(): Generator[String] =>
    Generators.ascii(
      where min = 0, max = 255)

  fun property(
    sample: String,
    h: PropertyHelper)
  ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.str_16(w, sample)?
    h.assert_eq[String](sample,
      MessagePackZeroCopyDecoder.str_16(
        _ZeroCopyBytes(w))?)

class \nodoc\ _PropertyZCBin8Roundtrip
  is Property1[(U8, Array[U8] val)]
  fun name(): String =>
    "msgpack/PropertyZCBin8Roundtrip"

  fun gen(): Generator[(U8, Array[U8] val)] =>
    Generators.map2[U8, USize,
      (U8, Array[U8] val)](
      Generators.u8(),
      Generators.usize(0, U8.max_value().usize()),
      {(fill, len) =>
        (fill,
          recover val
            Array[U8].init(fill, len)
          end)
      })

  fun ref property(
    arg1: (U8, Array[U8] val),
    h: PropertyHelper)
    ?
  =>
    (_, let value) = arg1
    let w: Writer ref = Writer
    MessagePackEncoder.bin_8(w, value)?
    let decoded =
      MessagePackZeroCopyDecoder.bin_8(
        _ZeroCopyBytes(w))?
    h.assert_eq[USize](value.size(), decoded.size())

class \nodoc\ _PropertyZCBin16Roundtrip
  is Property1[(U8, Array[U8] val)]
  fun name(): String =>
    "msgpack/PropertyZCBin16Roundtrip"

  fun gen(): Generator[(U8, Array[U8] val)] =>
    Generators.map2[U8, USize,
      (U8, Array[U8] val)](
      Generators.u8(),
      Generators.usize(0, U8.max_value().usize()),
      {(fill, len) =>
        (fill,
          recover val
            Array[U8].init(fill, len)
          end)
      })

  fun ref property(
    arg1: (U8, Array[U8] val),
    h: PropertyHelper)
    ?
  =>
    (_, let value) = arg1
    let w: Writer ref = Writer
    MessagePackEncoder.bin_16(w, value)?
    let decoded =
      MessagePackZeroCopyDecoder.bin_16(
        _ZeroCopyBytes(w))?
    h.assert_eq[USize](value.size(), decoded.size())

class \nodoc\ _PropertyZCFixext1Roundtrip
  is Property1[(U8, Array[U8] val)]
  fun name(): String =>
    "msgpack/PropertyZCFixext1Roundtrip"

  fun gen(): Generator[(U8, Array[U8] val)] =>
    Generators.map2[U8, U8, (U8, Array[U8] val)](
      Generators.u8()
        .filter({(v) => (v, v != 0xFF) }),
      Generators.u8(),
      {(ext_type, data_byte) =>
        (ext_type,
          recover val [as U8: data_byte] end)
      })

  fun ref property(
    arg1: (U8, Array[U8] val),
    h: PropertyHelper)
    ?
  =>
    (let ext_type, let value) = arg1
    let w: Writer ref = Writer
    MessagePackEncoder.fixext_1(
      w, ext_type, value)?
    (let t, let d) =
      MessagePackZeroCopyDecoder.fixext_1(
        _ZeroCopyBytes(w))?
    h.assert_eq[U8](ext_type, t)
    h.assert_eq[USize](1, d.size())

class \nodoc\ _PropertyZCFixext2Roundtrip
  is Property1[(U8, Array[U8] val)]
  fun name(): String =>
    "msgpack/PropertyZCFixext2Roundtrip"

  fun gen(): Generator[(U8, Array[U8] val)] =>
    Generators.map2[U8, U8, (U8, Array[U8] val)](
      Generators.u8()
        .filter({(v) => (v, v != 0xFF) }),
      Generators.u8(),
      {(ext_type, data_byte) =>
        (ext_type,
          recover val
            Array[U8].init(data_byte, 2)
          end)
      })

  fun ref property(
    arg1: (U8, Array[U8] val),
    h: PropertyHelper)
    ?
  =>
    (let ext_type, let value) = arg1
    let w: Writer ref = Writer
    MessagePackEncoder.fixext_2(
      w, ext_type, value)?
    (let t, let d) =
      MessagePackZeroCopyDecoder.fixext_2(
        _ZeroCopyBytes(w))?
    h.assert_eq[U8](ext_type, t)
    h.assert_eq[USize](2, d.size())

class \nodoc\ _PropertyZCFixext4Roundtrip
  is Property1[(U8, Array[U8] val)]
  fun name(): String =>
    "msgpack/PropertyZCFixext4Roundtrip"

  fun gen(): Generator[(U8, Array[U8] val)] =>
    Generators.map2[U8, U8, (U8, Array[U8] val)](
      Generators.u8()
        .filter({(v) => (v, v != 0xFF) }),
      Generators.u8(),
      {(ext_type, data_byte) =>
        (ext_type,
          recover val
            Array[U8].init(data_byte, 4)
          end)
      })

  fun ref property(
    arg1: (U8, Array[U8] val),
    h: PropertyHelper)
    ?
  =>
    (let ext_type, let value) = arg1
    let w: Writer ref = Writer
    MessagePackEncoder.fixext_4(
      w, ext_type, value)?
    (let t, let d) =
      MessagePackZeroCopyDecoder.fixext_4(
        _ZeroCopyBytes(w))?
    h.assert_eq[U8](ext_type, t)
    h.assert_eq[USize](4, d.size())

class \nodoc\ _PropertyZCFixext8Roundtrip
  is Property1[(U8, Array[U8] val)]
  fun name(): String =>
    "msgpack/PropertyZCFixext8Roundtrip"

  fun gen(): Generator[(U8, Array[U8] val)] =>
    Generators.map2[U8, U8, (U8, Array[U8] val)](
      Generators.u8()
        .filter({(v) => (v, v != 0xFF) }),
      Generators.u8(),
      {(ext_type, data_byte) =>
        (ext_type,
          recover val
            Array[U8].init(data_byte, 8)
          end)
      })

  fun ref property(
    arg1: (U8, Array[U8] val),
    h: PropertyHelper)
    ?
  =>
    (let ext_type, let value) = arg1
    let w: Writer ref = Writer
    MessagePackEncoder.fixext_8(
      w, ext_type, value)?
    (let t, let d) =
      MessagePackZeroCopyDecoder.fixext_8(
        _ZeroCopyBytes(w))?
    h.assert_eq[U8](ext_type, t)
    h.assert_eq[USize](8, d.size())

class \nodoc\ _PropertyZCFixext16Roundtrip
  is Property1[(U8, Array[U8] val)]
  fun name(): String =>
    "msgpack/PropertyZCFixext16Roundtrip"

  fun gen(): Generator[(U8, Array[U8] val)] =>
    Generators.map2[U8, U8, (U8, Array[U8] val)](
      Generators.u8()
        .filter({(v) => (v, v != 0xFF) }),
      Generators.u8(),
      {(ext_type, data_byte) =>
        (ext_type,
          recover val
            Array[U8].init(data_byte, 16)
          end)
      })

  fun ref property(
    arg1: (U8, Array[U8] val),
    h: PropertyHelper)
    ?
  =>
    (let ext_type, let value) = arg1
    let w: Writer ref = Writer
    MessagePackEncoder.fixext_16(
      w, ext_type, value)?
    (let t, let d) =
      MessagePackZeroCopyDecoder.fixext_16(
        _ZeroCopyBytes(w))?
    h.assert_eq[U8](ext_type, t)
    h.assert_eq[USize](16, d.size())

class \nodoc\ _PropertyZCExt8Roundtrip
  is Property1[(U8, Array[U8] val)]
  fun name(): String =>
    "msgpack/PropertyZCExt8Roundtrip"

  fun gen(): Generator[(U8, Array[U8] val)] =>
    Generators.map2[U8, USize,
      (U8, Array[U8] val)](
      Generators.u8()
        .filter({(v) => (v, v != 0xFF) }),
      Generators.usize(0, U8.max_value().usize()),
      {(ext_type, len) =>
        (ext_type,
          recover val
            Array[U8].init('X', len)
          end)
      })

  fun ref property(
    arg1: (U8, Array[U8] val),
    h: PropertyHelper)
    ?
  =>
    (let ext_type, let value) = arg1
    let w: Writer ref = Writer
    MessagePackEncoder.ext_8(
      w, ext_type, value)?
    (let t, let d) =
      MessagePackZeroCopyDecoder.ext_8(
        _ZeroCopyBytes(w))?
    h.assert_eq[U8](ext_type, t)
    h.assert_eq[USize](value.size(), d.size())

class \nodoc\ _PropertyZCExt16Roundtrip
  is Property1[(U8, Array[U8] val)]
  fun name(): String =>
    "msgpack/PropertyZCExt16Roundtrip"

  fun gen(): Generator[(U8, Array[U8] val)] =>
    Generators.map2[U8, USize,
      (U8, Array[U8] val)](
      Generators.u8()
        .filter({(v) => (v, v != 0xFF) }),
      Generators.frequency[USize]([
        as WeightedGenerator[USize]:
        (7, Generators.usize(0, 300))
        (3, Generators.usize(301, 1000))
      ]),
      {(ext_type, len) =>
        (ext_type,
          recover val
            Array[U8].init('X', len)
          end)
      })

  fun ref property(
    arg1: (U8, Array[U8] val),
    h: PropertyHelper)
    ?
  =>
    (let ext_type, let value) = arg1
    let w: Writer ref = Writer
    MessagePackEncoder.ext_16(
      w, ext_type, value)?
    (let t, let d) =
      MessagePackZeroCopyDecoder.ext_16(
        _ZeroCopyBytes(w))?
    h.assert_eq[U8](ext_type, t)
    h.assert_eq[USize](value.size(), d.size())

//
// Cross-decoder equivalence
//

class \nodoc\ _PropertyZCCrossDecoderStr
  is Property1[String]
  fun name(): String =>
    "msgpack/PropertyZCCrossDecoderStr"

  fun gen(): Generator[String] =>
    Generators.ascii(
      where min = 0, max = 100)

  fun property(
    sample: String,
    h: PropertyHelper)
  ? =>
    // Encode once
    let w1: Writer ref = Writer
    MessagePackEncoder.str(w1, sample)?
    let bytes = _WriterBytes(w1)

    // Decode with original decoder
    let r1: Reader ref = Reader
    r1.append(bytes)
    let v1 = MessagePackDecoder.str(r1)?

    // Decode with zero-copy decoder
    let r2 = ZeroCopyReader
    r2.append(bytes)
    let v2 = MessagePackZeroCopyDecoder.str(r2)?

    h.assert_eq[String](consume v1, v2)

class \nodoc\ _PropertyZCCrossDecoderBin
  is Property1[(U8, Array[U8] val)]
  fun name(): String =>
    "msgpack/PropertyZCCrossDecoderBin"

  fun gen(): Generator[(U8, Array[U8] val)] =>
    Generators.map2[U8, USize,
      (U8, Array[U8] val)](
      Generators.u8(),
      Generators.usize(0, U8.max_value().usize()),
      {(fill, len) =>
        (fill,
          recover val
            Array[U8].init(fill, len)
          end)
      })

  fun ref property(
    arg1: (U8, Array[U8] val),
    h: PropertyHelper)
    ?
  =>
    (_, let data) = arg1
    // Encode once
    let w1: Writer ref = Writer
    MessagePackEncoder.bin(w1, data)?
    let bytes = _WriterBytes(w1)

    // Decode with original decoder
    let r1: Reader ref = Reader
    r1.append(bytes)
    let v1 = MessagePackDecoder.byte_array(r1)?

    // Decode with zero-copy decoder
    let r2 = ZeroCopyReader
    r2.append(bytes)
    let v2 =
      MessagePackZeroCopyDecoder.byte_array(r2)?

    h.assert_eq[USize](v1.size(), v2.size())
