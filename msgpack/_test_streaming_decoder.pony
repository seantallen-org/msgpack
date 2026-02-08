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

primitive _WriterBytes
  """
  Collects Writer output into a single contiguous Array[U8] val.
  """
  fun apply(w: Writer ref): Array[U8] val =>
    let out = recover iso Array[U8] end
    for chunk in w.done().values() do
      match chunk
      | let a: Array[U8] val => out.append(a)
      | let s: String val => out.append(s.array())
      end
    end
    consume out

actor \nodoc\ _TestStreamingDecoder is TestList
  new make() =>
    None

  fun tag tests(test: PonyTest) =>
    // Roundtrip tests: encode then stream-decode
    test(_TestStreamDecodeNil)
    test(_TestStreamDecodeTrue)
    test(_TestStreamDecodeFalse)
    test(_TestStreamDecodePositiveFixint)
    test(_TestStreamDecodeNegativeFixint)
    test(_TestStreamDecodeU8)
    test(_TestStreamDecodeU16)
    test(_TestStreamDecodeU32)
    test(_TestStreamDecodeU64)
    test(_TestStreamDecodeI8)
    test(_TestStreamDecodeI16)
    test(_TestStreamDecodeI32)
    test(_TestStreamDecodeI64)
    test(_TestStreamDecodeF32)
    test(_TestStreamDecodeF64)
    test(_TestStreamDecodeFixstr)
    test(_TestStreamDecodeStr8)
    test(_TestStreamDecodeStr16)
    test(_TestStreamDecodeStr32)
    test(_TestStreamDecodeBin8)
    test(_TestStreamDecodeBin16)
    test(_TestStreamDecodeBin32)
    test(_TestStreamDecodeFixarray)
    test(_TestStreamDecodeArray16)
    test(_TestStreamDecodeArray32)
    test(_TestStreamDecodeFixmap)
    test(_TestStreamDecodeMap16)
    test(_TestStreamDecodeMap32)
    test(_TestStreamDecodeFixext1)
    test(_TestStreamDecodeFixext2)
    test(_TestStreamDecodeFixext4)
    test(_TestStreamDecodeFixext8)
    test(_TestStreamDecodeFixext16)
    test(_TestStreamDecodeExt8)
    test(_TestStreamDecodeExt16)
    test(_TestStreamDecodeExt32)
    // Timestamp tests
    test(_TestStreamTimestamp32)
    test(_TestStreamTimestamp64)
    test(_TestStreamTimestamp96)
    test(_TestStreamTimestampPartial)
    test(_TestStreamTimestamp64Partial)
    test(_TestStreamTimestamp96Partial)
    test(_TestStreamExt8NotTimestamp)
    // Streaming-specific tests
    test(_TestStreamEmptyReturnsNotEnoughData)
    test(_TestStreamInvalidFormatByte)
    test(_TestStreamMultipleValues)
    test(_TestStreamPartialU32)
    test(_TestStreamPartialStr8)
    test(_TestStreamPartialFixext4)
    test(_TestStreamPartialBin16)
    test(_TestStreamPartialExt8)
    test(_TestStreamPartialThenMultiple)
    // Property-based tests
    test(Property1UnitTest[U32](
      _PropertyStreamU32Safety))
    test(Property1UnitTest[I16](
      _PropertyStreamI16Safety))
    test(Property1UnitTest[String](
      _PropertyStreamStr8Safety))
    test(Property1UnitTest[U32](
      _PropertyStreamTimestamp32Safety))
    test(Property1UnitTest[U8](
      _PropertyStreamBin16Safety))
    test(Property1UnitTest[String](
      _PropertyStreamStr32Safety))
    test(Property1UnitTest[U8](
      _PropertyStreamFixext4Safety))
    // Limit tests
    test(_TestStreamLimitFixext)
    test(_TestStreamLimitMap)
    test(_TestStreamLimitArray32)
    test(_TestStreamLimitMap32)
    test(_TestStreamLimitStr16)
    test(_TestStreamLimitBin16)
    test(_TestStreamLimitExt16)
    test(_TestStreamLimitNoConsume)
    test(_TestStreamLimitUnlimited)
    test(_TestStreamLimitAtBoundary)
    // Limit property-based tests
    test(Property1UnitTest[String](
      _PropertyStreamLimitStr))
    test(Property1UnitTest[U8](
      _PropertyStreamLimitBin))
    test(Property1UnitTest[U16](
      _PropertyStreamLimitArray))
    test(Property1UnitTest[U8](
      _PropertyStreamLimitExt))
    // Depth limit tests
    test(_TestStreamDepthBasic)
    test(_TestStreamDepthExact)
    test(_TestStreamDepthAutoTrack)
    test(_TestStreamDepthMap)
    test(_TestStreamDepthMixed)
    test(_TestStreamDepthNoConsume)
    test(_TestStreamDepthUnlimited)
    test(_TestStreamDepthZero)
    test(_TestStreamDepthEmptyContainer)
    test(_TestStreamDepthDefault)
    // Depth property-based tests
    test(Property1UnitTest[U8](
      _PropertyStreamDepth))
    // Skip tests
    test(_TestStreamSkipNil)
    test(_TestStreamSkipStr)
    test(_TestStreamSkipFixarray)
    test(_TestStreamSkipArray32)
    test(_TestStreamSkipFixmap)
    test(_TestStreamSkipMap32)
    test(_TestStreamSkipNestedContainers)
    test(_TestStreamSkipEmptyContainers)
    test(_TestStreamSkipTimestamp)
    test(_TestStreamSkipNotEnoughData)
    test(_TestStreamSkipInvalidData)
    test(_TestStreamSkipLimitExceeded)
    test(_TestStreamSkipLimitNoConsume)
    test(_TestStreamSkipDepthTracking)
    test(_TestStreamSkipPositionPreserving)
    test(_TestStreamSkipInsideContainer)
    // Skip property-based tests
    test(Property1UnitTest[U32](
      _PropertyStreamSkipU32Safety))
    test(Property1UnitTest[I16](
      _PropertyStreamSkipI16Safety))
    test(Property1UnitTest[String](
      _PropertyStreamSkipStr8Safety))
    test(Property1UnitTest[U8](
      _PropertyStreamSkipFixext4Safety))
    test(Property1UnitTest[U8](
      _PropertyStreamSkipBin16Safety))
    test(Property1UnitTest[U16](
      _PropertyStreamSkipLimitArray))

//
// Roundtrip tests
//

class \nodoc\ _TestStreamDecodeNil is UnitTest
  fun name(): String => "msgpack/StreamDecodeNil"

  fun ref apply(h: TestHelper) =>
    let w: Writer ref = Writer
    MessagePackEncoder.nil(w)
    let sd = MessagePackStreamingDecoder
    sd.append(_WriterBytes(w))
    match sd.next()
    | None => None
    else h.fail("expected None")
    end

class \nodoc\ _TestStreamDecodeTrue is UnitTest
  fun name(): String => "msgpack/StreamDecodeTrue"

  fun ref apply(h: TestHelper) =>
    let w: Writer ref = Writer
    MessagePackEncoder.bool(w, true)
    let sd = MessagePackStreamingDecoder
    sd.append(_WriterBytes(w))
    match sd.next()
    | let v: Bool => h.assert_true(v)
    else h.fail("expected Bool true")
    end

class \nodoc\ _TestStreamDecodeFalse is UnitTest
  fun name(): String => "msgpack/StreamDecodeFalse"

  fun ref apply(h: TestHelper) =>
    let w: Writer ref = Writer
    MessagePackEncoder.bool(w, false)
    let sd = MessagePackStreamingDecoder
    sd.append(_WriterBytes(w))
    match sd.next()
    | let v: Bool => h.assert_false(v)
    else h.fail("expected Bool false")
    end

class \nodoc\ _TestStreamDecodePositiveFixint is UnitTest
  fun name(): String => "msgpack/StreamDecodePositiveFixint"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.positive_fixint(w, 42)?
    let sd = MessagePackStreamingDecoder
    sd.append(_WriterBytes(w))
    match sd.next()
    | let v: U8 => h.assert_eq[U8](42, v)
    else h.fail("expected U8")
    end

class \nodoc\ _TestStreamDecodeNegativeFixint is UnitTest
  fun name(): String => "msgpack/StreamDecodeNegativeFixint"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.negative_fixint(w, -17)?
    let sd = MessagePackStreamingDecoder
    sd.append(_WriterBytes(w))
    match sd.next()
    | let v: I8 => h.assert_eq[I8](-17, v)
    else h.fail("expected I8")
    end

class \nodoc\ _TestStreamDecodeU8 is UnitTest
  fun name(): String => "msgpack/StreamDecodeU8"

  fun ref apply(h: TestHelper) =>
    let w: Writer ref = Writer
    MessagePackEncoder.uint_8(w, 200)
    let sd = MessagePackStreamingDecoder
    sd.append(_WriterBytes(w))
    match sd.next()
    | let v: U8 => h.assert_eq[U8](200, v)
    else h.fail("expected U8")
    end

class \nodoc\ _TestStreamDecodeU16 is UnitTest
  fun name(): String => "msgpack/StreamDecodeU16"

  fun ref apply(h: TestHelper) =>
    let w: Writer ref = Writer
    MessagePackEncoder.uint_16(w, 5000)
    let sd = MessagePackStreamingDecoder
    sd.append(_WriterBytes(w))
    match sd.next()
    | let v: U16 => h.assert_eq[U16](5000, v)
    else h.fail("expected U16")
    end

class \nodoc\ _TestStreamDecodeU32 is UnitTest
  fun name(): String => "msgpack/StreamDecodeU32"

  fun ref apply(h: TestHelper) =>
    let w: Writer ref = Writer
    MessagePackEncoder.uint_32(w, 100000)
    let sd = MessagePackStreamingDecoder
    sd.append(_WriterBytes(w))
    match sd.next()
    | let v: U32 => h.assert_eq[U32](100000, v)
    else h.fail("expected U32")
    end

class \nodoc\ _TestStreamDecodeU64 is UnitTest
  fun name(): String => "msgpack/StreamDecodeU64"

  fun ref apply(h: TestHelper) =>
    let w: Writer ref = Writer
    MessagePackEncoder.uint_64(w, 1_000_000_000)
    let sd = MessagePackStreamingDecoder
    sd.append(_WriterBytes(w))
    match sd.next()
    | let v: U64 => h.assert_eq[U64](1_000_000_000, v)
    else h.fail("expected U64")
    end

class \nodoc\ _TestStreamDecodeI8 is UnitTest
  fun name(): String => "msgpack/StreamDecodeI8"

  fun ref apply(h: TestHelper) =>
    let w: Writer ref = Writer
    MessagePackEncoder.int_8(w, -50)
    let sd = MessagePackStreamingDecoder
    sd.append(_WriterBytes(w))
    match sd.next()
    | let v: I8 => h.assert_eq[I8](-50, v)
    else h.fail("expected I8")
    end

class \nodoc\ _TestStreamDecodeI16 is UnitTest
  fun name(): String => "msgpack/StreamDecodeI16"

  fun ref apply(h: TestHelper) =>
    let w: Writer ref = Writer
    MessagePackEncoder.int_16(w, -1000)
    let sd = MessagePackStreamingDecoder
    sd.append(_WriterBytes(w))
    match sd.next()
    | let v: I16 => h.assert_eq[I16](-1000, v)
    else h.fail("expected I16")
    end

class \nodoc\ _TestStreamDecodeI32 is UnitTest
  fun name(): String => "msgpack/StreamDecodeI32"

  fun ref apply(h: TestHelper) =>
    let w: Writer ref = Writer
    MessagePackEncoder.int_32(w, -70000)
    let sd = MessagePackStreamingDecoder
    sd.append(_WriterBytes(w))
    match sd.next()
    | let v: I32 => h.assert_eq[I32](-70000, v)
    else h.fail("expected I32")
    end

class \nodoc\ _TestStreamDecodeI64 is UnitTest
  fun name(): String => "msgpack/StreamDecodeI64"

  fun ref apply(h: TestHelper) =>
    let w: Writer ref = Writer
    MessagePackEncoder.int_64(w, -5_000_000_000)
    let sd = MessagePackStreamingDecoder
    sd.append(_WriterBytes(w))
    match sd.next()
    | let v: I64 => h.assert_eq[I64](-5_000_000_000, v)
    else h.fail("expected I64")
    end

