import 'dart:convert';
import 'dart:typed_data';

enum TextEncodingKind { utf8, utf8WithBom, latin1 }

class DecodedText {
  const DecodedText(this.text, this.encoding);
  final String text;
  final TextEncodingKind encoding;
}

/// Decodes UTF-8 (keeping BOM info) and falls back to Latin-1.
DecodedText decodeText(Uint8List bytes) {
  final hasBom =
      bytes.length >= 3 && bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF;
  final body = hasBom ? bytes.sublist(3) : bytes;
  try {
    final text = utf8.decode(body);
    return DecodedText(
      text,
      hasBom ? TextEncodingKind.utf8WithBom : TextEncodingKind.utf8,
    );
  } on FormatException {
    return DecodedText(latin1.decode(bytes), TextEncodingKind.latin1);
  }
}

/// Throws [FormatException] if [encoding] cannot represent [text].
Uint8List encodeText(String text, TextEncodingKind encoding) {
  switch (encoding) {
    case TextEncodingKind.utf8:
      return Uint8List.fromList(utf8.encode(text));
    case TextEncodingKind.utf8WithBom:
      return Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(text)]);
    case TextEncodingKind.latin1:
      return Uint8List.fromList(latin1.encode(text));
  }
}
