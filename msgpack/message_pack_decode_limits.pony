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

class val MessagePackDecodeLimits
  """
  Limits for the streaming decoder. Protects against
  denial-of-service attacks where a malicious payload claims
  enormous sizes for variable-length values or deeply nested
  containers.

  The default constructor applies conservative limits: 1 MB for
  str/bin/ext data, 131,072 for array/map element counts, and
  512 for container nesting depth. Use `unlimited()` to disable
  all limits, or override individual limits:

  ```pony
  // Default conservative limits:
  let limits = MessagePackDecodeLimits

  // Custom limits:
  let limits = MessagePackDecodeLimits(
    where max_str_len' = 4096)

  // No limits:
  let limits = MessagePackDecodeLimits.unlimited()
  ```
  """
  let max_str_len: USize
  let max_bin_len: USize
  let max_ext_len: USize
  let max_array_len: U32
  let max_map_len: U32
  let max_depth: USize

  new val create(
    max_str_len': USize = 1_048_576,
    max_bin_len': USize = 1_048_576,
    max_ext_len': USize = 1_048_576,
    max_array_len': U32 = 131_072,
    max_map_len': U32 = 131_072,
    max_depth': USize = 512)
  =>
    max_str_len = max_str_len'
    max_bin_len = max_bin_len'
    max_ext_len = max_ext_len'
    max_array_len = max_array_len'
    max_map_len = max_map_len'
    max_depth = max_depth'

  new val unlimited() =>
    max_str_len = USize.max_value()
    max_bin_len = USize.max_value()
    max_ext_len = USize.max_value()
    max_array_len = U32.max_value()
    max_map_len = U32.max_value()
    max_depth = USize.max_value()
