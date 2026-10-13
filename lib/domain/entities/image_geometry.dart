import 'package:equatable/equatable.dart';

import 'image_edit_settings.dart';

class ImageInfo extends Equatable {
  const ImageInfo({required this.width, required this.height});

  final int width;
  final int height;

  @override
  List<Object?> get props => [width, height];
}

class TargetSize extends Equatable {
  const TargetSize({required this.width, required this.height});

  final int width;
  final int height;

  /// Output size for [settings] applied to a source of [source] pixels.
  factory TargetSize.resolve(ImageEditSettings settings, ImageInfo source) {
    var w = source.width;
    var h = source.height;
    final crop = settings.crop;
    if (crop != null) {
      w = crop.width;
      h = crop.height;
    }
    if (settings.rotationDegrees % 180 != 0) {
      final tmp = w;
      w = h;
      h = tmp;
    }
    switch (settings.resizeMode) {
      case ResizeMode.none:
        break;
      case ResizeMode.percent:
        w = (w * settings.percent / 100).round();
        h = (h * settings.percent / 100).round();
      case ResizeMode.pixels:
        final base = ImageInfo(width: w, height: h);
        if (settings.width != null && settings.height == null) {
          w = settings.width!;
          h = aspectHeightFor(w, base);
        } else if (settings.height != null && settings.width == null) {
          h = settings.height!;
          w = aspectWidthFor(h, base);
        } else {
          w = settings.width ?? w;
          h = settings.height ?? h;
        }
    }
    return TargetSize(width: w < 1 ? 1 : w, height: h < 1 ? 1 : h);
  }

  @override
  List<Object?> get props => [width, height];
}

/// Height matching [width] at the source aspect ratio.
int aspectHeightFor(int width, ImageInfo source) =>
    (width * source.height / source.width).round().clamp(1, 1 << 30);

/// Width matching [height] at the source aspect ratio.
int aspectWidthFor(int height, ImageInfo source) =>
    (height * source.width / source.height).round().clamp(1, 1 << 30);
