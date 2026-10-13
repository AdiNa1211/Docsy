import 'package:equatable/equatable.dart';

enum ResizeMode { none, percent, pixels }

enum OutputFormat {
  png('png', 'PNG'),
  jpeg('jpg', 'JPEG'),
  bmp('bmp', 'BMP');

  const OutputFormat(this.extension, this.label);
  final String extension;
  final String label;

  bool get supportsQuality => this == OutputFormat.jpeg;
}

class CropRect extends Equatable {
  const CropRect({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final int x;
  final int y;
  final int width;
  final int height;

  @override
  List<Object?> get props => [x, y, width, height];
}

class ImageEditSettings extends Equatable {
  const ImageEditSettings({
    this.resizeMode = ResizeMode.none,
    this.percent = 100,
    this.width,
    this.height,
    this.lockAspect = true,
    this.crop,
    this.rotationDegrees = 0,
    this.flipHorizontal = false,
    this.flipVertical = false,
    this.brightness = 0,
    this.contrast = 0,
    this.format = OutputFormat.png,
    this.quality = 90,
  });

  static const ImageEditSettings initial = ImageEditSettings();

  final ResizeMode resizeMode;
  final double percent;
  final int? width;
  final int? height;
  final bool lockAspect;
  final CropRect? crop;
  final int rotationDegrees;
  final bool flipHorizontal;
  final bool flipVertical;
  final int brightness;
  final int contrast;
  final OutputFormat format;
  final int quality;

  ImageEditSettings copyWith({
    ResizeMode? resizeMode,
    double? percent,
    int? width,
    int? height,
    bool clearSize = false,
    bool? lockAspect,
    CropRect? crop,
    bool clearCrop = false,
    int? rotationDegrees,
    bool? flipHorizontal,
    bool? flipVertical,
    int? brightness,
    int? contrast,
    OutputFormat? format,
    int? quality,
  }) {
    return ImageEditSettings(
      resizeMode: resizeMode ?? this.resizeMode,
      percent: percent ?? this.percent,
      width: clearSize ? null : (width ?? this.width),
      height: clearSize ? null : (height ?? this.height),
      lockAspect: lockAspect ?? this.lockAspect,
      crop: clearCrop ? null : (crop ?? this.crop),
      rotationDegrees: rotationDegrees ?? this.rotationDegrees,
      flipHorizontal: flipHorizontal ?? this.flipHorizontal,
      flipVertical: flipVertical ?? this.flipVertical,
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      format: format ?? this.format,
      quality: quality ?? this.quality,
    );
  }

  @override
  List<Object?> get props => [
    resizeMode,
    percent,
    width,
    height,
    lockAspect,
    crop,
    rotationDegrees,
    flipHorizontal,
    flipVertical,
    brightness,
    contrast,
    format,
    quality,
  ];
}
