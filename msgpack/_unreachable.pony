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

use @exit[None](status: U8)
use @fprintf[I32](
  stream: Pointer[U8] tag,
  fmt: Pointer[U8] tag, ...)
use @pony_os_stderr[Pointer[U8]]()

primitive _Unreachable
  """
  To be used in places that the compiler can't prove is
  unreachable but we are certain is unreachable and if we
  reach it, we'd be silently hiding a bug.
  """
  fun apply(loc: SourceLoc = __loc) =>
    @fprintf(
      @pony_os_stderr(),
      ("The unreachable was reached in %s at line %s\n"
        + "Please open an issue at "
        + "https://github.com/seantallen-org/msgpack/"
        + "issues")
        .cstring(),
      loc.file().cstring(),
      loc.line().string().cstring())
    @exit(1)
