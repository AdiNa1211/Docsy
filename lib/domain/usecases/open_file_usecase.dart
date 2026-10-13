import '../../core/constants/app_limits.dart';
import '../../core/error/app_failure.dart';
import '../entities/file_kind.dart';
import '../entities/opened_file.dart';
import '../repositories/file_repository.dart';

class OpenFileUseCase {
  const OpenFileUseCase(this._files);

  final FileRepository _files;

  Future<OpenedFile> call(String path) async {
    final kind = FileKind.fromPath(path);
    if (kind == FileKind.unsupported) {
      throw UnsupportedFormatFailure('Unsupported file type: $path');
    }
    final file = await _files.inspect(path);
    if (file.sizeBytes > AppLimits.maxFileBytes) {
      throw FileTooLargeFailure(
        'This file is larger than ${AppLimits.maxFileBytes ~/ (1024 * 1024)} MB.',
      );
    }
    return file;
  }
}
