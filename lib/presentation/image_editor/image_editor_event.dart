part of 'image_editor_bloc.dart';

sealed class ImageEditorEvent extends Equatable {
  const ImageEditorEvent();

  @override
  List<Object?> get props => [];
}

class ImageOpened extends ImageEditorEvent {
  const ImageOpened(this.path);
  final String path;

  @override
  List<Object?> get props => [path];
}

class ImageResizeModeChanged extends ImageEditorEvent {
  const ImageResizeModeChanged(this.mode);
  final ResizeMode mode;

  @override
  List<Object?> get props => [mode];
}

class ImagePercentChanged extends ImageEditorEvent {
  const ImagePercentChanged(this.percent);
  final double percent;

  @override
  List<Object?> get props => [percent];
}

/// Changes one dimension; the other follows when aspect lock is on.
class ImagePixelWidthChanged extends ImageEditorEvent {
  const ImagePixelWidthChanged(this.width);
  final int width;

  @override
  List<Object?> get props => [width];
}

class ImagePixelHeightChanged extends ImageEditorEvent {
  const ImagePixelHeightChanged(this.height);
  final int height;

  @override
  List<Object?> get props => [height];
}

class ImagePresetSelected extends ImageEditorEvent {
  const ImagePresetSelected(this.width, this.height);
  final int width;
  final int height;

  @override
  List<Object?> get props => [width, height];
}

class ImageLockAspectChanged extends ImageEditorEvent {
  const ImageLockAspectChanged(this.locked);
  final bool locked;

  @override
  List<Object?> get props => [locked];
}

class ImageCropChanged extends ImageEditorEvent {
  const ImageCropChanged(this.crop);
  final CropRect? crop;

  @override
  List<Object?> get props => [crop];
}

class ImageRotated extends ImageEditorEvent {
  const ImageRotated({required this.clockwise});
  final bool clockwise;

  @override
  List<Object?> get props => [clockwise];
}

class ImageFlipped extends ImageEditorEvent {
  const ImageFlipped({required this.horizontal});
  final bool horizontal;

  @override
  List<Object?> get props => [horizontal];
}

class ImageAdjustmentsChanged extends ImageEditorEvent {
  const ImageAdjustmentsChanged({this.brightness, this.contrast});
  final int? brightness;
  final int? contrast;

  @override
  List<Object?> get props => [brightness, contrast];
}

class ImageFormatChanged extends ImageEditorEvent {
  const ImageFormatChanged({this.format, this.quality});
  final OutputFormat? format;
  final int? quality;

  @override
  List<Object?> get props => [format, quality];
}

class ImageUndoRequested extends ImageEditorEvent {
  const ImageUndoRequested();
}

class ImageRedoRequested extends ImageEditorEvent {
  const ImageRedoRequested();
}

class ImageResetRequested extends ImageEditorEvent {
  const ImageResetRequested();
}

class ImageExportRequested extends ImageEditorEvent {
  const ImageExportRequested({
    required this.destination,
    this.overwrite = false,
  });
  final String destination;
  final bool overwrite;

  @override
  List<Object?> get props => [destination, overwrite];
}

class _PreviewRequested extends ImageEditorEvent {
  const _PreviewRequested();
}