class \nodoc\ _TestStreamDecodeF32 is UnitTest
  fun name(): String => "msgpack/StreamDecodeF32"

  fun ref apply(h: TestHelper) =>
    let w: Writer ref = Writer
    MessagePackEncoder.float_32(w, 33.33)
    let sd = MessagePackStreamingDecoder
    sd.append(_WriterBytes(w))
    match sd.next()
    | let v: F32 => h.assert_eq[F32](33.33, v)
    else h.fail("expected F32")
    end

class \nodoc\ _TestStreamDecodeF64 is UnitTest
  fun name(): String => "msgpack/StreamDecodeF64"

  fun ref apply(h: TestHelper) =>
    let w: Writer ref = Writer
    MessagePackEncoder.float_64(w, 65.65)
    let sd = MessagePackStreamingDecoder
    sd.append(_WriterBytes(w))
    match sd.next()
    | let v: F64 => h.assert_eq[F64](65.65, v)
    else h.fail("expected F64")
    end

class \nodoc\ _TestStreamDecodeFixstr is UnitTest
  fun name(): String => "msgpack/StreamDecodeFixstr"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.fixstr(w, "hello")?
    let sd = MessagePackStreamingDecoder
    sd.append(_WriterBytes(w))
    match sd.next()
    | let v: String val => h.assert_eq[String]("hello", v)
    else h.fail("expected String")
    end

class \nodoc\ _TestStreamDecodeStr8 is UnitTest
  fun name(): String => "msgpack/StreamDecodeStr8"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.str_8(w, "str8")?
    let sd = MessagePackStreamingDecoder
    sd.append(_WriterBytes(w))
    match sd.next()
    | let v: String val => h.assert_eq[String]("str8", v)
    else h.fail("expected String")
    end

class \nodoc\ _TestStreamDecodeStr16 is UnitTest
  fun name(): String => "msgpack/StreamDecodeStr16"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.str_16(w, "str16")?
    let sd = MessagePackStreamingDecoder
    sd.append(_WriterBytes(w))
    match sd.next()
    | let v: String val => h.assert_eq[String]("str16", v)
    else h.fail("expected String")
    end

class \nodoc\ _TestStreamDecodeStr32 is UnitTest
  fun name(): String => "msgpack/StreamDecodeStr32"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.str_32(w, "str32")?
    let sd = MessagePackStreamingDecoder
    sd.append(_WriterBytes(w))
    match sd.next()
    | let v: String val => h.assert_eq[String]("str32", v)
    else h.fail("expected String")
    end

class \nodoc\ _TestStreamDecodeBin8 is UnitTest
  fun name(): String => "msgpack/StreamDecodeBin8"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    let value = recover val [as U8: 'H'; 'e'; 'l'; 'l'; 'o'] end
    MessagePackEncoder.bin_8(w, value)?
    let sd = MessagePackStreamingDecoder
    sd.append(_WriterBytes(w))
    match sd.next()
    | let v: Array[U8] val =>
      h.assert_eq[USize](5, v.size())
      h.assert_eq[U8]('H', v(0)?)
      h.assert_eq[U8]('o', v(4)?)
    else h.fail("expected Array[U8]")
    end

class \nodoc\ _TestStreamDecodeBin16 is UnitTest
  fun name(): String => "msgpack/StreamDecodeBin16"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    let value = recover val [as U8: 'H'; 'e'; 'l'; 'l'; 'o'] end
    MessagePackEncoder.bin_16(w, value)?
    let sd = MessagePackStreamingDecoder
    sd.append(_WriterBytes(w))
    match sd.next()
    | let v: Array[U8] val =>
      h.assert_eq[USize](5, v.size())
      h.assert_eq[U8]('H', v(0)?)
      h.assert_eq[U8]('o', v(4)?)
    else h.fail("expected Array[U8]")
    end

class \nodoc\ _TestStreamDecodeBin32 is UnitTest
  fun name(): String => "msgpack/StreamDecodeBin32"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    let value = recover val [as U8: 'H'; 'e'; 'l'; 'l'; 'o'] end
    MessagePackEncoder.bin_32(w, value)?
    let sd = MessagePackStreamingDecoder
    sd.append(_WriterBytes(w))
    match sd.next()
    | let v: Array[U8] val =>
      h.assert_eq[USize](5, v.size())
      h.assert_eq[U8]('H', v(0)?)
      h.assert_eq[U8]('o', v(4)?)
    else h.fail("expected Array[U8]")
    end

class \nodoc\ _TestStreamDecodeFixarray is UnitTest
  fun name(): String => "msgpack/StreamDecodeFixarray"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.fixarray(w, 8)?
    let sd = MessagePackStreamingDecoder
    sd.append(_WriterBytes(w))
    match sd.next()
    | let v: MessagePackArray =>
      h.assert_eq[U32](8, v.size)
    else h.fail("expected MessagePackArray")
    end

class \nodoc\ _TestStreamDecodeArray16 is UnitTest
  fun name(): String => "msgpack/StreamDecodeArray16"

  fun ref apply(h: TestHelper) =>
    let w: Writer ref = Writer
    MessagePackEncoder.array_16(w, 300)
    let sd = MessagePackStreamingDecoder
    sd.append(_WriterBytes(w))
    match sd.next()
    | let v: MessagePackArray =>
      h.assert_eq[U32](300, v.size)
    else h.fail("expected MessagePackArray")
    end

class \nodoc\ _TestStreamDecodeArray32 is UnitTest
  fun name(): String => "msgpack/StreamDecodeArray32"

  fun ref apply(h: TestHelper) =>
    let w: Writer ref = Writer
    MessagePackEncoder.array_32(w, 70000)
    let sd = MessagePackStreamingDecoder
    sd.append(_WriterBytes(w))
    match sd.next()
    | let v: MessagePackArray =>
      h.assert_eq[U32](70000, v.size)
    else h.fail("expected MessagePackArray")
    end

class \nodoc\ _TestStreamDecodeFixmap is UnitTest
  fun name(): String => "msgpack/StreamDecodeFixmap"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.fixmap(w, 5)?
    let sd = MessagePackStreamingDecoder
    sd.append(_WriterBytes(w))
    match sd.next()
    | let v: MessagePackMap =>
      h.assert_eq[U32](5, v.size)
    else h.fail("expected MessagePackMap")
    end

class \nodoc\ _TestStreamDecodeMap16 is UnitTest
  fun name(): String => "msgpack/StreamDecodeMap16"

  fun ref apply(h: TestHelper) =>
    let w: Writer ref = Writer
    MessagePackEncoder.map_16(w, 400)
    let sd = MessagePackStreamingDecoder
    sd.append(_WriterBytes(w))
    match sd.next()
    | let v: MessagePackMap =>
      h.assert_eq[U32](400, v.size)
    else h.fail("expected MessagePackMap")
    end

class \nodoc\ _TestStreamDecodeMap32 is UnitTest
  fun name(): String => "msgpack/StreamDecodeMap32"

  fun ref apply(h: TestHelper) =>
    let w: Writer ref = Writer
    MessagePackEncoder.map_32(w, 80000)
    let sd = MessagePackStreamingDecoder
    sd.append(_WriterBytes(w))
    match sd.next()
    | let v: MessagePackMap =>
      h.assert_eq[U32](80000, v.size)
    else h.fail("expected MessagePackMap")
    end

class \nodoc\ _TestStreamDecodeFixext1 is UnitTest
  fun name(): String => "msgpack/StreamDecodeFixext1"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    let value = recover val [as U8: 'X'] end
    MessagePackEncoder.fixext_1(w, 8, value)?
    let sd = MessagePackStreamingDecoder
    sd.append(_WriterBytes(w))
    match sd.next()
    | let v: MessagePackExt =>
      h.assert_eq[U8](8, v.ext_type)
      h.assert_eq[USize](1, v.data.size())
      h.assert_eq[U8]('X', v.data(0)?)
    else h.fail("expected MessagePackExt")
    end

class \nodoc\ _TestStreamDecodeFixext2 is UnitTest
  fun name(): String => "msgpack/StreamDecodeFixext2"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    let value = recover val [as U8: 'A'; 'B'] end
    MessagePackEncoder.fixext_2(w, 12, value)?
    let sd = MessagePackStreamingDecoder
    sd.append(_WriterBytes(w))
    match sd.next()
    | let v: MessagePackExt =>
      h.assert_eq[U8](12, v.ext_type)
      h.assert_eq[USize](2, v.data.size())
      h.assert_eq[U8]('A', v.data(0)?)
      h.assert_eq[U8]('B', v.data(1)?)
    else h.fail("expected MessagePackExt")
    end

class \nodoc\ _TestStreamDecodeFixext4 is UnitTest
  fun name(): String => "msgpack/StreamDecodeFixext4"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    let value = recover val Array[U8].init('V', 4) end
    MessagePackEncoder.fixext_4(w, 20, value)?
    let sd = MessagePackStreamingDecoder
    sd.append(_WriterBytes(w))
    match sd.next()
    | let v: MessagePackExt =>
      h.assert_eq[U8](20, v.ext_type)
      h.assert_eq[USize](4, v.data.size())
    else h.fail("expected MessagePackExt")
    end

class \nodoc\ _TestStreamDecodeFixext8 is UnitTest
  fun name(): String => "msgpack/StreamDecodeFixext8"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    let value = recover val Array[U8].init('V', 8) end
    MessagePackEncoder.fixext_8(w, 30, value)?
    let sd = MessagePackStreamingDecoder
    sd.append(_WriterBytes(w))
    match sd.next()
    | let v: MessagePackExt =>
      h.assert_eq[U8](30, v.ext_type)
      h.assert_eq[USize](8, v.data.size())
    else h.fail("expected MessagePackExt")
    end

class \nodoc\ _TestStreamDecodeFixext16 is UnitTest
  fun name(): String => "msgpack/StreamDecodeFixext16"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    let value = recover val Array[U8].init('V', 16) end
    MessagePackEncoder.fixext_16(w, 40, value)?
    let sd = MessagePackStreamingDecoder
    sd.append(_WriterBytes(w))
    match sd.next()
    | let v: MessagePackExt =>
      h.assert_eq[U8](40, v.ext_type)
      h.assert_eq[USize](16, v.data.size())
    else h.fail("expected MessagePackExt")
    end

class \nodoc\ _TestStreamDecodeExt8 is UnitTest
  fun name(): String => "msgpack/StreamDecodeExt8"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    let value = recover val [as U8: 'Y'; 'e'; 'l'; 'l'; 'o'] end
    MessagePackEncoder.ext_8(w, 18, value)?
    let sd = MessagePackStreamingDecoder
    sd.append(_WriterBytes(w))
    match sd.next()
    | let v: MessagePackExt =>
      h.assert_eq[U8](18, v.ext_type)
      h.assert_eq[USize](5, v.data.size())
      h.assert_eq[U8]('Y', v.data(0)?)
      h.assert_eq[U8]('o', v.data(4)?)
    else h.fail("expected MessagePackExt")
    end

class \nodoc\ _TestStreamDecodeExt16 is UnitTest
  fun name(): String => "msgpack/StreamDecodeExt16"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    let value = recover val [as U8: 'H'; 'e'; 'l'; 'l'; 'o'] end
    MessagePackEncoder.ext_16(w, 99, value)?
    let sd = MessagePackStreamingDecoder
    sd.append(_WriterBytes(w))
    match sd.next()
    | let v: MessagePackExt =>
      h.assert_eq[U8](99, v.ext_type)
      h.assert_eq[USize](5, v.data.size())
      h.assert_eq[U8]('H', v.data(0)?)
    else h.fail("expected MessagePackExt")
    end

class \nodoc\ _TestStreamDecodeExt32 is UnitTest
  fun name(): String => "msgpack/StreamDecodeExt32"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    let value = recover val [as U8: 'Y'; 'e'; 'x'; 'x'; 'o'] end
    MessagePackEncoder.ext_32(w, 127, value)?
    let sd = MessagePackStreamingDecoder
    sd.append(_WriterBytes(w))
    match sd.next()
    | let v: MessagePackExt =>
      h.assert_eq[U8](127, v.ext_type)
      h.assert_eq[USize](5, v.data.size())
      h.assert_eq[U8]('Y', v.data(0)?)
    else h.fail("expected MessagePackExt")
    end

