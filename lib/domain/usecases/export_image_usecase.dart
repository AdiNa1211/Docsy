import 'package:path/path.dart' as p;

import '../../core/error/app_failure.dart';
import '../entities/image_edit_settings.dart';
import '../entities/image_geometry.dart';
import '../repositories/file_repository.dart';
import '../repositories/image_processor.dart';

class ExportResult {
  const ExportResult({
    required this.path,
    required this.width,
    required this.height,
    required this.sizeBytes,
  });

  final String path;
  final int width;
  final int height;
  final int sizeBytes;
}

class ExportImageUseCase {
  const ExportImageUseCase(this._processor, this._files);

  final ImageProcessor _processor;
  final FileRepository _files;

  /// Returns null when [destination] exists and [overwrite] is false.
  Future<ExportResult?> call({
    required String source,
    required String destination,
    required ImageEditSettings settings,
    bool overwrite = false,
  }) async {
    if (p.equals(source, destination)) {
      throw const FileAccessFailure(
        'Choose a different file name. The original image is never overwritten.',
      );
    }
    if (!overwrite && await _files.exists(destination)) {
      return null;
    }
    final bytes = await _files.readBytes(source);
    final output = await _processor.process(bytes, settings);
    await _files.writeBytes(destination, output.bytes);
    return ExportResult(
      path: destination,
      width: output.width,
      height: output.height,
      sizeBytes: output.bytes.length,
    );
  }
}

/// Output file name for [source] written into [directory].
String outputPathFor(String source, String directory, OutputFormat format,
    {String suffix = '_resized'}) {
  final base = p.basenameWithoutExtension(source);
  return p.join(directory, '$base$suffix.${format.extension}');
}

/// Target size for display in the properties panel.
TargetSize targetSizeFor(ImageEditSettings settings, ImageInfo source) =>
    TargetSize.resolve(settings, source);
