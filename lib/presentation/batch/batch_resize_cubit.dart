import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/utils/cancellation_token.dart';
import '../../domain/entities/image_edit_settings.dart';
import '../../domain/repositories/file_repository.dart';
import '../../domain/usecases/batch_resize_usecase.dart';

class BatchResizeState extends Equatable {
  const BatchResizeState({
    this.sources = const [],
    this.outputDirectory,
    this.settings = ImageEditSettings.initial,
    this.processed = 0,
    this.running = false,
    this.results = const [],
    this.message,
  });

  final List<String> sources;
  final String? outputDirectory;
  final ImageEditSettings settings;
  final int processed;
  final bool running;
  final List<BatchItemResult> results;
  final String? message;

  double get progress => sources.isEmpty ? 0 : processed / sources.length;

  @override
  List<Object?> get props => [
    sources,
    outputDirectory,
    settings,
    processed,
    running,
    results,
    message,
  ];
}

class BatchResizeCubit extends Cubit<BatchResizeState> {
  BatchResizeCubit({
    required BatchResizeUseCase batch,
    required FileRepository files,
  }) : _batch = batch,
       _files = files,
       super(const BatchResizeState());

  final BatchResizeUseCase _batch;
  final FileRepository _files;
  CancellationToken? _token;

  void addSources(List<String> paths) {
    final merged = {...state.sources, ...paths}.toList();
    emit(_copy(sources: merged));
  }

  void clearSources() {
    emit(_copy(sources: const [], processed: 0, results: const []));
  }

  void removeSource(String path) {
    emit(_copy(sources: state.sources.where((p) => p != path).toList()));
  }

  void setSettings(ImageEditSettings settings) => emit(_copy(settings: settings));

  void setOutputDirectory(String directory) =>
      emit(_copy(outputDirectory: directory));

  Future<void> run() async {
    final output = state.outputDirectory;
    if (output == null || state.sources.isEmpty || state.running) return;
    final token = _token = CancellationToken();
    emit(_copy(running: true, processed: 0, results: const [], message: null));

    final results = <BatchItemResult>[];
    await for (final result in _batch(
      sources: state.sources,
      outputDirectory: output,
      settings: state.settings,
      cancellation: token,
    )) {
      results.add(result);
      emit(_copy(processed: results.length, results: List.of(results)));
    }

    final cancelled = token.isCancelled;
    final failed = results.where((r) => !r.succeeded).length;
    emit(
      _copy(
        running: false,
        message: cancelled
            ? 'Stopped after ${results.length} of ${state.sources.length} files.'
            : 'Finished. ${results.length - failed} saved, $failed failed.',
      ),
    );
  }

  void cancel() => _token?.cancel();

  BatchResizeState _copy({
    List<String>? sources,
    String? outputDirectory,
    ImageEditSettings? settings,
    int? processed,
    bool? running,
    List<BatchItemResult>? results,
    String? message,
  }) {
    return BatchResizeState(
      sources: sources ?? state.sources,
      outputDirectory: outputDirectory ?? state.outputDirectory,
      settings: settings ?? state.settings,
      processed: processed ?? state.processed,
      running: running ?? state.running,
      results: results ?? state.results,
      message: message,
    );
  }
}
