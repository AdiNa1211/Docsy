import 'dart:convert';
import 'dart:typed_data';

import 'package:docsy/core/utils/text_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('decodeText', () {
    test('decodes plain UTF-8', () {
      final decoded = decodeText(Uint8List.fromList(utf8.encode('héllo')));
      expect(decoded.text, 'héllo');
      expect(decoded.encoding, TextEncodingKind.utf8);
    });

    test('detects and strips a UTF-8 BOM', () {
      final bytes = Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode('hi')]);
      final decoded = decodeText(bytes);
      expect(decoded.text, 'hi');
      expect(decoded.encoding, TextEncodingKind.utf8WithBom);
    });

    test('falls back to Latin-1 for invalid UTF-8', () {
      final decoded = decodeText(Uint8List.fromList([0x63, 0x61, 0x66, 0xE9]));
      expect(decoded.text, 'café');
      expect(decoded.encoding, TextEncodingKind.latin1);
    });
  });

  group('encodeText', () {
    test('round-trips a BOM file and keeps the BOM', () {
      const text = 'line one\nline two';
      final bytes = encodeText(text, TextEncodingKind.utf8WithBom);
      expect(bytes.sublist(0, 3), [0xEF, 0xBB, 0xBF]);
      final decoded = decodeText(bytes);
      expect(decoded.text, text);
      expect(decoded.encoding, TextEncodingKind.utf8WithBom);
    });

    test('throws when Latin-1 cannot represent the text', () {
      expect(
        () => encodeText('€', TextEncodingKind.latin1),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