//
// Streaming-specific tests
//

class \nodoc\ _TestStreamEmptyReturnsNotEnoughData is UnitTest
  fun name(): String => "msgpack/StreamEmptyReturnsNotEnoughData"

  fun ref apply(h: TestHelper) =>
    let sd = MessagePackStreamingDecoder
    match sd.next()
    | NotEnoughData => None
    else h.fail("expected NotEnoughData on empty reader")
    end

class \nodoc\ _TestStreamInvalidFormatByte is UnitTest
  fun name(): String => "msgpack/StreamInvalidFormatByte"

  fun ref apply(h: TestHelper) =>
    let sd = MessagePackStreamingDecoder
    // 0xC1 is the unused/invalid format byte
    sd.append(recover val [as U8: 0xC1] end)
    match sd.next()
    | InvalidData => None
    else h.fail("expected InvalidData for 0xC1")
    end

    // Calling next() again returns InvalidData again since
    // the invalid byte is not consumed
    match sd.next()
    | InvalidData => None
    else h.fail("expected InvalidData on repeated call")
    end

class \nodoc\ _TestStreamMultipleValues is UnitTest
  fun name(): String => "msgpack/StreamMultipleValues"

  fun ref apply(h: TestHelper) =>
    let w: Writer ref = Writer
    MessagePackEncoder.nil(w)
    MessagePackEncoder.bool(w, true)
    MessagePackEncoder.uint_32(w, 42)
    let sd = MessagePackStreamingDecoder
    sd.append(_WriterBytes(w))

    // First value: nil
    match sd.next()
    | None => None
    else h.fail("expected None")
    end

    // Second value: true
    match sd.next()
    | let v: Bool => h.assert_true(v)
    else h.fail("expected Bool true")
    end

    // Third value: U32
    match sd.next()
    | let v: U32 => h.assert_eq[U32](42, v)
    else h.fail("expected U32")
    end

    // Fourth call: no more data
    match sd.next()
    | NotEnoughData => None
    else h.fail("expected NotEnoughData after all values consumed")
    end

class \nodoc\ _TestStreamPartialU32 is UnitTest
  """
  Feed a uint_32 one byte at a time. Verify NotEnoughData until
  all 5 bytes (1 type + 4 value) arrive, then verify the decoded
  value.
  """
  fun name(): String => "msgpack/StreamPartialU32"

  fun ref apply(h: TestHelper) =>
    let w: Writer ref = Writer
    MessagePackEncoder.uint_32(w, 12345)
    let bytes = _WriterBytes(w)
    let sd = MessagePackStreamingDecoder

    // Feed one byte at a time; all but the last should give
    // NotEnoughData
    var i: USize = 0
    while i < (bytes.size() - 1) do
      try
        sd.append(
          recover val [as U8: bytes(i)?] end)
      end
      match sd.next()
      | NotEnoughData => None
      else
        h.fail("expected NotEnoughData at byte " + i.string())
        return
      end
      i = i + 1
    end

    // Feed the last byte
    try
      sd.append(
        recover val [as U8: bytes(bytes.size() - 1)?] end)
    end

    match sd.next()
    | let v: U32 => h.assert_eq[U32](12345, v)
    else h.fail("expected U32 after all bytes fed")
    end

class \nodoc\ _TestStreamPartialStr8 is UnitTest
  """
  Feed a str_8 encoded string in two chunks: first the header,
  then the payload. Verify NotEnoughData on partial, then the
  full string.
  """
  fun name(): String => "msgpack/StreamPartialStr8"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.str_8(w, "hello")?
    let bytes = _WriterBytes(w)
    let sd = MessagePackStreamingDecoder

    // Feed just the header (format byte + length byte = 2 bytes)
    sd.append(recover val [as U8: bytes(0)?; bytes(1)?] end)
    match sd.next()
    | NotEnoughData => None
    else h.fail("expected NotEnoughData with only header")
    end

    // Feed the string payload
    let payload = recover iso Array[U8] end
    var i: USize = 2
    while i < bytes.size() do
      payload.push(bytes(i)?)
      i = i + 1
    end
    sd.append(consume payload)

    match sd.next()
    | let v: String val => h.assert_eq[String]("hello", v)
    else h.fail("expected String")
    end

class \nodoc\ _TestStreamPartialFixext4 is UnitTest
  """
  Feed a fixext_4 in two parts: format + type bytes, then data.
  """
  fun name(): String => "msgpack/StreamPartialFixext4"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    let value = recover val [as U8: 'A'; 'B'; 'C'; 'D'] end
    MessagePackEncoder.fixext_4(w, 7, value)?
    let bytes = _WriterBytes(w)
    let sd = MessagePackStreamingDecoder

    // Feed first 2 bytes (format + type), need 6 total
    sd.append(recover val [as U8: bytes(0)?; bytes(1)?] end)
    match sd.next()
    | NotEnoughData => None
    else h.fail("expected NotEnoughData")
    end

    // Feed remaining bytes
    let rest = recover iso Array[U8] end
    var i: USize = 2
    while i < bytes.size() do
      rest.push(bytes(i)?)
      i = i + 1
    end
    sd.append(consume rest)

    match sd.next()
    | let v: MessagePackExt =>
      h.assert_eq[U8](7, v.ext_type)
      h.assert_eq[USize](4, v.data.size())
      h.assert_eq[U8]('A', v.data(0)?)
    else h.fail("expected MessagePackExt")
    end

class \nodoc\ _TestStreamPartialBin16 is UnitTest
  """
  Feed a bin_16 in stages: format byte alone, then length bytes,
  then payload.
  """
  fun name(): String => "msgpack/StreamPartialBin16"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    let value = recover val [as U8: 1; 2; 3; 4; 5] end
    MessagePackEncoder.bin_16(w, value)?
    let bytes = _WriterBytes(w)
    let sd = MessagePackStreamingDecoder

    // Feed just the format byte
    sd.append(recover val [as U8: bytes(0)?] end)
    match sd.next()
    | NotEnoughData => None
    else h.fail("expected NotEnoughData with just format byte")
    end

    // Feed the 2 length bytes
    sd.append(
      recover val [as U8: bytes(1)?; bytes(2)?] end)
    match sd.next()
    | NotEnoughData => None
    else h.fail("expected NotEnoughData with header but no data")
    end

    // Feed the payload
    let payload = recover iso Array[U8] end
    var i: USize = 3
    while i < bytes.size() do
      payload.push(bytes(i)?)
      i = i + 1
    end
    sd.append(consume payload)

    match sd.next()
    | let v: Array[U8] val =>
      h.assert_eq[USize](5, v.size())
      h.assert_eq[U8](1, v(0)?)
      h.assert_eq[U8](5, v(4)?)
    else h.fail("expected Array[U8]")
    end

class \nodoc\ _TestStreamPartialExt8 is UnitTest
  """
  Feed an ext_8 in stages: format byte, then length + type, then
  payload.
  """
  fun name(): String => "msgpack/StreamPartialExt8"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    let value = recover val [as U8: 10; 20; 30] end
    MessagePackEncoder.ext_8(w, 55, value)?
    let bytes = _WriterBytes(w)
    let sd = MessagePackStreamingDecoder

    // Feed just the format byte
    sd.append(recover val [as U8: bytes(0)?] end)
    match sd.next()
    | NotEnoughData => None
    else h.fail("expected NotEnoughData with just format byte")
    end

    // Feed length byte and type byte
    sd.append(
      recover val [as U8: bytes(1)?; bytes(2)?] end)
    match sd.next()
    | NotEnoughData => None
    else h.fail("expected NotEnoughData without payload")
    end

    // Feed the payload
    let payload = recover iso Array[U8] end
    var i: USize = 3
    while i < bytes.size() do
      payload.push(bytes(i)?)
      i = i + 1
    end
    sd.append(consume payload)

    match sd.next()
    | let v: MessagePackExt =>
      h.assert_eq[U8](55, v.ext_type)
      h.assert_eq[USize](3, v.data.size())
      h.assert_eq[U8](10, v.data(0)?)
    else h.fail("expected MessagePackExt")
    end

class \nodoc\ _TestStreamPartialThenMultiple is UnitTest
  """
  Feed a partial uint_32, get NotEnoughData, then feed the
  remainder plus a complete nil in one chunk. Verify both
  values decode correctly.
  """
  fun name(): String => "msgpack/StreamPartialThenMultiple"

  fun ref apply(h: TestHelper) ? =>
    // Encode uint_32 followed by nil
    let w: Writer ref = Writer
    MessagePackEncoder.uint_32(w, 99999)
    MessagePackEncoder.nil(w)
    let bytes = _WriterBytes(w)

    // Total should be 6 bytes: 5 (uint_32) + 1 (nil)
    h.assert_eq[USize](6, bytes.size())

    let sd = MessagePackStreamingDecoder

    // Feed first 3 bytes (partial uint_32)
    sd.append(
      recover val [as U8: bytes(0)?; bytes(1)?; bytes(2)?] end)
    match sd.next()
    | NotEnoughData => None
    else h.fail("expected NotEnoughData on partial uint_32")
    end

    // Feed remaining 3 bytes (rest of uint_32 + nil)
    sd.append(
      recover val
        [as U8: bytes(3)?; bytes(4)?; bytes(5)?]
      end)

    // Decode the uint_32
    match sd.next()
    | let v: U32 => h.assert_eq[U32](99999, v)
    else h.fail("expected U32")
    end

    // Decode the nil
    match sd.next()
    | None => None
    else h.fail("expected None (nil)")
    end

//
// Timestamp tests
//

class \nodoc\ _TestStreamTimestamp32 is UnitTest
  fun name(): String => "msgpack/StreamTimestamp32"

  fun ref apply(h: TestHelper) =>
    let w: Writer ref = Writer
    MessagePackEncoder.timestamp_32(w, 500)
    let sd = MessagePackStreamingDecoder
    sd.append(_WriterBytes(w))
    match sd.next()
    | let v: MessagePackTimestamp =>
      h.assert_eq[I64](500, v.sec)
      h.assert_eq[U32](0, v.nsec)
    else h.fail("expected MessagePackTimestamp")
    end

class \nodoc\ _TestStreamTimestamp64 is UnitTest
  fun name(): String => "msgpack/StreamTimestamp64"

  fun ref apply(h: TestHelper) ? =>
    let sec = U64(_Limit.sec_34())
    let nsec = U32(_Limit.nsec())
    let w: Writer ref = Writer
    MessagePackEncoder.timestamp_64(w, sec, nsec)?
    let sd = MessagePackStreamingDecoder
    sd.append(_WriterBytes(w))
    match sd.next()
    | let v: MessagePackTimestamp =>
      h.assert_eq[I64](_Limit.sec_34().i64(), v.sec)
      h.assert_eq[U32](_Limit.nsec(), v.nsec)
    else h.fail("expected MessagePackTimestamp")
    end

class \nodoc\ _TestStreamTimestamp96 is UnitTest
  fun name(): String => "msgpack/StreamTimestamp96"

  fun ref apply(h: TestHelper) ? =>
    let sec = 0 - _Limit.sec_34().i64()
    let nsec = _Limit.nsec()
    let w: Writer ref = Writer
    MessagePackEncoder.timestamp_96(w, sec, nsec)?
    let sd = MessagePackStreamingDecoder
    sd.append(_WriterBytes(w))
    match sd.next()
    | let v: MessagePackTimestamp =>
      h.assert_eq[I64](sec, v.sec)
      h.assert_eq[U32](nsec, v.nsec)
    else h.fail("expected MessagePackTimestamp")
    end

class \nodoc\ _TestStreamTimestampPartial is UnitTest
  """
  Feed a timestamp_32 one byte at a time. Verify NotEnoughData
  until all 6 bytes arrive, then verify the decoded timestamp.
  """
  fun name(): String => "msgpack/StreamTimestampPartial"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.timestamp_32(w, 1000)
    let bytes = _WriterBytes(w)
    let sd = MessagePackStreamingDecoder

    var i: USize = 0
    while i < (bytes.size() - 1) do
      sd.append(
        recover val [as U8: bytes(i)?] end)
      match sd.next()
      | NotEnoughData => None
      else
        h.fail(
          "expected NotEnoughData at byte "
            + i.string())
        return
      end
      i = i + 1
    end

    sd.append(
      recover val
        [as U8: bytes(bytes.size() - 1)?]
      end)

    match sd.next()
    | let v: MessagePackTimestamp =>
      h.assert_eq[I64](1000, v.sec)
      h.assert_eq[U32](0, v.nsec)
    else h.fail("expected MessagePackTimestamp")
    end

