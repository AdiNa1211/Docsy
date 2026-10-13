import 'package:path/path.dart' as p;

import '../../core/utils/cancellation_token.dart';
import '../entities/image_edit_settings.dart';
import '../repositories/file_repository.dart';
import '../repositories/image_processor.dart';
import 'export_image_usecase.dart';

class BatchItemResult {
  const BatchItemResult({required this.source, this.output, this.error});

  final String source;
  final String? output;
  final String? error;

  bool get succeeded => output != null;
}

class BatchResizeUseCase {
  const BatchResizeUseCase(this._processor, this._files);

  final ImageProcessor _processor;
  final FileRepository _files;

  /// Emits one result per source. Stops early when [cancellation] is set.
  Stream<BatchItemResult> call({
    required List<String> sources,
    required String outputDirectory,
    required ImageEditSettings settings,
    CancellationToken? cancellation,
  }) async* {
    for (final source in sources) {
      if (cancellation?.isCancelled ?? false) return;
      try {
        final bytes = await _files.readBytes(source);
        final output = await _processor.process(bytes, settings);
        final target = await _uniquePath(
          outputPathFor(source, outputDirectory, settings.format),
        );
        await _files.writeBytes(target, output.bytes);
        yield BatchItemResult(source: source, output: target);
      } catch (e) {
        yield BatchItemResult(source: source, error: e.toString());
      }
    }
  }

  /// Appends _2, _3… so existing files are never overwritten.
  Future<String> _uniquePath(String path) async {
    if (!await _files.exists(path)) return path;
    final dir = p.dirname(path);
    final base = p.basenameWithoutExtension(path);
    final ext = p.extension(path);
    var i = 2;
    while (await _files.exists(p.join(dir, '${base}_$i$ext'))) {
      i++;
    }
    return p.join(dir, '${base}_$i$ext');
  }
}
