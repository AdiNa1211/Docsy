import 'dart:typed_data';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_limits.dart';
import '../../core/error/app_failure.dart';
import '../../domain/entities/image_edit_settings.dart';
import '../../domain/entities/image_geometry.dart';
import '../../domain/entities/opened_file.dart';
import '../../domain/repositories/file_repository.dart';
import '../../domain/repositories/image_processor.dart';
import '../../domain/usecases/export_image_usecase.dart';

part 'image_editor_event.dart';
part 'image_editor_state.dart';

class ImageEditorBloc extends Bloc<ImageEditorEvent, ImageEditorState> {
  ImageEditorBloc({
    required FileRepository files,
    required ExportImageUseCase exportImage,
    required ImageProcessor processor,
  }) : _files = files,
       _exportImage = exportImage,
       _processor = processor,
       super(const ImageEditorState()) {
    on<ImageOpened>(_onOpened);
    on<ImageResizeModeChanged>(
      (e, emit) => _commit(emit, state.settings.copyWith(resizeMode: e.mode)),
    );
    on<ImagePercentChanged>(
      (e, emit) => _commit(
        emit,
        state.settings.copyWith(
          resizeMode: ResizeMode.percent,
          percent: e.percent.clamp(1, 1000).toDouble(),
        ),
      ),
    );
    on<ImagePixelWidthChanged>(_onWidthChanged);
    on<ImagePixelHeightChanged>(_onHeightChanged);
    on<ImagePresetSelected>(
      (e, emit) => _commit(
        emit,
        state.settings.copyWith(
          resizeMode: ResizeMode.pixels,
          width: e.width,
          height: e.height,
        ),
      ),
    );
    on<ImageLockAspectChanged>(_onLockChanged);
    on<ImageCropChanged>(
      (e, emit) => _commit(
        emit,
        state.settings.copyWith(
          crop: e.crop,
          clearCrop: e.crop == null,
          clearSize: true,
        ),
      ),
    );
    on<ImageRotated>(_onRotated);
    on<ImageFlipped>(
      (e, emit) => _commit(
        emit,
        e.horizontal
            ? state.settings.copyWith(
                flipHorizontal: !state.settings.flipHorizontal,
              )
            : state.settings.copyWith(
                flipVertical: !state.settings.flipVertical,
              ),
      ),
    );
    on<ImageAdjustmentsChanged>(
      (e, emit) => _commit(
        emit,
        state.settings.copyWith(
          brightness:
              (e.brightness ?? state.settings.brightness).clamp(-100, 100).toInt(),
          contrast:
              (e.contrast ?? state.settings.contrast).clamp(-100, 100).toInt(),
        ),
      ),
    );
    on<ImageFormatChanged>(
      (e, emit) => _commit(
        emit,
        state.settings.copyWith(
          format: e.format,
          quality: (e.quality ?? state.settings.quality).clamp(1, 100).toInt(),
        ),
      ),
    );
    on<ImageUndoRequested>(_onUndo);
    on<ImageRedoRequested>(_onRedo);
    on<ImageResetRequested>(
      (_, emit) => _commit(emit, ImageEditSettings.initial),
    );
    on<ImageExportRequested>(_onExport, transformer: droppable());
    on<_PreviewRequested>(_onPreview, transformer: restartable());
  }

  final FileRepository _files;
  final ExportImageUseCase _exportImage;
  final ImageProcessor _processor;
  Uint8List? _source;

  Future<void> _onOpened(ImageOpened event, Emitter<ImageEditorState> emit) async {
    emit(const ImageEditorState(status: ImageEditorStatus.loading));
    try {
      final file = await _files.inspect(event.path);
      if (!file.kind.isImage) {
        throw UnsupportedFormatFailure('Not an image file: ${file.name}');
      }
      final bytes = await _files.readBytes(event.path);
      final info = await _processor.inspect(bytes);
      _source = bytes;
      emit(
        ImageEditorState(
          status: ImageEditorStatus.ready,
          file: file,
          info: info,
        ),
      );
      add(const _PreviewRequested());
    } catch (e) {
      emit(
        ImageEditorState(
          status: ImageEditorStatus.failure,
          message: _messageFor(e),
        ),
      );
    }
  }

  void _onWidthChanged(
    ImagePixelWidthChanged event,
    Emitter<ImageEditorState> emit,
  ) {
    final base = _baseInfo();
    if (base == null) return;
    final width = event.width.clamp(1, 20000).toInt();
    final height = state.settings.lockAspect
        ? aspectHeightFor(width, base)
        : state.outputSize!.height;
    _commit(
      emit,
      state.settings.copyWith(
        resizeMode: ResizeMode.pixels,
        width: width,
        height: height,
      ),
    );
  }