class \nodoc\ _TestStreamTimestamp64Partial is UnitTest
  """
  Feed a timestamp_64 one byte at a time. Exercises the fixext_8
  path (10 bytes) through _decode_fixext timestamp detection.
  """
  fun name(): String => "msgpack/StreamTimestamp64Partial"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.timestamp_64(w, 500, 100)?
    let bytes = _WriterBytes(w)
    let sd = MessagePackStreamingDecoder

    var i: USize = 0
    while i < (bytes.size() - 1) do
      sd.append(
        recover val [as U8: bytes(i)?] end)
      match sd.next()
      | NotEnoughData => None
      else
        h.fail(
          "expected NotEnoughData at byte "
            + i.string())
        return
      end
      i = i + 1
    end

    sd.append(
      recover val
        [as U8: bytes(bytes.size() - 1)?]
      end)

    match sd.next()
    | let v: MessagePackTimestamp =>
      h.assert_eq[I64](500, v.sec)
      h.assert_eq[U32](100, v.nsec)
    else h.fail("expected MessagePackTimestamp")
    end

class \nodoc\ _TestStreamTimestamp96Partial is UnitTest
  """
  Feed a timestamp_96 one byte at a time. Exercises the ext_8
  path (15 bytes) through _decode_ext_variable timestamp detection.
  """
  fun name(): String => "msgpack/StreamTimestamp96Partial"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.timestamp_96(w, -1000, 500)?
    let bytes = _WriterBytes(w)
    let sd = MessagePackStreamingDecoder

    var i: USize = 0
    while i < (bytes.size() - 1) do
      sd.append(
        recover val [as U8: bytes(i)?] end)
      match sd.next()
      | NotEnoughData => None
      else
        h.fail(
          "expected NotEnoughData at byte "
            + i.string())
        return
      end
      i = i + 1
    end

    sd.append(
      recover val
        [as U8: bytes(bytes.size() - 1)?]
      end)

    match sd.next()
    | let v: MessagePackTimestamp =>
      h.assert_eq[I64](-1000, v.sec)
      h.assert_eq[U32](500, v.nsec)
    else h.fail("expected MessagePackTimestamp")
    end

class \nodoc\ _TestStreamExt8NotTimestamp is UnitTest
  """
  An ext_8 with data_len=12 but ext_type != 0xFF should decode
  as MessagePackExt, not MessagePackTimestamp.
  """
  fun name(): String => "msgpack/StreamExt8NotTimestamp"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    let value = recover val Array[U8].init('Z', 12) end
    MessagePackEncoder.ext_8(w, 42, value)?
    let sd = MessagePackStreamingDecoder
    sd.append(_WriterBytes(w))
    match sd.next()
    | let v: MessagePackExt =>
      h.assert_eq[U8](42, v.ext_type)
      h.assert_eq[USize](12, v.data.size())
    else h.fail("expected MessagePackExt, not timestamp")
    end

//
// Property-based tests
//

class \nodoc\ _PropertyStreamU32Safety is Property1[U32]
  """
  For any U32, encoding as uint_32 and feeding to the streaming
  decoder byte-by-byte yields NotEnoughData for all partial
  feeds and the correct value once complete.
  """
  fun name(): String =>
    "msgpack/PropertyStreamU32Safety"

  fun gen(): Generator[U32] =>
    Generators.u32()

  fun ref property(arg1: U32, h: PropertyHelper) ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.uint_32(w, arg1)
    let bytes = _WriterBytes(w)
    let sd = MessagePackStreamingDecoder

    var i: USize = 0
    while i < (bytes.size() - 1) do
      sd.append(
        recover val [as U8: bytes(i)?] end)
      match sd.next()
      | NotEnoughData => None
      else
        h.fail(
          "NotEnoughData expected at byte "
            + i.string())
        return
      end
      i = i + 1
    end

    sd.append(
      recover val
        [as U8: bytes(bytes.size() - 1)?]
      end)

    match sd.next()
    | let v: U32 =>
      h.assert_eq[U32](arg1, v)
    else
      h.fail("expected U32")
    end

class \nodoc\ _PropertyStreamI16Safety is Property1[I16]
  """
  For any I16, encoding as int_16 and feeding to the streaming
  decoder byte-by-byte yields NotEnoughData for all partial
  feeds and the correct value once complete.
  """
  fun name(): String =>
    "msgpack/PropertyStreamI16Safety"

  fun gen(): Generator[I16] =>
    Generators.i16()

  fun ref property(arg1: I16, h: PropertyHelper) ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.int_16(w, arg1)
    let bytes = _WriterBytes(w)
    let sd = MessagePackStreamingDecoder

    var i: USize = 0
    while i < (bytes.size() - 1) do
      sd.append(
        recover val [as U8: bytes(i)?] end)
      match sd.next()
      | NotEnoughData => None
      else
        h.fail(
          "NotEnoughData expected at byte "
            + i.string())
        return
      end
      i = i + 1
    end

    sd.append(
      recover val
        [as U8: bytes(bytes.size() - 1)?]
      end)

    match sd.next()
    | let v: I16 =>
      h.assert_eq[I16](arg1, v)
    else
      h.fail("expected I16")
    end

class \nodoc\ _PropertyStreamStr8Safety is Property1[String]
  """
  For any short ASCII string, encoding as str_8 and feeding to
  the streaming decoder byte-by-byte yields NotEnoughData for
  all partial feeds and the correct string once complete.
  """
  fun name(): String =>
    "msgpack/PropertyStreamStr8Safety"

  fun gen(): Generator[String] =>
    Generators.ascii_printable(0, 100)

  fun ref property(arg1: String, h: PropertyHelper) ? =>
    let s: String val = arg1.clone()
    let w: Writer ref = Writer
    MessagePackEncoder.str_8(w, s)?
    let bytes = _WriterBytes(w)
    let sd = MessagePackStreamingDecoder

    var i: USize = 0
    while i < (bytes.size() - 1) do
      sd.append(
        recover val [as U8: bytes(i)?] end)
      match sd.next()
      | NotEnoughData => None
      else
        h.fail(
          "NotEnoughData expected at byte "
            + i.string())
        return
      end
      i = i + 1
    end

    sd.append(
      recover val
        [as U8: bytes(bytes.size() - 1)?]
      end)

    match sd.next()
    | let v: String val =>
      h.assert_eq[String](s, v)
    else
      h.fail("expected String")
    end

class \nodoc\ _PropertyStreamTimestamp32Safety
  is Property1[U32]
  """
  For any U32, encoding as timestamp_32 and feeding to the
  streaming decoder byte-by-byte yields NotEnoughData for all
  partial feeds and a correct MessagePackTimestamp once complete.
  """
  fun name(): String =>
    "msgpack/PropertyStreamTimestamp32Safety"

  fun gen(): Generator[U32] =>
    Generators.u32()

  fun ref property(arg1: U32, h: PropertyHelper) ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.timestamp_32(w, arg1)
    let bytes = _WriterBytes(w)
    let sd = MessagePackStreamingDecoder

    var i: USize = 0
    while i < (bytes.size() - 1) do
      sd.append(
        recover val [as U8: bytes(i)?] end)
      match sd.next()
      | NotEnoughData => None
      else
        h.fail(
          "NotEnoughData expected at byte "
            + i.string())
        return
      end
      i = i + 1
    end

    sd.append(
      recover val
        [as U8: bytes(bytes.size() - 1)?]
      end)

    match sd.next()
    | let v: MessagePackTimestamp =>
      h.assert_eq[I64](arg1.i64(), v.sec)
      h.assert_eq[U32](0, v.nsec)
    else
      h.fail("expected MessagePackTimestamp")
    end

class \nodoc\ _PropertyStreamBin16Safety is Property1[U8]
  """
  For any small byte array, encoding as bin_16 and feeding to
  the streaming decoder byte-by-byte yields NotEnoughData for
  all partial feeds and the correct array once complete.
  Exercises the peek_u16_be length-reading path.
  """
  fun name(): String =>
    "msgpack/PropertyStreamBin16Safety"

  fun gen(): Generator[U8] =>
    Generators.u8()

  fun ref property(arg1: U8, h: PropertyHelper) ? =>
    let data = recover val
      Array[U8].init('X', arg1.usize())
    end
    let w: Writer ref = Writer
    MessagePackEncoder.bin_16(w, data)?
    let bytes = _WriterBytes(w)
    let sd = MessagePackStreamingDecoder

    var i: USize = 0
    while i < (bytes.size() - 1) do
      sd.append(
        recover val [as U8: bytes(i)?] end)
      match sd.next()
      | NotEnoughData => None
      else
        h.fail(
          "NotEnoughData expected at byte "
            + i.string())
        return
      end
      i = i + 1
    end

    sd.append(
      recover val
        [as U8: bytes(bytes.size() - 1)?]
      end)

    match sd.next()
    | let v: Array[U8] val =>
      h.assert_eq[USize](arg1.usize(), v.size())
    else
      h.fail("expected Array[U8]")
    end

class \nodoc\ _PropertyStreamStr32Safety
  is Property1[String]
  """
  For any short ASCII string, encoding as str_32 and feeding to
  the streaming decoder byte-by-byte yields NotEnoughData for
  all partial feeds and the correct string once complete.
  Exercises the peek_u32_be length-reading path.
  """
  fun name(): String =>
    "msgpack/PropertyStreamStr32Safety"

  fun gen(): Generator[String] =>
    Generators.ascii_printable(0, 50)

  fun ref property(arg1: String, h: PropertyHelper) ? =>
    let s: String val = arg1.clone()
    let w: Writer ref = Writer
    MessagePackEncoder.str_32(w, s)?
    let bytes = _WriterBytes(w)
    let sd = MessagePackStreamingDecoder

    var i: USize = 0
    while i < (bytes.size() - 1) do
      sd.append(
        recover val [as U8: bytes(i)?] end)
      match sd.next()
      | NotEnoughData => None
      else
        h.fail(
          "NotEnoughData expected at byte "
            + i.string())
        return
      end
      i = i + 1
    end

    sd.append(
      recover val
        [as U8: bytes(bytes.size() - 1)?]
      end)

    match sd.next()
    | let v: String val =>
      h.assert_eq[String](s, v)
    else
      h.fail("expected String")
    end

class \nodoc\ _PropertyStreamFixext4Safety is Property1[U8]
  """
  For any ext_type byte, encoding a fixext_4 and feeding to the
  streaming decoder byte-by-byte yields NotEnoughData for all
  partial feeds and the correct type once complete. When ext_type
  is 0xFF, the result should be a MessagePackTimestamp; otherwise,
  a MessagePackExt.
  """
  fun name(): String =>
    "msgpack/PropertyStreamFixext4Safety"

  fun gen(): Generator[U8] =>
    Generators.u8()

  fun ref property(arg1: U8, h: PropertyHelper) ? =>
    let data = recover val [as U8: 'A'; 'B'; 'C'; 'D'] end
    let w: Writer ref = Writer
    if arg1 == 0xFF then
      MessagePackEncoder.timestamp_32(w, 1000)
    else
      MessagePackEncoder.fixext_4(w, arg1, data)?
    end
    let bytes = _WriterBytes(w)
    let sd = MessagePackStreamingDecoder

    var i: USize = 0
    while i < (bytes.size() - 1) do
      sd.append(
        recover val [as U8: bytes(i)?] end)
      match sd.next()
      | NotEnoughData => None
      else
        h.fail(
          "NotEnoughData expected at byte "
            + i.string())
        return
      end
      i = i + 1
    end

    sd.append(
      recover val
        [as U8: bytes(bytes.size() - 1)?]
      end)

    if arg1 == 0xFF then
      match sd.next()
      | let v: MessagePackTimestamp =>
        h.assert_eq[I64](1000, v.sec)
      else
        h.fail("expected MessagePackTimestamp")
      end
    else
      match sd.next()
      | let v: MessagePackExt =>
        h.assert_eq[U8](arg1, v.ext_type)
        h.assert_eq[USize](4, v.data.size())
      else
        h.fail("expected MessagePackExt")
      end
    end

