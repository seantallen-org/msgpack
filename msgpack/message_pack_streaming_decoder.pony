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

  Limits protect against denial-of-service attacks where a
  malicious payload claims enormous sizes for variable-length
  values or deeply nested containers. By default, conservative
  limits are applied (1 MB for str/bin/ext, 131,072 for
  array/map counts, 512 for container nesting depth). When a
  value exceeds its limit, `next()` returns `LimitExceeded`
  with zero bytes consumed.

  The decoder automatically tracks container nesting depth.
  When `next()` returns a `MessagePackArray` or
  `MessagePackMap`, the depth counter increments. As the
  caller reads elements and containers are exhausted, the
  depth counter decrements automatically. Use `depth()` to
  inspect the current nesting level.

  When `validate_utf8` is `true`, decoded str values are
  validated for UTF-8 correctness. If a str value contains
  invalid UTF-8 byte sequences, `next()` returns `InvalidUtf8`
  instead of the decoded string. The bytes have been consumed
  from the reader and decoding can continue. By default,
  validation is off for backward compatibility.

  Usage:
  ```pony
  // Default conservative limits, no UTF-8 validation:
  let decoder = MessagePackStreamingDecoder
  decoder.append(chunk1)
  match decoder.next()
  | let v: U32 => // got a value
  | NotEnoughData => // need more data, append and retry
  | LimitExceeded => // value too large or too deep, reject
  | InvalidData => // corrupt stream, abort
  end

  // Custom limits:
  let limits = MessagePackDecodeLimits(
    where max_str_len' = 4096,
          max_depth' = 16)
  let decoder = MessagePackStreamingDecoder(limits)

  // With UTF-8 validation:
  let decoder = MessagePackStreamingDecoder(
    where validate_utf8' = true)
  match decoder.next()
  | InvalidUtf8 => // str value had invalid UTF-8
  end

  // No limits:
  let decoder = MessagePackStreamingDecoder(
    MessagePackDecodeLimits.unlimited())
  ```

  Container types (arrays and maps) return header objects
  (`MessagePackArray` / `MessagePackMap`) containing the element
  count. The caller is responsible for subsequently reading that
  many values.
  """
  let _reader: ZeroCopyReader ref
  let _limits: MessagePackDecodeLimits val
  let _validate_utf8: Bool
  let _stack: Array[USize]

  new create(
    limits: MessagePackDecodeLimits val
      = MessagePackDecodeLimits,
    validate_utf8': Bool = false)
  =>
    _reader = ZeroCopyReader
    _limits = limits
    _validate_utf8 = validate_utf8'
    _stack = Array[USize]

  fun ref append(data: ByteSeq) =>
    """
    Append data to the internal reader. Call this as chunks arrive.
    """
    _reader.append(data)

  fun depth(): USize =>
    """
    Returns the current container nesting depth. Depth increases
    when `next()` returns `MessagePackArray` or `MessagePackMap`,
    and decreases automatically as elements are consumed.
    """
    _stack.size()

  fun ref next(): DecodeResult =>
    """
    Attempt to decode the next MessagePack value.

    Returns one of:
    - A `MessagePackValue` if a complete value was decoded
    - `NotEnoughData` if more bytes are needed (no bytes consumed)
    - `LimitExceeded` if the value exceeds a configured size
      limit (no bytes consumed)
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

    _track(
      if fb <= 0x7F then
        _decode_positive_fixint()
      elseif fb <= 0x8F then
        _decode_fixmap(fb)
      elseif fb <= 0x9F then
        _decode_fixarray(fb)
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
    )

  fun ref skip(): SkipResult =>
    """
    Advances past one complete MessagePack value without
    decoding it. For containers (arrays and maps), skips all
    contained elements.

    Returns `None` on success, `NotEnoughData` if more bytes
    are needed (no bytes consumed), `InvalidData` if the
    format byte is invalid (no bytes consumed), or
    `LimitExceeded` if the number of values traversed exceeds
    the configured `max_skip_values` limit (no bytes
    consumed).

    Like `next()`, a successful skip decrements the parent
    container's remaining element count when called inside a
    container.
    """
    if _reader.size() == 0 then
      return NotEnoughData
    end

    var offset: USize = 0
    var remaining: USize = 1
    var values_seen: USize = 0

    while remaining > 0 do
      remaining = remaining - 1
      values_seen = values_seen + 1
      if values_seen > _limits.max_skip_values then
        return LimitExceeded
      end

      let fb =
        try _reader.peek_u8(offset)?
        else return NotEnoughData
        end

      if fb <= 0x7F then
        // positive fixint: 1 byte
        offset = offset + 1
      elseif fb <= 0x8F then
        // fixmap: 1 byte header, count * 2 values
        remaining = remaining
          + ((fb and 0x0F).usize() * 2)
        offset = offset + 1
      elseif fb <= 0x9F then
        // fixarray: 1 byte header, count values
        remaining = remaining
          + (fb and 0x0F).usize()
        offset = offset + 1
      elseif fb <= 0xBF then
        // fixstr: 1 byte header + data
        offset = offset + 1
          + (fb and 0x1F).usize()
      elseif fb == 0xC0 then
        // nil: 1 byte
        offset = offset + 1
      elseif fb == 0xC1 then
        return InvalidData
      elseif fb <= 0xC3 then
        // bool: 1 byte
        offset = offset + 1
      elseif fb <= 0xC6 then
        // bin_8/16/32
        if fb == _FormatName.bin_8() then
          let len =
            try _reader.peek_u8(offset + 1)?.usize()
            else return NotEnoughData
            end
          offset = offset + 2 + len
        elseif fb == _FormatName.bin_16() then
          let len =
            try
              _reader.peek_u16_be(offset + 1)?
                .usize()
            else return NotEnoughData
            end
          offset = offset + 3 + len
        else
          let len =
            try
              _reader.peek_u32_be(offset + 1)?
                .usize()
            else return NotEnoughData
            end
          offset = offset + 5 + len
        end
      elseif fb <= 0xC9 then
        // ext_8/16/32: header + 1 ext_type + data
        if fb == _FormatName.ext_8() then
          let len =
            try _reader.peek_u8(offset + 1)?.usize()
            else return NotEnoughData
            end
          offset = offset + 3 + len
        elseif fb == _FormatName.ext_16() then
          let len =
            try
              _reader.peek_u16_be(offset + 1)?
                .usize()
            else return NotEnoughData
            end
          offset = offset + 4 + len
        else
          let len =
            try
              _reader.peek_u32_be(offset + 1)?
                .usize()
            else return NotEnoughData
            end
          offset = offset + 6 + len
        end
      elseif fb == 0xCA then
        // float_32: 5 bytes
        offset = offset + 5
      elseif fb == 0xCB then
        // float_64: 9 bytes
        offset = offset + 9
      elseif fb <= 0xCF then
        // uint_8/16/32/64
        if fb == _FormatName.uint_8() then
          offset = offset + 2
        elseif fb == _FormatName.uint_16() then
          offset = offset + 3
        elseif fb == _FormatName.uint_32() then
          offset = offset + 5
        else
          offset = offset + 9
        end
      elseif fb <= 0xD3 then
        // int_8/16/32/64
        if fb == _FormatName.int_8() then
          offset = offset + 2
        elseif fb == _FormatName.int_16() then
          offset = offset + 3
        elseif fb == _FormatName.int_32() then
          offset = offset + 5
        else
          offset = offset + 9
        end
      elseif fb <= 0xD8 then
        // fixext_1/2/4/8/16
        if fb == _FormatName.fixext_1() then
          offset = offset + 3
        elseif fb == _FormatName.fixext_2() then
          offset = offset + 4
        elseif fb == _FormatName.fixext_4() then
          offset = offset + 6
        elseif fb == _FormatName.fixext_8() then
          offset = offset + 10
        else
          offset = offset + 18
        end
      elseif fb <= 0xDB then
        // str_8/16/32
        if fb == _FormatName.str_8() then
          let len =
            try _reader.peek_u8(offset + 1)?.usize()
            else return NotEnoughData
            end
          offset = offset + 2 + len
        elseif fb == _FormatName.str_16() then
          let len =
            try
              _reader.peek_u16_be(offset + 1)?
                .usize()
            else return NotEnoughData
            end
          offset = offset + 3 + len
        else
          let len =
            try
              _reader.peek_u32_be(offset + 1)?
                .usize()
            else return NotEnoughData
            end
          offset = offset + 5 + len
        end
      elseif fb <= 0xDD then
        // array_16/32
        if fb == _FormatName.array_16() then
          let count =
            try
              _reader.peek_u16_be(offset + 1)?
                .usize()
            else return NotEnoughData
            end
          remaining = remaining + count
          offset = offset + 3
        else
          let count =
            try
              _reader.peek_u32_be(offset + 1)?
                .usize()
            else return NotEnoughData
            end
          remaining = remaining + count
          offset = offset + 5
        end
      elseif fb <= 0xDF then
        // map_16/32
        if fb == _FormatName.map_16() then
          let count =
            try
              _reader.peek_u16_be(offset + 1)?
                .usize()
            else return NotEnoughData
            end
          remaining = remaining + (count * 2)
          offset = offset + 3
        else
          let count =
            try
              _reader.peek_u32_be(offset + 1)?
                .usize()
            else return NotEnoughData
            end
          remaining = remaining + (count * 2)
          offset = offset + 5
        end
      else
        // negative fixint: 1 byte
        offset = offset + 1
      end
    end

    if _reader.size() < offset then
      return NotEnoughData
    end

    try _reader.skip(offset)?
    else
      _Unreachable()
      return InvalidData
    end
    _decrement_parent()
    _drain_completed()
    None

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
      MessagePackZeroCopyDecoder.nil(_reader)?
    else
      _Unreachable()
      InvalidData
    end

  fun ref _decode_bool(): DecodeResult =>
    // 0xC2/0xC3: 1 byte total
    try
      MessagePackZeroCopyDecoder.bool(_reader)?
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
    try MessagePackZeroCopyDecoder.f32(_reader)?
    else
      _Unreachable()
      InvalidData
    end

  fun ref _decode_float_64(): DecodeResult =>
    // 0xCB: 1 type + 8 data = 9 bytes
    if _reader.size() < 9 then return NotEnoughData end
    try MessagePackZeroCopyDecoder.f64(_reader)?
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
        MessagePackZeroCopyDecoder.u8(_reader)?
      elseif fb == _FormatName.uint_16() then
        MessagePackZeroCopyDecoder.u16(_reader)?
      elseif fb == _FormatName.uint_32() then
        MessagePackZeroCopyDecoder.u32(_reader)?
      else
        MessagePackZeroCopyDecoder.u64(_reader)?
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
        MessagePackZeroCopyDecoder.i8(_reader)?
      elseif fb == _FormatName.int_16() then
        MessagePackZeroCopyDecoder.i16(_reader)?
      elseif fb == _FormatName.int_32() then
        MessagePackZeroCopyDecoder.i32(_reader)?
      else
        MessagePackZeroCopyDecoder.i64(_reader)?
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
    if data_len > _limits.max_str_len then
      return LimitExceeded
    end
    if _reader.size() < (1 + data_len) then
      return NotEnoughData
    end
    try
      let s = MessagePackZeroCopyDecoder.fixstr(_reader)?
      if _validate_utf8
        and not MessagePackValidateUTF8(s)
      then
        return InvalidUtf8
      end
      s
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

    if data_len > _limits.max_str_len then
      return LimitExceeded
    end

    if _reader.size() < (header_size + data_len) then
      return NotEnoughData
    end

    try
      let s = if fb == _FormatName.str_8() then
        MessagePackZeroCopyDecoder.str_8(_reader)?
      elseif fb == _FormatName.str_16() then
        MessagePackZeroCopyDecoder.str_16(_reader)?
      else
        MessagePackZeroCopyDecoder.str_32(_reader)?
      end
      if _validate_utf8
        and not MessagePackValidateUTF8(s)
      then
        return InvalidUtf8
      end
      s
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

    if data_len > _limits.max_bin_len then
      return LimitExceeded
    end

    if _reader.size() < (header_size + data_len) then
      return NotEnoughData
    end

    try
      if fb == _FormatName.bin_8() then
        MessagePackZeroCopyDecoder.bin_8(_reader)?
      elseif fb == _FormatName.bin_16() then
        MessagePackZeroCopyDecoder.bin_16(_reader)?
      else
        MessagePackZeroCopyDecoder.bin_32(_reader)?
      end
    else
      _Unreachable()
      InvalidData
    end

  //
  // Array format
  //

  fun ref _decode_fixarray(fb: U8): DecodeResult =>
    // 0x90-0x9F: 1 byte header, count in low 4 bits
    let count = (fb and 0x0F).u32()
    if count > _limits.max_array_len then
      return LimitExceeded
    end
    if _stack.size() >= _limits.max_depth then
      return LimitExceeded
    end
    try
      MessagePackArray(
        MessagePackZeroCopyDecoder.fixarray(_reader)?.u32())
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

    let count: U32 =
      try
        if fb == _FormatName.array_16() then
          _reader.peek_u16_be(1)?.u32()
        else
          _reader.peek_u32_be(1)?
        end
      else
        return NotEnoughData
      end

    if count > _limits.max_array_len then
      return LimitExceeded
    end
    if _stack.size() >= _limits.max_depth then
      return LimitExceeded
    end

    try
      if fb == _FormatName.array_16() then
        MessagePackArray(
          MessagePackZeroCopyDecoder.array_16(_reader)?.u32())
      else
        MessagePackArray(
          MessagePackZeroCopyDecoder.array_32(_reader)?)
      end
    else
      _Unreachable()
      InvalidData
    end

  //
  // Map format
  //

  fun ref _decode_fixmap(fb: U8): DecodeResult =>
    // 0x80-0x8F: 1 byte header, count in low 4 bits
    let count = (fb and 0x0F).u32()
    if count > _limits.max_map_len then
      return LimitExceeded
    end
    if _stack.size() >= _limits.max_depth then
      return LimitExceeded
    end
    try
      MessagePackMap(
        MessagePackZeroCopyDecoder.fixmap(_reader)?.u32())
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

    let count: U32 =
      try
        if fb == _FormatName.map_16() then
          _reader.peek_u16_be(1)?.u32()
        else
          _reader.peek_u32_be(1)?
        end
      else
        return NotEnoughData
      end

    if count > _limits.max_map_len then
      return LimitExceeded
    end
    if _stack.size() >= _limits.max_depth then
      return LimitExceeded
    end

    try
      if fb == _FormatName.map_16() then
        MessagePackMap(
          MessagePackZeroCopyDecoder.map_16(_reader)?.u32())
      else
        MessagePackMap(
          MessagePackZeroCopyDecoder.map_32(_reader)?)
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

    // Data length is total minus format byte and ext_type byte
    if (required - 2) > _limits.max_ext_len then
      return LimitExceeded
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
          MessagePackZeroCopyDecoder.fixext_1(_reader)?
        elseif fb == _FormatName.fixext_2() then
          MessagePackZeroCopyDecoder.fixext_2(_reader)?
        elseif fb == _FormatName.fixext_4() then
          MessagePackZeroCopyDecoder.fixext_4(_reader)?
        elseif fb == _FormatName.fixext_8() then
          MessagePackZeroCopyDecoder.fixext_8(_reader)?
        else
          MessagePackZeroCopyDecoder.fixext_16(_reader)?
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

    if data_len > _limits.max_ext_len then
      return LimitExceeded
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
          MessagePackZeroCopyDecoder.ext_8(_reader)?
        elseif fb == _FormatName.ext_16() then
          MessagePackZeroCopyDecoder.ext_16(_reader)?
        else
          MessagePackZeroCopyDecoder.ext_32(_reader)?
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
      (let sec, let nsec) = MessagePackZeroCopyDecoder.timestamp(_reader)?
      MessagePackTimestamp(sec, nsec)
    else
      _Unreachable()
      InvalidData
    end

  //
  // Container depth tracking
  //

  fun ref _track(result: DecodeResult): DecodeResult =>
    match result
    | let a: MessagePackArray =>
      _decrement_parent()
      _stack.push(a.size.usize())
      _drain_completed()
      result
    | let m: MessagePackMap =>
      _decrement_parent()
      _stack.push(m.size.usize() * 2)
      _drain_completed()
      result
    | NotEnoughData => result
    | InvalidData => result
    | LimitExceeded => result
    else
      // scalar value
      _decrement_parent()
      _drain_completed()
      result
    end

  fun ref _decrement_parent() =>
    if _stack.size() > 0 then
      try
        let idx = _stack.size() - 1
        _stack(idx)? = _stack(idx)? - 1
      end
    end

  fun ref _drain_completed() =>
    try
      while (_stack.size() > 0)
        and (_stack(_stack.size() - 1)? == 0)
      do
        _stack.pop()?
      end
    end
