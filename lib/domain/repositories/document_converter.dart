import '../../core/utils/cancellation_token.dart';

abstract interface class DocumentConverter {
  /// Converts [inputPath] to PDF and returns the temporary output path.
  /// Never writes next to the input file.
  Future<String> convertToPdf(
    String inputPath, {
    CancellationToken? cancellation,
  });
}