//
// Limit tests
//

class \nodoc\ _TestStreamLimitFixext is UnitTest
  """
  A fixext_16 (16 bytes data) is rejected when max_ext_len is 15.
  """
  fun name(): String => "msgpack/StreamLimitFixext"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    let value = recover val Array[U8].init('V', 16) end
    MessagePackEncoder.fixext_16(w, 40, value)?
    let sd = MessagePackStreamingDecoder(
      MessagePackDecodeLimits(where max_ext_len' = 15))
    sd.append(_WriterBytes(w))
    match sd.next()
    | LimitExceeded => None
    else h.fail("expected LimitExceeded")
    end

class \nodoc\ _TestStreamLimitMap is UnitTest
  """
  A map_16 with count 100 is rejected when max_map_len is 99.
  """
  fun name(): String => "msgpack/StreamLimitMap"

  fun ref apply(h: TestHelper) =>
    let w: Writer ref = Writer
    MessagePackEncoder.map_16(w, 100)
    let sd = MessagePackStreamingDecoder(
      MessagePackDecodeLimits(where max_map_len' = 99))
    sd.append(_WriterBytes(w))
    match sd.next()
    | LimitExceeded => None
    else h.fail("expected LimitExceeded")
    end

class \nodoc\ _TestStreamLimitArray32 is UnitTest
  """
  An array_32 with count 200000 is rejected when max_array_len
  is 131072.
  """
  fun name(): String => "msgpack/StreamLimitArray32"

  fun ref apply(h: TestHelper) =>
    let w: Writer ref = Writer
    MessagePackEncoder.array_32(w, 200_000)
    let sd = MessagePackStreamingDecoder(
      MessagePackDecodeLimits(
        where max_array_len' = 131_072))
    sd.append(_WriterBytes(w))
    match sd.next()
    | LimitExceeded => None
    else h.fail("expected LimitExceeded")
    end

class \nodoc\ _TestStreamLimitMap32 is UnitTest
  """
  A map_32 with count 200000 is rejected when max_map_len
  is 131072.
  """
  fun name(): String => "msgpack/StreamLimitMap32"

  fun ref apply(h: TestHelper) =>
    let w: Writer ref = Writer
    MessagePackEncoder.map_32(w, 200_000)
    let sd = MessagePackStreamingDecoder(
      MessagePackDecodeLimits(
        where max_map_len' = 131_072))
    sd.append(_WriterBytes(w))
    match sd.next()
    | LimitExceeded => None
    else h.fail("expected LimitExceeded")
    end

class \nodoc\ _TestStreamLimitStr16 is UnitTest
  """
  A str_16 with 300 bytes is rejected when max_str_len is 250.
  Exercises the peek_u16_be length path in _decode_str.
  """
  fun name(): String => "msgpack/StreamLimitStr16"

  fun ref apply(h: TestHelper) ? =>
    let data = recover iso Array[U8].init('A', 300) end
    let s: String val =
      String.from_iso_array(consume data)
    let w: Writer ref = Writer
    MessagePackEncoder.str_16(w, s)?
    let sd = MessagePackStreamingDecoder(
      MessagePackDecodeLimits(
        where max_str_len' = 250))
    sd.append(_WriterBytes(w))
    match sd.next()
    | LimitExceeded => None
    else h.fail("expected LimitExceeded")
    end

class \nodoc\ _TestStreamLimitBin16 is UnitTest
  """
  A bin_16 with 300 bytes is rejected when max_bin_len is 250.
  Exercises the peek_u16_be length path in _decode_bin.
  """
  fun name(): String => "msgpack/StreamLimitBin16"

  fun ref apply(h: TestHelper) ? =>
    let data = recover val
      Array[U8].init('B', 300)
    end
    let w: Writer ref = Writer
    MessagePackEncoder.bin_16(w, data)?
    let sd = MessagePackStreamingDecoder(
      MessagePackDecodeLimits(
        where max_bin_len' = 250))
    sd.append(_WriterBytes(w))
    match sd.next()
    | LimitExceeded => None
    else h.fail("expected LimitExceeded")
    end

class \nodoc\ _TestStreamLimitExt16 is UnitTest
  """
  An ext_16 with 300 bytes is rejected when max_ext_len is 250.
  Exercises the peek_u16_be length path in _decode_ext_variable.
  """
  fun name(): String => "msgpack/StreamLimitExt16"

  fun ref apply(h: TestHelper) ? =>
    let data = recover val
      Array[U8].init('C', 300)
    end
    let w: Writer ref = Writer
    MessagePackEncoder.ext_16(w, 42, data)?
    let sd = MessagePackStreamingDecoder(
      MessagePackDecodeLimits(
        where max_ext_len' = 250))
    sd.append(_WriterBytes(w))
    match sd.next()
    | LimitExceeded => None
    else h.fail("expected LimitExceeded")
    end

class \nodoc\ _TestStreamLimitNoConsume is UnitTest
  """
  When LimitExceeded is returned, no bytes are consumed.
  Calling next() again on the same data returns LimitExceeded
  again, confirming the reader state is unchanged.
  """
  fun name(): String => "msgpack/StreamLimitNoConsume"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.str_8(w, "hello world")?
    let sd = MessagePackStreamingDecoder(
      MessagePackDecodeLimits(where max_str_len' = 5))
    sd.append(_WriterBytes(w))

    // First call: LimitExceeded
    match sd.next()
    | LimitExceeded => None
    else h.fail("expected LimitExceeded")
    end

    // Second call: still LimitExceeded (bytes not consumed)
    match sd.next()
    | LimitExceeded => None
    else
      h.fail(
        "expected LimitExceeded on second call")
    end

class \nodoc\ _TestStreamLimitUnlimited is UnitTest
  """
  With unlimited() limits, large counts are accepted.
  """
  fun name(): String => "msgpack/StreamLimitUnlimited"

  fun ref apply(h: TestHelper) =>
    let w: Writer ref = Writer
    MessagePackEncoder.array_32(w, 200_000)
    let sd = MessagePackStreamingDecoder(
      MessagePackDecodeLimits.unlimited())
    sd.append(_WriterBytes(w))
    match sd.next()
    | let v: MessagePackArray =>
      h.assert_eq[U32](200_000, v.size)
    else h.fail("expected MessagePackArray")
    end

class \nodoc\ _TestStreamLimitAtBoundary is UnitTest
  """
  A value whose size exactly equals the limit is accepted.
  """
  fun name(): String => "msgpack/StreamLimitAtBoundary"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.str_8(w, "1234567890")?
    let sd = MessagePackStreamingDecoder(
      MessagePackDecodeLimits(where max_str_len' = 10))
    sd.append(_WriterBytes(w))
    match sd.next()
    | let v: String val =>
      h.assert_eq[USize](10, v.size())
    else h.fail("expected String at limit boundary")
    end

//
// Limit property-based tests
//

class \nodoc\ _PropertyStreamLimitStr
  is Property1[String]
  """
  For any ASCII string 0-100 chars with max_str_len=50:
  strings longer than 50 return LimitExceeded, others succeed.
  Exercises both fixstr (<=31) and str_8 (32-100) paths.
  """
  fun name(): String =>
    "msgpack/PropertyStreamLimitStr"

  fun gen(): Generator[String] =>
    Generators.ascii_printable(0, 100)

  fun ref property(arg1: String, h: PropertyHelper) ? =>
    let s: String val = arg1.clone()
    let w: Writer ref = Writer
    MessagePackEncoder.str(w, s)?
    let sd = MessagePackStreamingDecoder(
      MessagePackDecodeLimits(
        where max_str_len' = 50))
    sd.append(_WriterBytes(w))

    if s.size() > 50 then
      match sd.next()
      | LimitExceeded => None
      else
        h.fail(
          "expected LimitExceeded for size "
            + s.size().string())
      end
    else
      match sd.next()
      | let v: String val =>
        h.assert_eq[String](s, v)
      else
        h.fail(
          "expected String for size "
            + s.size().string())
      end
    end

class \nodoc\ _PropertyStreamLimitBin
  is Property1[U8]
  """
  For any byte array of size 0-255 with max_bin_len=100:
  arrays larger than 100 return LimitExceeded, others succeed.
  """
  fun name(): String =>
    "msgpack/PropertyStreamLimitBin"

  fun gen(): Generator[U8] =>
    Generators.u8()

  fun ref property(arg1: U8, h: PropertyHelper) ? =>
    let data = recover val
      Array[U8].init('X', arg1.usize())
    end
    let w: Writer ref = Writer
    MessagePackEncoder.bin(w, data)?
    let sd = MessagePackStreamingDecoder(
      MessagePackDecodeLimits(
        where max_bin_len' = 100))
    sd.append(_WriterBytes(w))

    if arg1.usize() > 100 then
      match sd.next()
      | LimitExceeded => None
      else
        h.fail(
          "expected LimitExceeded for size "
            + arg1.string())
      end
    else
      match sd.next()
      | let v: Array[U8] val =>
        h.assert_eq[USize](
          arg1.usize(), v.size())
      else
        h.fail(
          "expected Array[U8] for size "
            + arg1.string())
      end
    end

class \nodoc\ _PropertyStreamLimitArray
  is Property1[U16]
  """
  For any U16 count with max_array_len=1000: counts above 1000
  return LimitExceeded, others succeed. Exercises both fixarray
  (<=15) and array_16 (16-65535) paths.
  """
  fun name(): String =>
    "msgpack/PropertyStreamLimitArray"

  fun gen(): Generator[U16] =>
    Generators.u16()

  fun ref property(arg1: U16, h: PropertyHelper) =>
    let w: Writer ref = Writer
    MessagePackEncoder.array(w, arg1.u32())
    let sd = MessagePackStreamingDecoder(
      MessagePackDecodeLimits(
        where max_array_len' = 1000))
    sd.append(_WriterBytes(w))

    if arg1.u32() > 1000 then
      match sd.next()
      | LimitExceeded => None
      else
        h.fail(
          "expected LimitExceeded for count "
            + arg1.string())
      end
    else
      match sd.next()
      | let v: MessagePackArray =>
        h.assert_eq[U32](arg1.u32(), v.size)
      else
        h.fail(
          "expected MessagePackArray for count "
            + arg1.string())
      end
    end

class \nodoc\ _PropertyStreamLimitExt
  is Property1[U8]
  """
  For any ext data of size 0-255 with max_ext_len=100: data
  larger than 100 return LimitExceeded, others succeed. Uses
  ext_type 42 to avoid timestamp detection.
  """
  fun name(): String =>
    "msgpack/PropertyStreamLimitExt"

  fun gen(): Generator[U8] =>
    Generators.u8()

  fun ref property(arg1: U8, h: PropertyHelper) ? =>
    let data = recover val
      Array[U8].init('Z', arg1.usize())
    end
    let w: Writer ref = Writer
    MessagePackEncoder.ext(w, 42, data)?
    let sd = MessagePackStreamingDecoder(
      MessagePackDecodeLimits(
        where max_ext_len' = 100))
    sd.append(_WriterBytes(w))

    if arg1.usize() > 100 then
      match sd.next()
      | LimitExceeded => None
      else
        h.fail(
          "expected LimitExceeded for size "
            + arg1.string())
      end
    else
      match sd.next()
      | let v: MessagePackExt =>
        h.assert_eq[U8](42, v.ext_type)
        h.assert_eq[USize](
          arg1.usize(), v.data.size())
      else
        h.fail(
          "expected MessagePackExt for size "
            + arg1.string())
      end
    end

//
// Depth limit tests
//

class \nodoc\ _TestStreamDepthBasic is UnitTest
  """
  Nested arrays at depth 2 succeed with max_depth=2.
  A third nesting level returns LimitExceeded.
  """
  fun name(): String => "msgpack/StreamDepthBasic"

  fun ref apply(h: TestHelper) ? =>
    // Encode: [[1]]  (depth 2)
    let w: Writer ref = Writer
    MessagePackEncoder.fixarray(w, 1)?
    MessagePackEncoder.fixarray(w, 1)?
    MessagePackEncoder.uint(w, 1)

    let sd = MessagePackStreamingDecoder(
      MessagePackDecodeLimits(
        where max_depth' = 2))
    sd.append(_WriterBytes(w))

    // Outer array at depth 1 — succeeds
    match sd.next()
    | let a: MessagePackArray =>
      h.assert_eq[U32](1, a.size)
    else h.fail("expected outer array")
    end

    // Inner array at depth 2 — succeeds
    match sd.next()
    | let a: MessagePackArray =>
      h.assert_eq[U32](1, a.size)
    else h.fail("expected inner array")
    end

    // Element inside inner array
    match sd.next()
    | let v: U8 =>
      h.assert_eq[U8](1, v)
    else h.fail("expected U8(1)")
    end

    // Now encode depth 3 and verify rejection
    let w2: Writer ref = Writer
    MessagePackEncoder.fixarray(w2, 1)?
    MessagePackEncoder.fixarray(w2, 1)?
    MessagePackEncoder.fixarray(w2, 1)?
    MessagePackEncoder.uint(w2, 1)

    let sd2 = MessagePackStreamingDecoder(
      MessagePackDecodeLimits(
        where max_depth' = 2))
    sd2.append(_WriterBytes(w2))

    // Depth 1 — succeeds
    match sd2.next()
    | let a: MessagePackArray => None
    else h.fail("expected outer array")
    end

    // Depth 2 — succeeds
    match sd2.next()
    | let a: MessagePackArray => None
    else h.fail("expected middle array")
    end

    // Depth 3 — rejected
    match sd2.next()
    | LimitExceeded => None
    else h.fail("expected LimitExceeded at depth 3")
    end

class \nodoc\ _TestStreamDepthExact is UnitTest
  """
  Nesting exactly to max_depth succeeds.
  One deeper fails.
  """
  fun name(): String => "msgpack/StreamDepthExact"

  fun ref apply(h: TestHelper) ? =>
    // Build depth=5 nested arrays, each containing one U8
    let w: Writer ref = Writer
    var i: USize = 0
    while i < 5 do
      MessagePackEncoder.fixarray(w, 1)?
      i = i + 1
    end
    MessagePackEncoder.uint(w, 42)

    let sd = MessagePackStreamingDecoder(
      MessagePackDecodeLimits(
        where max_depth' = 5))
    sd.append(_WriterBytes(w))

    // All 5 arrays should succeed
    i = 0
    while i < 5 do
      match sd.next()
      | let a: MessagePackArray => None
      else h.fail("expected array at depth "
        + (i + 1).string())
      end
      i = i + 1
    end

    // The scalar at the bottom
    match sd.next()
    | let v: U8 =>
      h.assert_eq[U8](42, v)
    else h.fail("expected U8(42)")
    end

    // Now try depth=6 with max_depth=5
    let w2: Writer ref = Writer
    i = 0
    while i < 6 do
      MessagePackEncoder.fixarray(w2, 1)?
      i = i + 1
    end
    MessagePackEncoder.uint(w2, 42)

    let sd2 = MessagePackStreamingDecoder(
      MessagePackDecodeLimits(
        where max_depth' = 5))
    sd2.append(_WriterBytes(w2))

    // First 5 succeed
    i = 0
    while i < 5 do
      match sd2.next()
      | let a: MessagePackArray => None
      else h.fail("expected array at depth "
        + (i + 1).string())
      end
      i = i + 1
    end

    // 6th fails
    match sd2.next()
    | LimitExceeded => None
    else h.fail("expected LimitExceeded at depth 6")
    end

class \nodoc\ _TestStreamDepthAutoTrack is UnitTest
  """
  Decode [[1,2],3] and verify depth() at each step.
  """
  fun name(): String => "msgpack/StreamDepthAutoTrack"

  fun ref apply(h: TestHelper) ? =>
    // Encode [[1, 2], 3]
    let w: Writer ref = Writer
    MessagePackEncoder.fixarray(w, 2)?
    MessagePackEncoder.fixarray(w, 2)?
    MessagePackEncoder.uint(w, 1)
    MessagePackEncoder.uint(w, 2)
    MessagePackEncoder.uint(w, 3)

    let sd = MessagePackStreamingDecoder(
      MessagePackDecodeLimits.unlimited())
    sd.append(_WriterBytes(w))

    // Array(2) -> depth 1
    match sd.next()
    | let a: MessagePackArray =>
      h.assert_eq[U32](2, a.size)
    else h.fail("expected outer array")
    end
    h.assert_eq[USize](1, sd.depth())

    // Array(2) -> depth 2
    match sd.next()
    | let a: MessagePackArray =>
      h.assert_eq[U32](2, a.size)
    else h.fail("expected inner array")
    end
    h.assert_eq[USize](2, sd.depth())

    // U8(1) -> depth 2
    match sd.next()
    | let v: U8 =>
      h.assert_eq[U8](1, v)
    else h.fail("expected U8(1)")
    end
    h.assert_eq[USize](2, sd.depth())

    // U8(2) -> inner exhausted, depth 1
    match sd.next()
    | let v: U8 =>
      h.assert_eq[U8](2, v)
    else h.fail("expected U8(2)")
    end
    h.assert_eq[USize](1, sd.depth())

    // U8(3) -> outer exhausted, depth 0
    match sd.next()
    | let v: U8 =>
      h.assert_eq[U8](3, v)
    else h.fail("expected U8(3)")
    end
    h.assert_eq[USize](0, sd.depth())

class \nodoc\ _TestStreamDepthMap is UnitTest
  """
  Maps increment depth. Nested map triggers limit.
  """
  fun name(): String => "msgpack/StreamDepthMap"

  fun ref apply(h: TestHelper) ? =>
    // Encode {"a": {"b": 1}}
    let w: Writer ref = Writer
    MessagePackEncoder.fixmap(w, 1)?
    MessagePackEncoder.str(w, "a")?
    MessagePackEncoder.fixmap(w, 1)?
    MessagePackEncoder.str(w, "b")?
    MessagePackEncoder.uint(w, 1)

    let sd = MessagePackStreamingDecoder(
      MessagePackDecodeLimits(
        where max_depth' = 1))
    sd.append(_WriterBytes(w))

    // Outer map at depth 1 — succeeds
    match sd.next()
    | let m: MessagePackMap =>
      h.assert_eq[U32](1, m.size)
    else h.fail("expected outer map")
    end

    // Key "a" — scalar, depth stays 1
    match sd.next()
    | let s: String val =>
      h.assert_eq[String val]("a", s)
    else h.fail("expected string key")
    end

    // Inner map — depth 2, exceeds limit
    match sd.next()
    | LimitExceeded => None
    else h.fail("expected LimitExceeded for nested map")
    end

class \nodoc\ _TestStreamDepthMixed is UnitTest
  """
  Array containing map containing array — all contribute
  to depth.
  """
  fun name(): String => "msgpack/StreamDepthMixed"

  fun ref apply(h: TestHelper) ? =>
    // Encode [{"k": [1]}]
    let w: Writer ref = Writer
    MessagePackEncoder.fixarray(w, 1)?
    MessagePackEncoder.fixmap(w, 1)?
    MessagePackEncoder.str(w, "k")?
    MessagePackEncoder.fixarray(w, 1)?
    MessagePackEncoder.uint(w, 1)

    let sd = MessagePackStreamingDecoder(
      MessagePackDecodeLimits.unlimited())
    sd.append(_WriterBytes(w))

    // Array -> depth 1
    match sd.next()
    | let a: MessagePackArray => None
    else h.fail("expected array")
    end
    h.assert_eq[USize](1, sd.depth())

    // Map -> depth 2
    match sd.next()
    | let m: MessagePackMap => None
    else h.fail("expected map")
    end
    h.assert_eq[USize](2, sd.depth())

    // Key "k" -> depth 2
    match sd.next()
    | let s: String val => None
    else h.fail("expected string key")
    end
    h.assert_eq[USize](2, sd.depth())

    // Inner array -> depth 3
    match sd.next()
    | let a: MessagePackArray => None
    else h.fail("expected inner array")
    end
    h.assert_eq[USize](3, sd.depth())

    // U8(1) -> cascading pops, depth 0
    match sd.next()
    | let v: U8 =>
      h.assert_eq[U8](1, v)
    else h.fail("expected U8(1)")
    end
    h.assert_eq[USize](0, sd.depth())

class \nodoc\ _TestStreamDepthNoConsume is UnitTest
  """
  LimitExceeded from depth: no bytes consumed, retrying
  returns LimitExceeded again.
  """
  fun name(): String => "msgpack/StreamDepthNoConsume"

  fun ref apply(h: TestHelper) ? =>
    // Encode [[1]]
    let w: Writer ref = Writer
    MessagePackEncoder.fixarray(w, 1)?
    MessagePackEncoder.fixarray(w, 1)?
    MessagePackEncoder.uint(w, 1)

    let sd = MessagePackStreamingDecoder(
      MessagePackDecodeLimits(
        where max_depth' = 1))
    sd.append(_WriterBytes(w))

    // Depth 1 — succeeds
    match sd.next()
    | let a: MessagePackArray => None
    else h.fail("expected array")
    end

    // Depth 2 — rejected, no bytes consumed
    match sd.next()
    | LimitExceeded => None
    else h.fail("expected LimitExceeded")
    end

    // Retry — same result
    match sd.next()
    | LimitExceeded => None
    else h.fail("expected LimitExceeded on retry")
    end

class \nodoc\ _TestStreamDepthUnlimited is UnitTest
  """
  unlimited() allows deep nesting.
  """
  fun name(): String => "msgpack/StreamDepthUnlimited"

  fun ref apply(h: TestHelper) ? =>
    // Build 50 levels of nesting
    let w: Writer ref = Writer
    var i: USize = 0
    while i < 50 do
      MessagePackEncoder.fixarray(w, 1)?
      i = i + 1
    end
    MessagePackEncoder.uint(w, 99)

    let sd = MessagePackStreamingDecoder(
      MessagePackDecodeLimits.unlimited())
    sd.append(_WriterBytes(w))

    // All 50 arrays should decode
    i = 0
    while i < 50 do
      match sd.next()
      | let a: MessagePackArray => None
      else h.fail("expected array at depth "
        + (i + 1).string())
      end
      i = i + 1
    end

    // The scalar
    match sd.next()
    | let v: U8 =>
      h.assert_eq[U8](99, v)
    else h.fail("expected U8(99)")
    end
    h.assert_eq[USize](0, sd.depth())

class \nodoc\ _TestStreamDepthZero is UnitTest
  """
  max_depth=0: any container returns LimitExceeded.
  Scalars still work.
  """
  fun name(): String => "msgpack/StreamDepthZero"

  fun ref apply(h: TestHelper) =>
    let w: Writer ref = Writer
    MessagePackEncoder.uint(w, 42)

    let sd = MessagePackStreamingDecoder(
      MessagePackDecodeLimits(
        where max_depth' = 0))
    sd.append(_WriterBytes(w))

    // Scalar at depth 0 — works
    match sd.next()
    | let v: U8 =>
      h.assert_eq[U8](42, v)
    else h.fail("expected U8(42)")
    end

    // Array at depth 0 — rejected
    let w2: Writer ref = Writer
    MessagePackEncoder.array_16(w2, 1)
    sd.append(_WriterBytes(w2))

    match sd.next()
    | LimitExceeded => None
    else h.fail("expected LimitExceeded for array")
    end

class \nodoc\ _TestStreamDepthEmptyContainer is UnitTest
  """
  Empty array increments then immediately decrements depth.
  """
  fun name(): String => "msgpack/StreamDepthEmptyContainer"

  fun ref apply(h: TestHelper) ? =>
    // Encode [[], 1]
    let w: Writer ref = Writer
    MessagePackEncoder.fixarray(w, 2)?
    MessagePackEncoder.fixarray(w, 0)?
    MessagePackEncoder.uint(w, 1)

    let sd = MessagePackStreamingDecoder(
      MessagePackDecodeLimits.unlimited())
    sd.append(_WriterBytes(w))

    // Outer array
    match sd.next()
    | let a: MessagePackArray =>
      h.assert_eq[U32](2, a.size)
    else h.fail("expected outer array")
    end
    h.assert_eq[USize](1, sd.depth())

    // Empty inner array — pushed 0, immediately drained
    match sd.next()
    | let a: MessagePackArray =>
      h.assert_eq[U32](0, a.size)
    else h.fail("expected empty array")
    end
    h.assert_eq[USize](1, sd.depth())

    // U8(1) — outer exhausted
    match sd.next()
    | let v: U8 =>
      h.assert_eq[U8](1, v)
    else h.fail("expected U8(1)")
    end
    h.assert_eq[USize](0, sd.depth())

class \nodoc\ _TestStreamDepthDefault is UnitTest
  """
  Default max_depth is 512.
  """
  fun name(): String => "msgpack/StreamDepthDefault"

  fun ref apply(h: TestHelper) =>
    let limits = MessagePackDecodeLimits
    h.assert_eq[USize](512, limits.max_depth)

class \nodoc\ _PropertyStreamDepth is Property1[U8]
  """
  Generate a random nesting depth (0-15). Build nested
  fixarrays to that depth, each containing one U8. With
  max_depth=10, nesting beyond 10 returns LimitExceeded;
  within limit, all values decode and depth returns to 0.
  """
  fun name(): String =>
    "msgpack/PropertyStreamDepth"

  fun gen(): Generator[U8] =>
    Generators.u8(0, 15)

  fun ref property(
    arg1: U8,
    h: PropertyHelper)
  =>
    let nesting = arg1.usize()
    let max_depth: USize = 10

    let w: Writer ref = Writer
    var i: USize = 0
    try
      while i < nesting do
        MessagePackEncoder.fixarray(w, 1)?
        i = i + 1
      end
    else
      h.fail("encoding failed")
      return
    end
    MessagePackEncoder.uint(w, 42)

    let sd = MessagePackStreamingDecoder(
      MessagePackDecodeLimits(
        where max_depth' = max_depth))
    sd.append(_WriterBytes(w))

    if nesting > max_depth then
      // Decode containers up to the limit
      i = 0
      while i < max_depth do
        match sd.next()
        | let a: MessagePackArray => None
        else
          h.fail("expected array at depth "
            + (i + 1).string())
          return
        end
        i = i + 1
      end
      // Next container exceeds limit
      match sd.next()
      | LimitExceeded => None
      else
        h.fail("expected LimitExceeded at depth "
          + (max_depth + 1).string()
          + " with nesting " + nesting.string())
      end
    else
      // All containers should decode
      i = 0
      while i < nesting do
        match sd.next()
        | let a: MessagePackArray => None
        else
          h.fail("expected array at depth "
            + (i + 1).string())
          return
        end
        i = i + 1
      end
      // Scalar at the bottom
      match sd.next()
      | let v: U8 =>
        h.assert_eq[U8](42, v)
      else
        h.fail("expected U8(42)")
        return
      end
      // Depth should be back to 0
      h.assert_eq[USize](0, sd.depth())
    end

//
// Skip tests
//

class \nodoc\ _TestStreamSkipNil is UnitTest
  fun name(): String => "msgpack/StreamSkipNil"

  fun ref apply(h: TestHelper) =>
    let w: Writer ref = Writer
    MessagePackEncoder.nil(w)
    let sd = MessagePackStreamingDecoder
    sd.append(_WriterBytes(w))
    match sd.skip()
    | None => None
    else h.fail("expected None")
    end
    // Reader should be empty
    match sd.next()
    | NotEnoughData => None
    else h.fail("expected NotEnoughData after skip")
    end

class \nodoc\ _TestStreamSkipStr is UnitTest
  fun name(): String => "msgpack/StreamSkipStr"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.str_8(w, "hello world")?
    let sd = MessagePackStreamingDecoder
    sd.append(_WriterBytes(w))
    match sd.skip()
    | None => None
    else h.fail("expected None")
    end
    match sd.next()
    | NotEnoughData => None
    else h.fail("expected NotEnoughData after skip")
    end

class \nodoc\ _TestStreamSkipFixarray is UnitTest
  """
  Skip a fixarray with scalar elements.
  """
  fun name(): String => "msgpack/StreamSkipFixarray"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.fixarray(w, 3)?
    MessagePackEncoder.uint(w, 1)
    MessagePackEncoder.uint(w, 2)
    MessagePackEncoder.uint(w, 3)
    let sd = MessagePackStreamingDecoder
    sd.append(_WriterBytes(w))
    match sd.skip()
    | None => None
    else h.fail("expected None")
    end
    match sd.next()
    | NotEnoughData => None
    else h.fail("expected NotEnoughData after skip")
    end

class \nodoc\ _TestStreamSkipArray32 is UnitTest
  """
  Skip an array_32 with 65536 fixint elements.
  """
  fun name(): String => "msgpack/StreamSkipArray32"

  fun ref apply(h: TestHelper) =>
    ifdef not "ci" then
      let count = U16.max_value().u32() + 1
      let w: Writer ref = Writer
      MessagePackEncoder.array_32(w, count)
      var i: U32 = 0
      while i < count do
        MessagePackEncoder.uint(w, 1)
        i = i + 1
      end
      let sd = MessagePackStreamingDecoder(
        MessagePackDecodeLimits.unlimited())
      sd.append(_WriterBytes(w))
      match sd.skip()
      | None => None
      else h.fail("expected None")
      end
      match sd.next()
      | NotEnoughData => None
      else
        h.fail("expected NotEnoughData after skip")
      end
    end

class \nodoc\ _TestStreamSkipFixmap is UnitTest
  """
  Skip a fixmap with key-value pairs.
  """
  fun name(): String => "msgpack/StreamSkipFixmap"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.fixmap(w, 2)?
    MessagePackEncoder.uint(w, 1)
    MessagePackEncoder.uint(w, 10)
    MessagePackEncoder.uint(w, 2)
    MessagePackEncoder.uint(w, 20)
    let sd = MessagePackStreamingDecoder
    sd.append(_WriterBytes(w))
    match sd.skip()
    | None => None
    else h.fail("expected None")
    end
    match sd.next()
    | NotEnoughData => None
    else h.fail("expected NotEnoughData after skip")
    end

class \nodoc\ _TestStreamSkipMap32 is UnitTest
  """
  Skip a map_32 with 65536 fixint key-value pairs.
  """
  fun name(): String => "msgpack/StreamSkipMap32"

  fun ref apply(h: TestHelper) =>
    ifdef not "ci" then
      let count = U16.max_value().u32() + 1
      let w: Writer ref = Writer
      MessagePackEncoder.map_32(w, count)
      var i: U32 = 0
      while i < count do
        MessagePackEncoder.uint(w, 1)
        MessagePackEncoder.uint(w, 2)
        i = i + 1
      end
      let sd = MessagePackStreamingDecoder(
        MessagePackDecodeLimits.unlimited())
      sd.append(_WriterBytes(w))
      match sd.skip()
      | None => None
      else h.fail("expected None")
      end
      match sd.next()
      | NotEnoughData => None
      else
        h.fail("expected NotEnoughData after skip")
      end
    end

class \nodoc\ _TestStreamSkipNestedContainers is UnitTest
  """
  Skip deeply nested containers: [[1, [2]], {3: 4}].
  """
  fun name(): String => "msgpack/StreamSkipNestedContainers"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.fixarray(w, 2)?
    // First element: [1, [2]]
    MessagePackEncoder.fixarray(w, 2)?
    MessagePackEncoder.uint(w, 1)
    MessagePackEncoder.fixarray(w, 1)?
    MessagePackEncoder.uint(w, 2)
    // Second element: {3: 4}
    MessagePackEncoder.fixmap(w, 1)?
    MessagePackEncoder.uint(w, 3)
    MessagePackEncoder.uint(w, 4)

    let sd = MessagePackStreamingDecoder
    sd.append(_WriterBytes(w))
    match sd.skip()
    | None => None
    else h.fail("expected None")
    end
    match sd.next()
    | NotEnoughData => None
    else h.fail("expected NotEnoughData after skip")
    end

class \nodoc\ _TestStreamSkipEmptyContainers is UnitTest
  """
  Skip empty fixarray and empty fixmap.
  """
  fun name(): String => "msgpack/StreamSkipEmptyContainers"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.fixarray(w, 0)?
    MessagePackEncoder.fixmap(w, 0)?

    let sd = MessagePackStreamingDecoder
    sd.append(_WriterBytes(w))

    // Skip empty array
    match sd.skip()
    | None => None
    else h.fail("expected None for empty array")
    end

    // Skip empty map
    match sd.skip()
    | None => None
    else h.fail("expected None for empty map")
    end

    match sd.next()
    | NotEnoughData => None
    else h.fail("expected NotEnoughData after skip")
    end

class \nodoc\ _TestStreamSkipTimestamp is UnitTest
  """
  Skip a timestamp (fixext_4 wire format).
  """
  fun name(): String => "msgpack/StreamSkipTimestamp"

  fun ref apply(h: TestHelper) =>
    let w: Writer ref = Writer
    MessagePackEncoder.timestamp_32(w, 1000)
    let sd = MessagePackStreamingDecoder
    sd.append(_WriterBytes(w))
    match sd.skip()
    | None => None
    else h.fail("expected None")
    end
    match sd.next()
    | NotEnoughData => None
    else h.fail("expected NotEnoughData after skip")
    end

class \nodoc\ _TestStreamSkipNotEnoughData is UnitTest
  """
  Partial data returns NotEnoughData, no bytes consumed.
  """
  fun name(): String => "msgpack/StreamSkipNotEnoughData"

  fun ref apply(h: TestHelper) =>
    let sd = MessagePackStreamingDecoder

    // Empty reader
    match sd.skip()
    | NotEnoughData => None
    else h.fail("expected NotEnoughData on empty")
    end

    // Partial uint_32 (only 3 of 5 bytes)
    sd.append(
      recover val [as U8: 0xCE; 0x00; 0x01] end)
    match sd.skip()
    | NotEnoughData => None
    else h.fail("expected NotEnoughData on partial")
    end

    // Feed remaining bytes to verify no consumption
    sd.append(
      recover val [as U8: 0xE2; 0x40] end)
    match sd.skip()
    | None => None
    else h.fail("expected None after completing data")
    end

class \nodoc\ _TestStreamSkipInvalidData is UnitTest
  """
  0xC1 returns InvalidData.
  """
  fun name(): String => "msgpack/StreamSkipInvalidData"

  fun ref apply(h: TestHelper) =>
    let sd = MessagePackStreamingDecoder
    sd.append(
      recover val [as U8: 0xC1] end)
    match sd.skip()
    | InvalidData => None
    else h.fail("expected InvalidData")
    end

    // Calling skip again returns InvalidData again
    match sd.skip()
    | InvalidData => None
    else h.fail("expected InvalidData on retry")
    end

class \nodoc\ _TestStreamSkipLimitExceeded is UnitTest
  """
  Nested containers exceeding max_skip_values returns
  LimitExceeded.
  """
  fun name(): String => "msgpack/StreamSkipLimitExceeded"

  fun ref apply(h: TestHelper) ? =>
    // Array with 10 elements — skip traverses 11 values
    // (the array header + 10 elements)
    let w: Writer ref = Writer
    MessagePackEncoder.fixarray(w, 10)?
    var i: U32 = 0
    while i < 10 do
      MessagePackEncoder.uint(w, 1)
      i = i + 1
    end

    let sd = MessagePackStreamingDecoder(
      MessagePackDecodeLimits(
        where max_skip_values' = 10))
    sd.append(_WriterBytes(w))

    // 11 values to traverse, limit is 10
    match sd.skip()
    | LimitExceeded => None
    else h.fail("expected LimitExceeded")
    end

class \nodoc\ _TestStreamSkipLimitNoConsume is UnitTest
  """
  LimitExceeded consumes no bytes.
  """
  fun name(): String => "msgpack/StreamSkipLimitNoConsume"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.fixarray(w, 5)?
    var i: U32 = 0
    while i < 5 do
      MessagePackEncoder.uint(w, 1)
      i = i + 1
    end

    let sd = MessagePackStreamingDecoder(
      MessagePackDecodeLimits(
        where max_skip_values' = 1))
    sd.append(_WriterBytes(w))

    // First call: LimitExceeded
    match sd.skip()
    | LimitExceeded => None
    else h.fail("expected LimitExceeded")
    end

    // Second call: still LimitExceeded (no bytes consumed)
    match sd.skip()
    | LimitExceeded => None
    else h.fail("expected LimitExceeded on retry")
    end

class \nodoc\ _TestStreamSkipDepthTracking is UnitTest
  """
  Skip inside a container updates depth correctly.
  Decode array header via next(), skip elements, verify
  depth returns to 0.
  """
  fun name(): String => "msgpack/StreamSkipDepthTracking"

  fun ref apply(h: TestHelper) ? =>
    // Encode [1, "hello", [2, 3]]
    let w: Writer ref = Writer
    MessagePackEncoder.fixarray(w, 3)?
    MessagePackEncoder.uint(w, 1)
    MessagePackEncoder.str(w, "hello")?
    MessagePackEncoder.fixarray(w, 2)?
    MessagePackEncoder.uint(w, 2)
    MessagePackEncoder.uint(w, 3)

    let sd = MessagePackStreamingDecoder
    sd.append(_WriterBytes(w))

    // Decode the outer array header
    match sd.next()
    | let a: MessagePackArray =>
      h.assert_eq[U32](3, a.size)
    else h.fail("expected array header")
    end
    h.assert_eq[USize](1, sd.depth())

    // Skip first element (1)
    match sd.skip()
    | None => None
    else h.fail("expected None for skip 1")
    end
    h.assert_eq[USize](1, sd.depth())

    // Skip second element ("hello")
    match sd.skip()
    | None => None
    else h.fail("expected None for skip 2")
    end
    h.assert_eq[USize](1, sd.depth())

    // Skip third element ([2, 3]) — this pops the outer
    match sd.skip()
    | None => None
    else h.fail("expected None for skip 3")
    end
    h.assert_eq[USize](0, sd.depth())

class \nodoc\ _TestStreamSkipPositionPreserving is UnitTest
  """
  Encode [value_a, value_b], skip value_a, decode value_b,
  verify match.
  """
  fun name(): String =>
    "msgpack/StreamSkipPositionPreserving"

  fun ref apply(h: TestHelper) ? =>
    // Skip a string, then decode a uint
    let w: Writer ref = Writer
    MessagePackEncoder.str(w, "skip me")?
    MessagePackEncoder.uint_32(w, 42)
    let sd = MessagePackStreamingDecoder
    sd.append(_WriterBytes(w))

    match sd.skip()
    | None => None
    else h.fail("expected None on skip")
    end

    match sd.next()
    | let v: U32 => h.assert_eq[U32](42, v)
    else h.fail("expected U32(42)")
    end

    // Skip an array, then decode a string
    let w2: Writer ref = Writer
    MessagePackEncoder.fixarray(w2, 2)?
    MessagePackEncoder.uint(w2, 1)
    MessagePackEncoder.uint(w2, 2)
    MessagePackEncoder.str(w2, "after")?
    let sd2 = MessagePackStreamingDecoder
    sd2.append(_WriterBytes(w2))

    match sd2.skip()
    | None => None
    else h.fail("expected None on skip array")
    end

    match sd2.next()
    | let v: String val =>
      h.assert_eq[String]("after", v)
    else h.fail("expected String")
    end

class \nodoc\ _TestStreamSkipInsideContainer is UnitTest
  """
  Decode array header via next(), skip elements, verify
  depth returns to 0.
  """
  fun name(): String =>
    "msgpack/StreamSkipInsideContainer"

  fun ref apply(h: TestHelper) ? =>
    // Encode {"name": "Alice", "age": 30, "scores": [1]}
    let w: Writer ref = Writer
    MessagePackEncoder.fixmap(w, 3)?
    MessagePackEncoder.str(w, "name")?
    MessagePackEncoder.str(w, "Alice")?
    MessagePackEncoder.str(w, "age")?
    MessagePackEncoder.uint(w, 30)
    MessagePackEncoder.str(w, "scores")?
    MessagePackEncoder.fixarray(w, 1)?
    MessagePackEncoder.uint(w, 1)

    let sd = MessagePackStreamingDecoder
    sd.append(_WriterBytes(w))

    // Decode map header
    match sd.next()
    | let m: MessagePackMap =>
      h.assert_eq[U32](3, m.size)
    else h.fail("expected map header")
    end
    h.assert_eq[USize](1, sd.depth())

    // Read key "name", skip value "Alice"
    match sd.next()
    | let s: String val =>
      h.assert_eq[String]("name", s)
    else h.fail("expected key 'name'")
    end
    match sd.skip()
    | None => None
    else h.fail("expected None skipping 'Alice'")
    end

    // Read key "age", skip value 30
    match sd.next()
    | let s: String val =>
      h.assert_eq[String]("age", s)
    else h.fail("expected key 'age'")
    end
    match sd.skip()
    | None => None
    else h.fail("expected None skipping 30")
    end

    // Read key "scores", skip value [1]
    match sd.next()
    | let s: String val =>
      h.assert_eq[String]("scores", s)
    else h.fail("expected key 'scores'")
    end
    match sd.skip()
    | None => None
    else h.fail("expected None skipping [1]")
    end

    h.assert_eq[USize](0, sd.depth())

//
// Skip property-based tests
//

class \nodoc\ _PropertyStreamSkipU32Safety
  is Property1[U32]
  """
  For any U32, encoding as uint_32 and feeding byte-by-byte,
  skip() returns NotEnoughData until the last byte, then None.
  """
  fun name(): String =>
    "msgpack/PropertyStreamSkipU32Safety"

  fun gen(): Generator[U32] =>
    Generators.u32()

  fun ref property(arg1: U32, h: PropertyHelper) ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.uint_32(w, arg1)
    let bytes = _WriterBytes(w)
    let sd = MessagePackStreamingDecoder

    var i: USize = 0
    while i < (bytes.size() - 1) do
      sd.append(
        recover val [as U8: bytes(i)?] end)
      match sd.skip()
      | NotEnoughData => None
      else
        h.fail(
          "NotEnoughData expected at byte "
            + i.string())
        return
      end
      i = i + 1
    end

    sd.append(
      recover val
        [as U8: bytes(bytes.size() - 1)?]
      end)

    match sd.skip()
    | None => None
    else
      h.fail("expected None after all bytes")
    end

class \nodoc\ _PropertyStreamSkipI16Safety
  is Property1[I16]
  """
  For any I16, encoding as int_16 and feeding byte-by-byte,
  skip() returns NotEnoughData until the last byte, then None.
  """
  fun name(): String =>
    "msgpack/PropertyStreamSkipI16Safety"

  fun gen(): Generator[I16] =>
    Generators.i16()

  fun ref property(arg1: I16, h: PropertyHelper) ? =>
    let w: Writer ref = Writer
    MessagePackEncoder.int_16(w, arg1)
    let bytes = _WriterBytes(w)
    let sd = MessagePackStreamingDecoder

    var i: USize = 0
    while i < (bytes.size() - 1) do
      sd.append(
        recover val [as U8: bytes(i)?] end)
      match sd.skip()
      | NotEnoughData => None
      else
        h.fail(
          "NotEnoughData expected at byte "
            + i.string())
        return
      end
      i = i + 1
    end

    sd.append(
      recover val
        [as U8: bytes(bytes.size() - 1)?]
      end)

    match sd.skip()
    | None => None
    else
      h.fail("expected None after all bytes")
    end

class \nodoc\ _PropertyStreamSkipStr8Safety
  is Property1[String]
  """
  For any short ASCII string, encoding as str_8 and feeding
  byte-by-byte, skip() returns NotEnoughData until the last
  byte, then None.
  """
  fun name(): String =>
    "msgpack/PropertyStreamSkipStr8Safety"

  fun gen(): Generator[String] =>
    Generators.ascii_printable(0, 100)

  fun ref property(arg1: String, h: PropertyHelper) ? =>
    let s: String val = arg1.clone()
    let w: Writer ref = Writer
    MessagePackEncoder.str_8(w, s)?
    let bytes = _WriterBytes(w)
    let sd = MessagePackStreamingDecoder

    var i: USize = 0
    while i < (bytes.size() - 1) do
      sd.append(
        recover val [as U8: bytes(i)?] end)
      match sd.skip()
      | NotEnoughData => None
      else
        h.fail(
          "NotEnoughData expected at byte "
            + i.string())
        return
      end
      i = i + 1
    end

    sd.append(
      recover val
        [as U8: bytes(bytes.size() - 1)?]
      end)

    match sd.skip()
    | None => None
    else
      h.fail("expected None after all bytes")
    end

class \nodoc\ _PropertyStreamSkipFixext4Safety
  is Property1[U8]
  """
  For any ext_type byte, encoding a fixext_4 and feeding
  byte-by-byte, skip() returns NotEnoughData until the last
  byte, then None.
  """
  fun name(): String =>
    "msgpack/PropertyStreamSkipFixext4Safety"

  fun gen(): Generator[U8] =>
    Generators.u8()

  fun ref property(arg1: U8, h: PropertyHelper) ? =>
    let data =
      recover val [as U8: 'A'; 'B'; 'C'; 'D'] end
    let w: Writer ref = Writer
    if arg1 == 0xFF then
      // Timestamp wire format for ext_type 0xFF
      MessagePackEncoder.timestamp_32(w, 1000)
    else
      MessagePackEncoder.fixext_4(w, arg1, data)?
    end
    let bytes = _WriterBytes(w)
    let sd = MessagePackStreamingDecoder

    var i: USize = 0
    while i < (bytes.size() - 1) do
      sd.append(
        recover val [as U8: bytes(i)?] end)
      match sd.skip()
      | NotEnoughData => None
      else
        h.fail(
          "NotEnoughData expected at byte "
            + i.string())
        return
      end
      i = i + 1
    end

    sd.append(
      recover val
        [as U8: bytes(bytes.size() - 1)?]
      end)

    match sd.skip()
    | None => None
    else
      h.fail("expected None after all bytes")
    end

class \nodoc\ _PropertyStreamSkipBin16Safety
  is Property1[U8]
  """
  For any small byte array, encoding as bin_16 and feeding
  byte-by-byte, skip() returns NotEnoughData until the last
  byte, then None.
  """
  fun name(): String =>
    "msgpack/PropertyStreamSkipBin16Safety"

  fun gen(): Generator[U8] =>
    Generators.u8()

  fun ref property(arg1: U8, h: PropertyHelper) ? =>
    let data = recover val
      Array[U8].init('X', arg1.usize())
    end
    let w: Writer ref = Writer
    MessagePackEncoder.bin_16(w, data)?
    let bytes = _WriterBytes(w)
    let sd = MessagePackStreamingDecoder

    var i: USize = 0
    while i < (bytes.size() - 1) do
      sd.append(
        recover val [as U8: bytes(i)?] end)
      match sd.skip()
      | NotEnoughData => None
      else
        h.fail(
          "NotEnoughData expected at byte "
            + i.string())
        return
      end
      i = i + 1
    end

    sd.append(
      recover val
        [as U8: bytes(bytes.size() - 1)?]
      end)

    match sd.skip()
    | None => None
    else
      h.fail("expected None after all bytes")
    end

class \nodoc\ _PropertyStreamSkipLimitArray
  is Property1[U16]
  """
  Generate arrays with varying element counts, skip with
  small max_skip_values, verify LimitExceeded when element
  count + 1 exceeds limit and None when within limit.
  """
  fun name(): String =>
    "msgpack/PropertyStreamSkipLimitArray"

  fun gen(): Generator[U16] =>
    Generators.u16(0, 100)

  fun ref property(arg1: U16, h: PropertyHelper) =>
    let count = arg1.u32()
    let max_skip: USize = 50

    let w: Writer ref = Writer
    MessagePackEncoder.array(w, count)
    var i: U32 = 0
    while i < count do
      MessagePackEncoder.uint(w, 1)
      i = i + 1
    end

    let sd = MessagePackStreamingDecoder(
      MessagePackDecodeLimits(
        where max_skip_values' = max_skip))
    sd.append(_WriterBytes(w))

    // Total values traversed = count + 1 (the array itself)
    if (count.usize() + 1) > max_skip then
      match sd.skip()
      | LimitExceeded => None
      else
        h.fail(
          "expected LimitExceeded for count "
            + count.string())
      end
    else
      match sd.skip()
      | None => None
      else
        h.fail(
          "expected None for count "
            + count.string())
      end
    end
