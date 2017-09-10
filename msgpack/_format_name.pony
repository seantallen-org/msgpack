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

primitive _FormatName
  fun positive_fixint(): U8 => 0x00
  fun fixmap(): U8 => 0x80
  fun fixarray(): U8 => 0x90
  fun fixstr(): U8 => 0xA0
  fun nil(): U8 => 0xc0
  fun falsey(): U8 => 0xc2
  fun truthy(): U8 => 0xc3
  fun bin_8(): U8 => 0xc4
  fun bin_16(): U8 => 0xc5
  fun bin_32(): U8 => 0xc6
  fun ext_8(): U8 => 0xc7
  fun ext_16(): U8 => 0xc8
  fun ext_32(): U8 => 0xc9
  fun float_32(): U8 => 0xca
  fun float_64(): U8 => 0xcb
  fun uint_8(): U8 => 0xcc
  fun uint_16(): U8 => 0xcd
  fun uint_32(): U8 => 0xce
  fun uint_64(): U8 => 0xcf
  fun int_8(): U8 => 0xd0
  fun int_16(): U8 => 0xd1
  fun int_32(): U8 => 0xd2
  fun int_64(): U8 => 0xd3
  fun fixext_1(): U8 => 0xd4
  fun fixext_2(): U8 => 0xd5
  fun fixext_4(): U8 => 0xd6
  fun fixext_8(): U8 => 0xd7
  fun fixext_16(): U8 => 0xd8
  fun str_8(): U8 => 0xd9
  fun str_16(): U8 => 0xda
  fun str_32(): U8 => 0xdb
  fun array_16(): U8 => 0xdc
  fun array_32(): U8 => 0xdd
  fun map_16(): U8 => 0xde
  fun map_32(): U8 => 0xdf
  fun negative_fixint(): U8 => 0xe0
