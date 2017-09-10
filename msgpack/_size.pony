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

primitive _Size
  fun fixext_1(): USize => 1
  fun fixext_2(): USize => 2
  fun fixext_4(): USize => 4
  fun fixext_8(): USize => 8
  fun fixext_16(): USize => 16
