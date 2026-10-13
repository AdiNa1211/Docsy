import 'dart:typed_data';

import 'package:docsy/core/error/app_failure.dart';
import 'package:docsy/data/services/image_processor_impl.dart';
import 'package:docsy/domain/entities/image_edit_settings.dart';
import 'package:docsy/domain/entities/image_geometry.dart';
import 'package:flutter_test/flutter_test.dart' hide ImageInfo;
import 'package:image/image.dart' as img;

Uint8List _pngOf(int width, int height) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(10, 120, 200));
  return Uint8List.fromList(img.encodePng(image));
}

void main() {
  const processor = ImageProcessorImpl();

  test('inspect reports the decoded pixel size', () async {
    final info = await processor.inspect(_pngOf(40, 20));
    expect(info, const ImageInfo(width: 40, height: 20));
  });

  test('pixel resize writes an image with the requested dimensions', () async {
    final out = await processor.process(
      _pngOf(40, 20),
      const ImageEditSettings(resizeMode: ResizeMode.pixels, width: 10),
    );
    expect(out.width, 10);
    expect(out.height, 5);

    final decoded = img.decodePng(out.bytes)!;
    expect(decoded.width, 10);
    expect(decoded.height, 5);
  });

  test('crop then 90° rotation produces the expected size', () async {
    final out = await processor.process(
      _pngOf(40, 20),
      const ImageEditSettings(
        crop: CropRect(x: 5, y: 5, width: 20, height: 10),
        rotationDegrees: 90,
      ),
    );
    expect(out.width, 10);
    expect(out.height, 20);
  });

  test('preview keeps the aspect ratio within the preview bound', () async {
    final out = await processor.process(
      _pngOf(4000, 2000),
      const ImageEditSettings(),
      previewMaxSide: 1024,
    );
    expect(out.width, 1024);
    expect(out.height, 512);
  });

  test('JPEG export encodes without an alpha channel error', () async {
    final out = await processor.process(
      _pngOf(16, 16),
      const ImageEditSettings(format: OutputFormat.jpeg, quality: 80),
    );
    expect(img.decodeJpg(out.bytes), isNotNull);
  });

  test('corrupted input throws ImageProcessingFailure', () async {
    expect(
      () => processor.inspect(Uint8List.fromList([1, 2, 3, 4])),
      throwsA(isA<ImageProcessingFailure>()),
    );
  });
}
