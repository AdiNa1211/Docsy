import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/error/app_failure.dart';
import '../../domain/entities/opened_file.dart';
import '../../domain/usecases/open_file_usecase.dart';

class FileManagerState extends Equatable {
  const FileManagerState({
    this.current,
    this.recent = const [],
    this.loading = false,
    this.message,
  });

  final OpenedFile? current;
  final List<String> recent;
  final bool loading;
  final String? message;

  @override
  List<Object?> get props => [current, recent, loading, message];
}

/// Tracks the open document and recent files. Editors decide whether unsaved work blocks a switch.
class FileManagerCubit extends Cubit<FileManagerState> {
  FileManagerCubit({required OpenFileUseCase openFile})
    : _openFile = openFile,
      super(const FileManagerState());

  static const _maxRecent = 10;

  final OpenFileUseCase _openFile;

  Future<void> openPath(String path) async {
    emit(FileManagerState(current: state.current, recent: state.recent, loading: true));
    try {
      final file = await _openFile(path);
      final recent = [
        path,
        ...state.recent.where((p) => p != path),
      ].take(_maxRecent).toList();
      emit(FileManagerState(current: file, recent: recent));
    } catch (e) {
      emit(
        FileManagerState(
          current: state.current,
          recent: state.recent,
          message: e is AppFailure ? e.message : 'Could not open file: $e',
        ),
      );
    }
  }

  void clearMessage() {
    emit(FileManagerState(current: state.current, recent: state.recent));
  }

  void closeFile() {
    emit(FileManagerState(recent: state.recent));
  }
}
