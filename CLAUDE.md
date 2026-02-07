# msgpack - Project Instructions

## Overview

Pure Pony implementation of the MessagePack serialization format. This is a **library** (not an application) providing low-level encoding/decoding primitives. Beta status (v0.2.5). No external dependencies — pure Pony stdlib only.

## Building and Testing

```bash
make test           # Run unit tests + build examples (default target)
make unit-tests     # Run unit tests only (--sequential --exclude=integration)
make build-examples # Compile examples only
make clean          # Clean build artifacts
make docs           # Generate API documentation
```

Build modes: `config=release` (default) or `config=debug`.

## Project Structure

```
msgpack/                             # Main source package
  message_pack_encoder.pony          # Encoding API (primitive)
  message_pack_decoder.pony          # Decoding API (primitive)
  _format_name.pony                  # MessagePack format byte constants
  _limit.pony                       # Range validation limits
  _size.pony                        # Fixed extension size constants
  _test.pony                        # Test entry point
  _test_encoder.pony                # Encoder tests (~101 cases)
  _test_decoder.pony                # Decoder tests (~34 cases)
examples/simple-example/             # Example usage
```

## Architecture

Two stateless primitives form the public API:

- **`MessagePackEncoder`** — All `fun` methods take a `Writer` and encode values into MessagePack format. Methods map directly to MessagePack format families (nil, bool, int, float, string, binary, array, map, ext, timestamp).
- **`MessagePackDecoder`** — All `fun` methods take a `Reader ref` and decode MessagePack-encoded bytes. Returns decoded values or tuples for compound types.

Internal helpers (`_FormatName`, `_Limit`, `_Size`) are private primitives prefixed with `_`.

All fallible methods use `?` for error signaling. No high-level API exists yet.

**Known limitation:** The decoder is not suitable for streaming. It assumes all data is available when decoding begins. If you read the type byte but the full payload hasn't arrived yet, the stream and reader will be corrupted. See [issue #14](https://github.com/seantallen-org/msgpack/issues/14).

## Conventions

- Follows the Pony stdlib style guide (see STYLE_GUIDE.md).
- File naming: public modules are descriptive (`message_pack_encoder.pony`), private/internal prefixed with `_` (`_format_name.pony`).
- 80-column line wrapping for code, docs, and commands.
- Spaces, not tabs.

## Testing

- Uses `pony_test` framework.
- Tests are encode-then-decode roundtrips verifying spec compliance.
- Each test is a separate class implementing `UnitTest`, registered in actor-based `TestList` suites.
- Memory-intensive tests are wrapped in `ifdef not "ci"` to avoid OOM in CI (4GB limit).

## Dependencies

None. Uses only Pony stdlib packages: `buffered` (Reader/Writer), `collections`, `pony_test`.

Dependency management via `corral` (Pony's package manager). See `corral.json`.

## Branching and Releases

- Main branch: `main`.
- Releases triggered by `release-X.Y.Z` tags on `main`.
- Semantic versioning. Version tracked in `VERSION` file and `corral.json`.
