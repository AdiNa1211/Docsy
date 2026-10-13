part of 'image_editor_bloc.dart';

enum ImageEditorStatus { initial, loading, ready, failure }

class ImageEditorState extends Equatable {
  const ImageEditorState({
    this.status = ImageEditorStatus.initial,
    this.file,
    this.info,
    this.settings = ImageEditSettings.initial,
    this.undoStack = const [],
    this.redoStack = const [],
    this.previewBytes,
    this.previewBusy = false,
    this.exporting = false,
    this.lastExport,
    this.overwritePrompt,
    this.message,
  });

  final ImageEditorStatus status;
  final OpenedFile? file;
  final ImageInfo? info;
  final ImageEditSettings settings;
  final List<ImageEditSettings> undoStack;
  final List<ImageEditSettings> redoStack;
  final Uint8List? previewBytes;
  final bool previewBusy;
  final bool exporting;
  final ExportResult? lastExport;

  /// Destination that already exists and needs explicit overwrite confirmation.
  final String? overwritePrompt;
  final String? message;

  bool get canUndo => undoStack.isNotEmpty;
  bool get canRedo => redoStack.isNotEmpty;

  /// Output size after crop, rotation and resize. Null until an image is loaded.
  TargetSize? get outputSize =>
      info == null ? null : TargetSize.resolve(settings, info!);

  ImageEditorState copyWith({
    ImageEditorStatus? status,
    OpenedFile? file,
    ImageInfo? info,
    ImageEditSettings? settings,
    List<ImageEditSettings>? undoStack,
    List<ImageEditSettings>? redoStack,
    Uint8List? previewBytes,
    bool clearPreview = false,
    bool? previewBusy,
    bool? exporting,
    ExportResult? lastExport,
    String? overwritePrompt,
    bool clearOverwritePrompt = false,
    String? message,
    bool clearMessage = false,
  }) {
    return ImageEditorState(
      status: status ?? this.status,
      file: file ?? this.file,
      info: info ?? this.info,
      settings: settings ?? this.settings,
      undoStack: undoStack ?? this.undoStack,
      redoStack: redoStack ?? this.redoStack,
      previewBytes: clearPreview ? null : (previewBytes ?? this.previewBytes),
      previewBusy: previewBusy ?? this.previewBusy,
      exporting: exporting ?? this.exporting,
      lastExport: lastExport ?? this.lastExport,
      overwritePrompt: clearOverwritePrompt
          ? null
          : (overwritePrompt ?? this.overwritePrompt),
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [
    status,
    file,
    info,
    settings,
    undoStack,
    redoStack,
    previewBytes,
    previewBusy,
    exporting,
    lastExport,
    overwritePrompt,
    message,
  ];
}
