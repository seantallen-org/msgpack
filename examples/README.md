# Examples

Each subdirectory is a self-contained Pony program demonstrating a different part of the msgpack library.

## encode-decode

Core encode/decode workflow using the compact API. Covers nil, bool, unsigned and signed integers, strings, arrays, and maps. Start here if you're new to the library.

## streaming-decode

Streaming decoder for data that arrives in chunks. Shows how `MessagePackStreamingDecoder` handles containers (maps), mixed value types, and partial data (`NotEnoughData`).

## zero-copy-decode

Zero-copy decoding with `ZeroCopyReader` and `MessagePackZeroCopyDecoder`. Decoded strings and byte arrays are returned as views into the reader's buffer rather than copies, avoiding allocation when data falls within a single chunk.

## decode-limits

Configurable size limits via `MessagePackDecodeLimits`. Shows how to protect against denial-of-service attacks when decoding untrusted data by setting maximum sizes for strings, binary data, and container counts.

## skip

Forward-compatible protocol handling with `MessagePackDecoder.skip`. Demonstrates reading known fields from a map and skipping unrecognized fields without needing to know their type or structure.

## utf8-validation

Three approaches to UTF-8 validation for MessagePack str values: validate on encode (`str_utf8`), validate on streaming decode (`validate_utf8` option), and decode-then-validate manually (`MessagePackValidateUTF8`).