  void _onHeightChanged(
    ImagePixelHeightChanged event,
    Emitter<ImageEditorState> emit,
  ) {
    final base = _baseInfo();
    if (base == null) return;
    final height = event.height.clamp(1, 20000).toInt();
    final width = state.settings.lockAspect
        ? aspectWidthFor(height, base)
        : state.outputSize!.width;
    _commit(
      emit,
      state.settings.copyWith(
        resizeMode: ResizeMode.pixels,
        width: width,
        height: height,
      ),
    );
  }

  void _onLockChanged(
    ImageLockAspectChanged event,
    Emitter<ImageEditorState> emit,
  ) {
    final base = _baseInfo();
    if (base == null) return;
    var next = state.settings.copyWith(lockAspect: event.locked);
    if (event.locked && next.resizeMode == ResizeMode.pixels) {
      final width = state.outputSize!.width;
      next = next.copyWith(
        width: width,
        height: aspectHeightFor(width, base),
      );
    }
    _commit(emit, next);
  }

  void _onRotated(ImageRotated event, Emitter<ImageEditorState> emit) {
    final delta = event.clockwise ? 90 : -90;
    final rotation = ((state.settings.rotationDegrees + delta) % 360 + 360) % 360;
    _commit(
      emit,
      state.settings.copyWith(rotationDegrees: rotation, clearSize: true),
    );
  }

  void _onUndo(ImageUndoRequested event, Emitter<ImageEditorState> emit) {
    if (!state.canUndo) return;
    final previous = state.undoStack.last;
    emit(
      state.copyWith(
        settings: previous,
        undoStack: state.undoStack.sublist(0, state.undoStack.length - 1),
        redoStack: [...state.redoStack, state.settings],
        clearMessage: true,
      ),
    );
    add(const _PreviewRequested());
  }

  void _onRedo(ImageRedoRequested event, Emitter<ImageEditorState> emit) {
    if (!state.canRedo) return;
    final next = state.redoStack.last;
    emit(
      state.copyWith(
        settings: next,
        redoStack: state.redoStack.sublist(0, state.redoStack.length - 1),
        undoStack: _pushUndo(state.undoStack, state.settings),
        clearMessage: true,
      ),
    );
    add(const _PreviewRequested());
  }

  void _commit(Emitter<ImageEditorState> emit, ImageEditSettings next) {
    if (state.status != ImageEditorStatus.ready || next == state.settings) {
      return;
    }
    emit(
      state.copyWith(
        settings: next,
        undoStack: _pushUndo(state.undoStack, state.settings),
        redoStack: const [],
        clearMessage: true,
      ),
    );
    add(const _PreviewRequested());
  }

  List<ImageEditSettings> _pushUndo(
    List<ImageEditSettings> stack,
    ImageEditSettings current,
  ) {
    final next = [...stack, current];
    final overflow = next.length - AppLimits.historyLimit;
    return overflow > 0 ? next.sublist(overflow) : next;
  }

  /// Debounced by restartable(): a newer edit cancels the in-flight preview.
  Future<void> _onPreview(
    _PreviewRequested event,
    Emitter<ImageEditorState> emit,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final bytes = _source;
    if (emit.isDone || bytes == null || state.status != ImageEditorStatus.ready) {
      return;
    }
    emit(state.copyWith(previewBusy: true));
    try {
      final preview = await _processor.process(
        bytes,
        state.settings,
        previewMaxSide: AppLimits.previewMaxSide,
      );
      if (emit.isDone) return;
      emit(state.copyWith(previewBytes: preview.bytes, previewBusy: false));
    } catch (e) {
      if (emit.isDone) return;
      emit(state.copyWith(previewBusy: false, message: _messageFor(e)));
    }
  }

  Future<void> _onExport(
    ImageExportRequested event,
    Emitter<ImageEditorState> emit,
  ) async {
    final file = state.file;
    if (file == null || _source == null) return;
    emit(
      state.copyWith(
        exporting: true,
        clearMessage: true,
        clearOverwritePrompt: true,
      ),
    );
    try {
      final result = await _exportImage(
        source: file.path,
        destination: event.destination,
        settings: state.settings,
        overwrite: event.overwrite,
      );
      if (result == null) {
        emit(state.copyWith(exporting: false, overwritePrompt: event.destination));
        return;
      }
      emit(
        state.copyWith(
          exporting: false,
          lastExport: result,
          clearOverwritePrompt: true,
        ),
      );
    } catch (e) {
      emit(state.copyWith(exporting: false, message: _messageFor(e)));
    }
  }

  /// Source size after crop and rotation, before any resize.
  ImageInfo? _baseInfo() {
    final info = state.info;
    if (info == null) return null;
    final base = TargetSize.resolve(
      state.settings.copyWith(resizeMode: ResizeMode.none),
      info,
    );
    return ImageInfo(width: base.width, height: base.height);
  }

  static String _messageFor(Object e) =>
      e is AppFailure ? e.message : 'Unexpected error: $e';
}
