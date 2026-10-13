import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_limits.dart';
import '../../core/error/app_failure.dart';
import '../../core/utils/text_codec.dart';
import '../../domain/repositories/file_repository.dart';

class DocumentEditorState extends Equatable {
  const DocumentEditorState({
    this.path,
    this.text = '',
    this.encoding = TextEncodingKind.utf8,
    this.savedText = '',
    this.undoStack = const [],
    this.redoStack = const [],
    this.loading = false,
    this.saving = false,
    this.message,
  });

  final String? path;
  final String text;
  final TextEncodingKind encoding;
  final String savedText;
  final List<String> undoStack;
  final List<String> redoStack;
  final bool loading;
  final bool saving;
  final String? message;

  bool get isDirty => text != savedText;
  bool get canUndo => undoStack.isNotEmpty;
  bool get canRedo => redoStack.isNotEmpty;

  DocumentEditorState copyWith({
    String? path,
    String? text,
    TextEncodingKind? encoding,
    String? savedText,
    List<String>? undoStack,
    List<String>? redoStack,
    bool? loading,
    bool? saving,
    String? message,
    bool clearMessage = false,
  }) {
    return DocumentEditorState(
      path: path ?? this.path,
      text: text ?? this.text,
      encoding: encoding ?? this.encoding,
      savedText: savedText ?? this.savedText,
      undoStack: undoStack ?? this.undoStack,
      redoStack: redoStack ?? this.redoStack,
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [
    path,
    text,
    encoding,
    savedText,
    undoStack,
    redoStack,
    loading,
    saving,
    message,
  ];
}

/// Edits plain text with undo/redo and keeps the file's original encoding on save.
class DocumentEditorCubit extends Cubit<DocumentEditorState> {
  DocumentEditorCubit({required FileRepository files})
    : _files = files,
      super(const DocumentEditorState());

  final FileRepository _files;
  static const _coalesceWindow = Duration(seconds: 1);
  DateTime? _lastEdit;

  Future<void> load(String path) async {
    emit(DocumentEditorState(path: path, loading: true));
    try {
      final bytes = await _files.readBytes(path);
      final decoded = decodeText(bytes);
      emit(
        DocumentEditorState(
          path: path,
          text: decoded.text,
          savedText: decoded.text,
          encoding: decoded.encoding,
        ),
      );
    } catch (e) {
      emit(
        DocumentEditorState(
          path: path,
          message: e is AppFailure ? e.message : 'Could not read file: $e',
        ),
      );
    }
  }

  /// Typing bursts within [_coalesceWindow] share one undo step.
  void edit(String text) {
    if (text == state.text) return;
    final now = DateTime.now();
    final last = _lastEdit;
    final coalesce =
        last != null && now.difference(last) < _coalesceWindow;
    _lastEdit = now;
    emit(
      state.copyWith(
        text: text,
        undoStack: coalesce
            ? state.undoStack
            : _push(state.undoStack, state.text),
        redoStack: const [],
        clearMessage: true,
      ),
    );
  }

  void undo() {
    if (!state.canUndo) return;
    _lastEdit = null;
    final previous = state.undoStack.last;
    emit(
      state.copyWith(
        text: previous,
        undoStack: state.undoStack.sublist(0, state.undoStack.length - 1),
        redoStack: [...state.redoStack, state.text],
      ),
    );
  }

  void redo() {
    if (!state.canRedo) return;
    final next = state.redoStack.last;
    emit(
      state.copyWith(
        text: next,
        redoStack: state.redoStack.sublist(0, state.redoStack.length - 1),
        undoStack: _push(state.undoStack, state.text),
      ),
    );
  }

  /// Saves to [target] (defaults to the open path). Pass a new path for Save As.
  Future<bool> save({String? target}) async {
    final destination = target ?? state.path;
    if (destination == null) return false;
    emit(state.copyWith(saving: true, clearMessage: true));
    try {
      final bytes = _encodeOrThrow(state.text, state.encoding);
      await _files.writeBytes(destination, bytes);
      emit(
        state.copyWith(
          path: destination,
          savedText: state.text,
          saving: false,
          message: 'Saved ${destination.split(RegExp(r'[/\\]')).last}',
        ),
      );
      return true;
    } catch (e) {
      emit(
        state.copyWith(
          saving: false,
          message: e is AppFailure ? e.message : 'Save failed: $e',
        ),
      );
      return false;
    }
  }

  Uint8List _encodeOrThrow(String text, TextEncodingKind encoding) {
    try {
      return encodeText(text, encoding);
    } on FormatException {
      throw const FileAccessFailure(
        'This text contains characters the original encoding cannot store. Save As UTF-8 instead.',
      );
    }
  }

  List<String> _push(List<String> stack, String value) {
    final next = [...stack, value];
    final overflow = next.length - AppLimits.historyLimit;
    return overflow > 0 ? next.sublist(overflow) : next;
  }
}
