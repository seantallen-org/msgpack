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

primitive _Limit
  fun fixarray(): U8 => 15
  fun fixmap(): U8 => 15
  fun fixstr(): USize => 31
  fun positive_fixint(): U8 => 127
  fun negative_fixint_low(): I8 => -32
  fun negative_fixint_high(): I8 => -1
  fun nsec(): U32 => 999999999
  fun sec_34(): U64 => 17179869183 // 2^34 - 1
