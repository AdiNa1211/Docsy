import 'package:path/path.dart' as p;

import '../../core/error/app_failure.dart';
import '../../core/utils/cancellation_token.dart';
import '../entities/file_kind.dart';
import '../repositories/document_converter.dart';
import '../repositories/file_repository.dart';

class ConvertDocumentUseCase {
  const ConvertDocumentUseCase(this._converter, this._files);

  final DocumentConverter _converter;
  final FileRepository _files;

  /// Converts to PDF at [destination]. Returns null if it exists and [overwrite] is false.
  Future<String?> call({
    required String source,
    required String destination,
    bool overwrite = false,
    CancellationToken? cancellation,
  }) async {
    final kind = FileKind.fromPath(source);
    if (!(kind == FileKind.docx || kind == FileKind.doc || kind == FileKind.rtf)) {
      throw UnsupportedFormatFailure('Only DOC, DOCX and RTF can be converted.');
    }
    if (p.equals(source, destination)) {
      throw const FileAccessFailure('Choose a different output file.');
    }
    if (!overwrite && await _files.exists(destination)) return null;

    final temp = await _converter.convertToPdf(
      source,
      cancellation: cancellation,
    );
    if (cancellation?.isCancelled ?? false) {
      throw const OperationCancelledFailure();
    }
    await _files.copy(temp, destination);
    return destination;
  }
}
