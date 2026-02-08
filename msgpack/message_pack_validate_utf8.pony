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

primitive MessagePackValidateUTF8
  """
  Validates whether a string contains only valid UTF-8 byte
  sequences. Returns `true` if the string is valid UTF-8,
  `false` otherwise.

  This is useful in the "decode then validate" pattern, where
  callers decode a string using a non-validating method and
  then validate separately so they retain access to the raw
  bytes on failure:

  ```pony
  let s = MessagePackDecoder.str(reader)?

  if not MessagePackValidateUTF8(s) then
    // s still available — log, reject, or treat as raw bytes
  end
  ```
  """
  fun apply(s: String box): Bool =>
    var i: USize = 0
    while i < s.size() do
      try
        (let cp, let len) = s.utf32(i.isize())?
        // String.utf32 returns (0xFFFD, 1) for invalid byte
        // sequences: the Unicode replacement character with a
        // consumed length of 1. A legitimately encoded U+FFFD
        // (bytes 0xEF 0xBF 0xBD) returns (0xFFFD, 3). The
        // length field disambiguates.
        //
        // This depends on String.utf32's error-reporting
        // convention. If utf32's behavior changes, this
        // validator will need to be updated.
        if (cp == 0xFFFD) and (len == 1) then
          return false
        end
        i = i + len.usize()
      else
        return false
      end
    end
    true
