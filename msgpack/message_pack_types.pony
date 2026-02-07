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

primitive NotEnoughData
  """
  Returned when the reader doesn't have enough data to decode the
  next value. The caller should append more data and retry.
  No bytes have been consumed from the reader.
  """

primitive InvalidData
  """
  Returned when the data contains an invalid MessagePack format
  byte. The stream is corrupt and decoding should stop.
  """

class val MessagePackArray
  """
  Header for a MessagePack array. The `size` field indicates how
  many elements follow. The caller is responsible for reading
  `size` subsequent values.
  """
  let size: U32

  new val create(size': U32) =>
    size = size'

class val MessagePackMap
  """
  Header for a MessagePack map. The `size` field indicates how
  many key-value pairs follow. The caller is responsible for
  reading `size * 2` subsequent values (alternating keys and
  values).
  """
  let size: U32

  new val create(size': U32) =>
    size = size'

class val MessagePackTimestamp
  """
  A decoded MessagePack timestamp. The `sec` field is the number
  of seconds since 1970-01-01 00:00:00 UTC (can be negative for
  dates before the epoch). The `nsec` field is the nanoseconds
  component (0 to 999999999).
  """
  let sec: I64
  let nsec: U32

  new val create(sec': I64, nsec': U32) =>
    sec = sec'
    nsec = nsec'

class val MessagePackExt
  """
  A MessagePack extension type. The `ext_type` field is the
  type identifier stored as a `U8`. User-defined types occupy
  0 through 127. The MessagePack spec reserves -1 through -128
  (signed) for predefined types (e.g., -1 for timestamps);
  these appear in `ext_type` as their unsigned equivalents
  (0xFF for -1, 0x80 for -128). The `data` field contains the
  raw extension bytes.
  """
  let ext_type: U8
  let data: Array[U8] val

  new val create(ext_type': U8, data': Array[U8] val) =>
    ext_type = ext_type'
    data = data'

/*
Union of all possible values returned by the streaming decoder.

Multiple MessagePack wire formats collapse into the same Pony
type. For example:

* `positive_fixint` (1 byte) and `uint_8` (2 bytes) both
  decode to `U8`.
* `negative_fixint` (1 byte) and `int_8` (2 bytes) both
  decode to `I8`.
* `fixstr`, `str_8`, `str_16`, and `str_32` all decode to
  `String val`.
* `fixarray`, `array_16`, and `array_32` all decode to
  `MessagePackArray`.
* `fixmap`, `map_16`, and `map_32` all decode to
  `MessagePackMap`.
* `bin_8`, `bin_16`, and `bin_32` all decode to
  `Array[U8] val`.
* `fixext_1/2/4/8/16`, `ext_8`, `ext_16`, and `ext_32` all
  decode to `MessagePackExt`.

This is an intentional trade-off: a value-oriented API has no
reason to preserve the encoding's size optimization choices.
A caller seeing `U8(42)` cannot tell whether the encoder used
the compact `positive_fixint` or the explicit `uint_8` format.
*/
type MessagePackValue is
  ( None
  | Bool
  | U8 | U16 | U32 | U64
  | I8 | I16 | I32 | I64
  | F32 | F64
  | String val
  | Array[U8] val
  | MessagePackArray
  | MessagePackMap
  | MessagePackExt
  | MessagePackTimestamp
  )

type DecodeResult is
  (MessagePackValue | NotEnoughData | InvalidData)
