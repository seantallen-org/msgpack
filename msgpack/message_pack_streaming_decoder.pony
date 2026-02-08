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

class MessagePackStreamingDecoder
  """
  A streaming-safe MessagePack decoder that never corrupts the
  underlying reader on insufficient data.

  Unlike `MessagePackDecoder`, which assumes all data is available
  and will corrupt the reader's state on partial reads, this class
  peeks at the format byte and any length fields before consuming
  any bytes. If insufficient data is available, it returns
  `NotEnoughData` with zero bytes consumed, allowing the caller to
  append more data and retry.

  Usage:
  ```pony
  let decoder = MessagePackStreamingDecoder
  decoder.append(chunk1)
  match decoder.next()
  | let v: U32 => // got a value
  | NotEnoughData => // need more data, append and retry
  | InvalidData => // corrupt stream, abort
  end
  ```

  Container types (arrays and maps) return header objects
  (`MessagePackArray` / `MessagePackMap`) containing the element
  count. The caller is responsible for subsequently reading that
  many values.
  """
  let _reader: Reader ref

  new create() =>
    _reader = Reader

  fun ref append(data: ByteSeq) =>
    """
    Append data to the internal reader. Call this as chunks arrive.
    """
    _reader.append(data)

  fun ref next(): DecodeResult =>
    """
    Attempt to decode the next MessagePack value.

    Returns one of:
    - A `MessagePackValue` if a complete value was decoded
    - `NotEnoughData` if more bytes are needed (no bytes consumed)
    - `InvalidData` if the format byte is invalid (0xC1).
      The invalid byte is NOT consumed. The caller must stop
      calling `next()` after receiving `InvalidData` — the
      stream is corrupt and cannot be resynced.
    """
    if _reader.size() == 0 then
      return NotEnoughData
    end

    let fb: U8 =
      try _reader.peek_u8()?
      else return NotEnoughData
      end

    if fb <= 0x7F then
      _decode_positive_fixint()
    elseif fb <= 0x8F then
      _decode_fixmap()
    elseif fb <= 0x9F then
      _decode_fixarray()
    elseif fb <= 0xBF then
      _decode_fixstr(fb)
    elseif fb == 0xC0 then
      _decode_nil()
    elseif fb == 0xC1 then
      InvalidData
    elseif fb <= 0xC3 then
      _decode_bool()
    elseif fb <= 0xC6 then
      _decode_bin(fb)
    elseif fb <= 0xC9 then
      _decode_ext_variable(fb)
    elseif fb == 0xCA then
      _decode_float_32()
    elseif fb == 0xCB then
      _decode_float_64()
    elseif fb <= 0xCF then
      _decode_uint(fb)
    elseif fb <= 0xD3 then
      _decode_int(fb)
    elseif fb <= 0xD8 then
      _decode_fixext(fb)
    elseif fb <= 0xDB then
      _decode_str(fb)
    elseif fb <= 0xDD then
      _decode_array(fb)
    elseif fb <= 0xDF then
      _decode_map(fb)
    else
      _decode_negative_fixint()
    end

  //
  // Fixed-size single-byte formats
  //

  fun ref _decode_positive_fixint(): DecodeResult =>
    // 0x00-0x7F: value is the byte itself
    try _reader.u8()?
    else
      _Unreachable()
      InvalidData
    end

  fun ref _decode_negative_fixint(): DecodeResult =>
    // 0xE0-0xFF: value is the byte as I8
    try _reader.i8()?
    else
      _Unreachable()
      InvalidData
    end

  fun ref _decode_nil(): DecodeResult =>
    // 0xC0: 1 byte total
    try
      MessagePackDecoder.nil(_reader)?
    else
      _Unreachable()
      InvalidData
    end

  fun ref _decode_bool(): DecodeResult =>
    // 0xC2/0xC3: 1 byte total
    try
      MessagePackDecoder.bool(_reader)?
    else
      _Unreachable()
      InvalidData
    end

  //
  // Fixed-size numeric formats
  //

  fun ref _decode_float_32(): DecodeResult =>
    // 0xCA: 1 type + 4 data = 5 bytes
    if _reader.size() < 5 then return NotEnoughData end
    try MessagePackDecoder.f32(_reader)?
    else
      _Unreachable()
      InvalidData
    end

  fun ref _decode_float_64(): DecodeResult =>
    // 0xCB: 1 type + 8 data = 9 bytes
    if _reader.size() < 9 then return NotEnoughData end
    try MessagePackDecoder.f64(_reader)?
    else
      _Unreachable()
      InvalidData
    end

  fun ref _decode_uint(fb: U8): DecodeResult =>
    // 0xCC: uint_8, 2 bytes
    // 0xCD: uint_16, 3 bytes
    // 0xCE: uint_32, 5 bytes
    // 0xCF: uint_64, 9 bytes
    let required: USize =
      if fb == _FormatName.uint_8() then 2
      elseif fb == _FormatName.uint_16() then 3
      elseif fb == _FormatName.uint_32() then 5
      else 9
      end

    if _reader.size() < required then return NotEnoughData end

    try
      if fb == _FormatName.uint_8() then
        MessagePackDecoder.u8(_reader)?
      elseif fb == _FormatName.uint_16() then
        MessagePackDecoder.u16(_reader)?
      elseif fb == _FormatName.uint_32() then
        MessagePackDecoder.u32(_reader)?
      else
        MessagePackDecoder.u64(_reader)?
      end
    else
      _Unreachable()
      InvalidData
    end

  fun ref _decode_int(fb: U8): DecodeResult =>
    // 0xD0: int_8, 2 bytes
    // 0xD1: int_16, 3 bytes
    // 0xD2: int_32, 5 bytes
    // 0xD3: int_64, 9 bytes
    let required: USize =
      if fb == _FormatName.int_8() then 2
      elseif fb == _FormatName.int_16() then 3
      elseif fb == _FormatName.int_32() then 5
      else 9
      end

    if _reader.size() < required then return NotEnoughData end

    try
      if fb == _FormatName.int_8() then
        MessagePackDecoder.i8(_reader)?
      elseif fb == _FormatName.int_16() then
        MessagePackDecoder.i16(_reader)?
      elseif fb == _FormatName.int_32() then
        MessagePackDecoder.i32(_reader)?
      else
        MessagePackDecoder.i64(_reader)?
      end
    else
      _Unreachable()
      InvalidData
    end

  //
  // Variable-length string formats
  //

  fun ref _decode_fixstr(fb: U8): DecodeResult =>
    // 0xA0-0xBF: 1 format byte + (fb AND fixstr mask) data bytes
    let data_len = fb.usize() and _Limit.fixstr()
    if _reader.size() < (1 + data_len) then
      return NotEnoughData
    end
    try MessagePackDecoder.fixstr(_reader)?
    else
      _Unreachable()
      InvalidData
    end

  fun ref _decode_str(fb: U8): DecodeResult =>
    // 0xD9: str_8, header=2, len=peek_u8(1)
    // 0xDA: str_16, header=3, len=peek_u16_be(1)
    // 0xDB: str_32, header=5, len=peek_u32_be(1)
    let header_size: USize =
      if fb == _FormatName.str_8() then 2
      elseif fb == _FormatName.str_16() then 3
      else 5
      end

    if _reader.size() < header_size then
      return NotEnoughData
    end

    let data_len: USize =
      try
        if fb == _FormatName.str_8() then
          _reader.peek_u8(1)?.usize()
        elseif fb == _FormatName.str_16() then
          _reader.peek_u16_be(1)?.usize()
        else
          _reader.peek_u32_be(1)?.usize()
        end
      else
        return NotEnoughData
      end

    if _reader.size() < (header_size + data_len) then
      return NotEnoughData
    end

    try
      if fb == _FormatName.str_8() then
        MessagePackDecoder.str_8(_reader)?
      elseif fb == _FormatName.str_16() then
        MessagePackDecoder.str_16(_reader)?
      else
        MessagePackDecoder.str_32(_reader)?
      end
    else
      _Unreachable()
      InvalidData
    end

  //
  // Binary format
  //

  fun ref _decode_bin(fb: U8): DecodeResult =>
    // 0xC4: bin_8, header=2, len=peek_u8(1)
    // 0xC5: bin_16, header=3, len=peek_u16_be(1)
    // 0xC6: bin_32, header=5, len=peek_u32_be(1)
    let header_size: USize =
      if fb == _FormatName.bin_8() then 2
      elseif fb == _FormatName.bin_16() then 3
      else 5
      end

    if _reader.size() < header_size then
      return NotEnoughData
    end

    let data_len: USize =
      try
        if fb == _FormatName.bin_8() then
          _reader.peek_u8(1)?.usize()
        elseif fb == _FormatName.bin_16() then
          _reader.peek_u16_be(1)?.usize()
        else
          _reader.peek_u32_be(1)?.usize()
        end
      else
        return NotEnoughData
      end

    if _reader.size() < (header_size + data_len) then
      return NotEnoughData
    end

    try
      if fb == _FormatName.bin_8() then
        MessagePackDecoder.bin_8(_reader)?
      elseif fb == _FormatName.bin_16() then
        MessagePackDecoder.bin_16(_reader)?
      else
        MessagePackDecoder.bin_32(_reader)?
      end
    else
      _Unreachable()
      InvalidData
    end

  //
  // Array format
  //

  fun ref _decode_fixarray(): DecodeResult =>
    // 0x90-0x9F: 1 byte header
    try
      MessagePackArray(
        MessagePackDecoder.fixarray(_reader)?.u32())
    else
      _Unreachable()
      InvalidData
    end

  fun ref _decode_array(fb: U8): DecodeResult =>
    // 0xDC: array_16, 3 bytes (1 type + 2 count)
    // 0xDD: array_32, 5 bytes (1 type + 4 count)
    let required: USize =
      if fb == _FormatName.array_16() then 3
      else 5
      end

    if _reader.size() < required then return NotEnoughData end

    try
      if fb == _FormatName.array_16() then
        MessagePackArray(
          MessagePackDecoder.array_16(_reader)?.u32())
      else
        MessagePackArray(
          MessagePackDecoder.array_32(_reader)?)
      end
    else
      _Unreachable()
      InvalidData
    end

  //
  // Map format
  //

  fun ref _decode_fixmap(): DecodeResult =>
    // 0x80-0x8F: 1 byte header
    try
      MessagePackMap(
        MessagePackDecoder.fixmap(_reader)?.u32())
    else
      _Unreachable()
      InvalidData
    end

  fun ref _decode_map(fb: U8): DecodeResult =>
    // 0xDE: map_16, 3 bytes (1 type + 2 count)
    // 0xDF: map_32, 5 bytes (1 type + 4 count)
    let required: USize =
      if fb == _FormatName.map_16() then 3
      else 5
      end

    if _reader.size() < required then return NotEnoughData end

    try
      if fb == _FormatName.map_16() then
        MessagePackMap(
          MessagePackDecoder.map_16(_reader)?.u32())
      else
        MessagePackMap(
          MessagePackDecoder.map_32(_reader)?)
      end
    else
      _Unreachable()
      InvalidData
    end

  //
  // Fixed-size extension formats
  //

  fun ref _decode_fixext(fb: U8): DecodeResult =>
    // 0xD4: fixext_1, 3 bytes (1 type + 1 ext_type + 1 data)
    // 0xD5: fixext_2, 4 bytes
    // 0xD6: fixext_4, 6 bytes
    // 0xD7: fixext_8, 10 bytes
    // 0xD8: fixext_16, 18 bytes
    let required: USize =
      if fb == _FormatName.fixext_1() then 3
      elseif fb == _FormatName.fixext_2() then 4
      elseif fb == _FormatName.fixext_4() then 6
      elseif fb == _FormatName.fixext_8() then 10
      else 18
      end

    if _reader.size() < required then return NotEnoughData end

    // Timestamp: fixext_4 or fixext_8 with ext_type 0xFF
    if (fb == _FormatName.fixext_4())
      or (fb == _FormatName.fixext_8())
    then
      try
        if _reader.peek_u8(1)? == 0xFF then
          return _decode_timestamp()
        end
      else
        _Unreachable()
        return InvalidData
      end
    end

    try
      (let t, let d) =
        if fb == _FormatName.fixext_1() then
          MessagePackDecoder.fixext_1(_reader)?
        elseif fb == _FormatName.fixext_2() then
          MessagePackDecoder.fixext_2(_reader)?
        elseif fb == _FormatName.fixext_4() then
          MessagePackDecoder.fixext_4(_reader)?
        elseif fb == _FormatName.fixext_8() then
          MessagePackDecoder.fixext_8(_reader)?
        else
          MessagePackDecoder.fixext_16(_reader)?
        end
      MessagePackExt(t, d)
    else
      _Unreachable()
      InvalidData
    end

  //
  // Variable-length extension formats
  //

  fun ref _decode_ext_variable(fb: U8): DecodeResult =>
    // 0xC7: ext_8, header=2 (1+1len), +1 type + data
    // 0xC8: ext_16, header=3 (1+2len), +1 type + data
    // 0xC9: ext_32, header=5 (1+4len), +1 type + data
    let header_size: USize =
      if fb == _FormatName.ext_8() then 2
      elseif fb == _FormatName.ext_16() then 3
      else 5
      end

    if _reader.size() < header_size then
      return NotEnoughData
    end

    let data_len: USize =
      try
        if fb == _FormatName.ext_8() then
          _reader.peek_u8(1)?.usize()
        elseif fb == _FormatName.ext_16() then
          _reader.peek_u16_be(1)?.usize()
        else
          _reader.peek_u32_be(1)?.usize()
        end
      else
        return NotEnoughData
      end

    // Total: header bytes + 1 type byte + data bytes
    let total = header_size + 1 + data_len
    if _reader.size() < total then
      return NotEnoughData
    end

    // Timestamp: ext_8 with data_len=12 and ext_type 0xFF
    if (fb == _FormatName.ext_8()) and (data_len == 12) then
      try
        if _reader.peek_u8(2)? == 0xFF then
          return _decode_timestamp()
        end
      else
        _Unreachable()
        return InvalidData
      end
    end

    try
      (let t, let d) =
        if fb == _FormatName.ext_8() then
          MessagePackDecoder.ext_8(_reader)?
        elseif fb == _FormatName.ext_16() then
          MessagePackDecoder.ext_16(_reader)?
        else
          MessagePackDecoder.ext_32(_reader)?
        end
      MessagePackExt(t, d)
    else
      _Unreachable()
      InvalidData
    end

  //
  // Timestamp format
  //

  fun ref _decode_timestamp(): DecodeResult =>
    try
      (let sec, let nsec) = MessagePackDecoder.timestamp(_reader)?
      MessagePackTimestamp(sec, nsec)
    else
      _Unreachable()
      InvalidData
    end
