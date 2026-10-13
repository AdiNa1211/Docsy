import 'dart:typed_data';

import '../entities/image_edit_settings.dart';
import '../entities/image_geometry.dart';

class ProcessedImage {
  const ProcessedImage({
    required this.bytes,
    required this.width,
    required this.height,
  });

  final Uint8List bytes;
  final int width;
  final int height;
}

abstract interface class ImageProcessor {
  /// Throws [ImageProcessingFailure] for corrupted or unsupported input.
  Future<ImageInfo> inspect(Uint8List source);

  /// Applies [settings] and encodes the result.
  /// [previewMaxSide] downsizes the source first for fast previews.
  Future<ProcessedImage> process(
    Uint8List source,
    ImageEditSettings settings, {
    int? previewMaxSide,
  });
}
