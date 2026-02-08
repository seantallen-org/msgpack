## Add opt-in UTF-8 validation for str format values

The MessagePack spec defines str format values as UTF-8 strings, but previously this library treated them as opaque byte sequences without validation. Opt-in UTF-8 validation is now available at every layer.

Validating `_utf8` method variants are available on all encoders and decoders. They work identically to their non-validating counterparts but error when the bytes are not valid UTF-8:

```pony
// Encode — errors if bytes are not valid UTF-8
MessagePackEncoder.str_utf8(w, value)?

// Decode — errors if decoded bytes are not valid UTF-8
let s = MessagePackDecoder.str_utf8(reader)?
let s = MessagePackZeroCopyDecoder.str_utf8(reader)?
```

Format-specific variants are also available: `fixstr_utf8`, `str_8_utf8`, `str_16_utf8`, and `str_32_utf8`.

The streaming decoder accepts a `validate_utf8` constructor option. When enabled, str values with invalid UTF-8 return `InvalidUtf8` — a new member of the `DecodeResult` union, distinct from `InvalidData`. The MessagePack framing is valid and decoding can continue:

```pony
let sd = MessagePackStreamingDecoder(
  where validate_utf8' = true)
match sd.next()
| let s: String val => // valid UTF-8 string
| InvalidUtf8 => // invalid UTF-8, stream is fine
end
```

A public `MessagePackValidateUTF8` primitive supports the "decode then validate" pattern for callers who need access to the raw bytes on validation failure:

```pony
let s = MessagePackDecoder.str(reader)?
if not MessagePackValidateUTF8(s) then
  // s still available — log, reject, or use as raw bytes
end
```

Existing non-validating methods are unchanged. The default behavior is preserved for backward compatibility.
