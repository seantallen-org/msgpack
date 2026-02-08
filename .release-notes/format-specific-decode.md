## Add format-specific str, bin, and ext decoding methods

`MessagePackDecoder` now provides format-specific decoding methods for the
str, bin, and ext format families: `str_8`, `str_16`, `str_32`, `bin_8`,
`bin_16`, `bin_32`, `fixext_1`, `fixext_2`, `fixext_4`, `fixext_8`,
`fixext_16`, `ext_8`, `ext_16`, and `ext_32`.

These methods decode a single wire format directly, skipping the
format-byte dispatch used by the compact methods (`str()`,
`byte_array()`, `ext()`). Use them when you know the exact wire format
and want to avoid the overhead of format detection.

```pony
// Compact — accepts any string wire format:
MessagePackDecoder.str(reader)?

// Format-specific — decodes str_8 only, errors on other formats:
MessagePackDecoder.str_8(reader)?
```
