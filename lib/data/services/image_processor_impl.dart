import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../../core/error/app_failure.dart';
import '../../domain/entities/image_edit_settings.dart';
import '../../domain/entities/image_geometry.dart';
import '../../domain/repositories/image_processor.dart';

/// Runs all pixel work in a background isolate so the UI stays responsive.
class ImageProcessorImpl implements ImageProcessor {
  const ImageProcessorImpl();

  @override
  Future<ImageInfo> inspect(Uint8List source) => compute(_inspect, source);

  @override
  Future<ProcessedImage> process(
    Uint8List source,
    ImageEditSettings settings, {
    int? previewMaxSide,
  }) {
    return compute(
      _run,
      _Job(source: source, settings: settings, previewMaxSide: previewMaxSide),
    );
  }
}

class _Job {
  const _Job({
    required this.source,
    required this.settings,
    this.previewMaxSide,
  });

  final Uint8List source;
  final ImageEditSettings settings;
  final int? previewMaxSide;
}

img.Image _decode(Uint8List source) {
  final decoded = img.decodeImage(source);
  if (decoded == null) {
    throw const ImageProcessingFailure(
      'The image is corrupted or in an unsupported format.',
    );
  }
  return decoded;
}

ImageInfo _inspect(Uint8List source) {
  final image = _decode(source);
  return ImageInfo(width: image.width, height: image.height);
}

ProcessedImage _run(_Job job) {
  final s = job.settings;
  final full = _decode(job.source);
  final info = ImageInfo(width: full.width, height: full.height);

  // Preview scale: shrink the source and every pixel value with it.
  final maxSide = job.previewMaxSide;
  final scale = maxSide == null
      ? 1.0
      : math.min(1.0, maxSide / math.max(full.width, full.height));
  var image = scale < 1.0
      ? img.copyResize(
          full,
          width: _scaled(full.width, scale),
          height: _scaled(full.height, scale),
          interpolation: img.Interpolation.average,
        )
      : full;

  final crop = s.crop;
  if (crop != null) {
    image = _crop(image, crop, scale);
  }
  if (s.rotationDegrees % 360 != 0) {
    image = img.copyRotate(image, angle: s.rotationDegrees.toDouble());
  }
  if (s.flipHorizontal) {
    image = img.flip(image, direction: img.FlipDirection.horizontal);
  }
  if (s.flipVertical) {
    image = img.flip(image, direction: img.FlipDirection.vertical);
  }

  final target = TargetSize.resolve(s, info);
  final tw = _scaled(target.width, scale);
  final th = _scaled(target.height, scale);
  if (image.width != tw || image.height != th) {
    image = img.copyResize(
      image,
      width: tw,
      height: th,
      interpolation: img.Interpolation.average,
    );
  }

  if (s.brightness != 0 || s.contrast != 0) {
    _adjust(image, s.brightness, s.contrast);
  }

  final encoded = switch (s.format) {
    OutputFormat.png => img.encodePng(image),
    OutputFormat.jpeg => img.encodeJpg(_flatten(image), quality: s.quality),
    OutputFormat.bmp => img.encodeBmp(image),
  };
  return ProcessedImage(
    bytes: Uint8List.fromList(encoded),
    width: image.width,
    height: image.height,
  );
}

int _scaled(int value, double scale) =>
    math.max(1, (value * scale).round());

img.Image _crop(img.Image image, CropRect crop, double scale) {
  final x = math.min(math.max((crop.x * scale).round(), 0), image.width - 1);
  final y = math.min(math.max((crop.y * scale).round(), 0), image.height - 1);
  final w = math.min(_scaled(crop.width, scale), image.width - x);
  final h = math.min(_scaled(crop.height, scale), image.height - y);
  return img.copyCrop(image, x: x, y: y, width: w, height: h);
}

/// Brightness in [-100, 100], contrast in [-100, 100]. Alpha is untouched.
void _adjust(img.Image image, int brightness, int contrast) {
  final factor = 1 + contrast / 100;
  final offset = brightness * 2.55;
  for (final pixel in image) {
    pixel
      ..r = _clampChannel((pixel.r - 128) * factor + 128 + offset)
      ..g = _clampChannel((pixel.g - 128) * factor + 128 + offset)
      ..b = _clampChannel((pixel.b - 128) * factor + 128 + offset);
  }
}

num _clampChannel(num value) => value.clamp(0, 255).round();

/// JPEG has no alpha channel, so transparent pixels are composited on white.
img.Image _flatten(img.Image image) {
  if (!image.hasAlpha) return image;
  final base = img.Image(width: image.width, height: image.height);
  img.fill(base, color: img.ColorRgb8(255, 255, 255));
  img.compositeImage(base, image);
  return base;
}
