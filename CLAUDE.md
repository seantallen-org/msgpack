# msgpack - Project Instructions

## Overview

Pure Pony implementation of the MessagePack serialization format. This is a **library** (not an application) providing compact encoding/decoding methods that automatically select the smallest wire format, format-specific primitives for explicit control, and a streaming-safe decoder. Beta status (v0.2.5). No external dependencies — pure Pony stdlib only.

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
  message_pack_streaming_decoder.pony # Streaming decoder (class)
  message_pack_types.pony            # Streaming decoder types
  _format_name.pony                  # MessagePack format byte constants
  _limit.pony                       # Range validation limits
  _size.pony                        # Fixed extension size constants
  _unreachable.pony                 # Panic primitive for dead code
  _test.pony                        # Test entry point
  _test_encoder.pony                # Encoder tests
  _test_decoder.pony                # Decoder tests
  _test_streaming_decoder.pony      # Streaming decoder tests
examples/encode-decode/              # Encode/decode roundtrip example
examples/streaming-decode/           # Streaming decoder example
```

## Architecture

Two stateless primitives provide encoding/decoding:

- **`MessagePackEncoder`** — All `fun` methods take a `Writer` and encode values into MessagePack format. Compact methods (`uint`, `int`, `str`, `bin`, `array`, `map`, `ext`, `timestamp`) automatically select the smallest wire format for a given value. Format-specific methods (`uint_8`, `uint_32`, `fixstr`, `str_8`, `fixarray`, `array_16`, etc.) are available for explicit control.
- **`MessagePackDecoder`** — All `fun` methods take a `Reader ref` and decode MessagePack-encoded bytes. Compact methods (`uint`, `int`, `str`, `array`, `map`) peek at the format byte and accept any wire format within the family. `str()` handles all string formats (fixstr, str_8, str_16, str_32). `array()` and `map()` handle all their respective formats. Format-specific methods remain available for callers who know the exact wire format.

A streaming-safe decoder wraps the low-level primitives:

- **`MessagePackStreamingDecoder`** — A class that peeks at format bytes and length fields before consuming data. Returns `DecodeResult` (a union of `MessagePackValue | NotEnoughData | InvalidData`). Container types return header objects (`MessagePackArray` / `MessagePackMap`); timestamps return `MessagePackTimestamp`. Types defined in `message_pack_types.pony`.

Internal helpers (`_FormatName`, `_Limit`, `_Size`) are private primitives prefixed with `_`.

All fallible methods use `?` for error signaling.

**Known limitation:** `MessagePackDecoder` is not suitable for streaming. It assumes all data is available when decoding begins. If you read the type byte but the full payload hasn't arrived yet, the stream and reader will be corrupted. See [issue #14](https://github.com/seantallen-org/msgpack/issues/14). `MessagePackStreamingDecoder` addresses this by peeking at format bytes and length fields before consuming any data — if insufficient data is available, it returns `NotEnoughData` with zero bytes consumed.

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

None. Uses only Pony stdlib packages: `buffered` (Reader/Writer), `collections`, `pony_check`, `pony_test`.

Dependency management via `corral` (Pony's package manager). See `corral.json`.

## Branching and Releases

- Main branch: `main`.
- Releases triggered by `release-X.Y.Z` tags on `main`.
- Semantic versioning. Version tracked in `VERSION` file and `corral.json`.
