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

actor _TestDecoder is TestList
  new make() =>
    None

  fun tag tests(test: PonyTest) =>
    test(_TestDecodeNil)
    test(_TestDecodeTrue)
    test(_TestDecodeFalse)

class _TestDecodeNil is UnitTest
  fun name(): String =>
    "msgpack/DecodeNil"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    let b = Reader

    MessagePackEncoder.nil(w)

    for bs in w.done().values() do
      try
        b.append(bs as Array[U8] val)
      end
    end

    MessagePackDecoder.nil(consume b)?

class _TestDecodeTrue is UnitTest
  fun name(): String =>
    "msgpack/DecodeTrue"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    let b = Reader

    MessagePackEncoder.bool(w, true)

    for bs in w.done().values() do
      try
        b.append(bs as Array[U8] val)
      end
    end

    h.assert_true(MessagePackDecoder.bool(consume b)?)

class _TestDecodeFalse is UnitTest
  fun name(): String =>
    "msgpack/DecodeFalse"

  fun ref apply(h: TestHelper) ? =>
    let w: Writer ref = Writer
    let b = Reader

    MessagePackEncoder.bool(w, false)

    for bs in w.done().values() do
      try
        b.append(bs as Array[U8] val)
      end
    end

    h.assert_false(MessagePackDecoder.bool(consume b)?)
