import 'package:docsy/domain/entities/file_kind.dart';
import 'package:docsy/domain/entities/image_edit_settings.dart';
import 'package:docsy/domain/entities/image_geometry.dart';
import 'package:flutter_test/flutter_test.dart' hide ImageInfo;

void main() {
  group('FileKind.fromPath', () {
    test('maps extensions case-insensitively', () {
      expect(FileKind.fromPath('/a/Photo.JPG'), FileKind.jpeg);
      expect(FileKind.fromPath('/a/report.docx'), FileKind.docx);
      expect(FileKind.fromPath('/a/notes.txt'), FileKind.txt);
    });

    test('returns unsupported for unknown extensions', () {
      expect(FileKind.fromPath('/a/archive.zip'), FileKind.unsupported);
      expect(FileKind.fromPath('/a/noext'), FileKind.unsupported);
    });
  });

  group('TargetSize.resolve', () {
    const source = ImageInfo(width: 400, height: 200);

    test('keeps the source size when no resize is set', () {
      final size = TargetSize.resolve(ImageEditSettings.initial, source);
      expect(size, const TargetSize(width: 400, height: 200));
    });

    test('scales by percentage', () {
      final size = TargetSize.resolve(
        const ImageEditSettings(resizeMode: ResizeMode.percent, percent: 50),
        source,
      );
      expect(size, const TargetSize(width: 200, height: 100));
    });

    test('derives height from width when only width is set', () {
      final size = TargetSize.resolve(
        const ImageEditSettings(resizeMode: ResizeMode.pixels, width: 100),
        source,
      );
      expect(size, const TargetSize(width: 100, height: 50));
    });

    test('uses both values exactly when aspect is not kept', () {
      final size = TargetSize.resolve(
        const ImageEditSettings(
          resizeMode: ResizeMode.pixels,
          width: 300,
          height: 300,
        ),
        source,
      );
      expect(size, const TargetSize(width: 300, height: 300));
    });

    test('applies crop before resize and swaps axes on 90° rotation', () {
      final size = TargetSize.resolve(
        const ImageEditSettings(
          crop: CropRect(x: 0, y: 0, width: 200, height: 100),
          rotationDegrees: 90,
          resizeMode: ResizeMode.percent,
          percent: 50,
        ),
        source,
      );
      expect(size, const TargetSize(width: 50, height: 100));
    });
  });
}
