/// Typed failures surfaced to the presentation layer.
sealed class AppFailure implements Exception {
  const AppFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

class UnsupportedFormatFailure extends AppFailure {
  const UnsupportedFormatFailure(super.message);
}

class FileTooLargeFailure extends AppFailure {
  const FileTooLargeFailure(super.message);
}

class FileAccessFailure extends AppFailure {
  const FileAccessFailure(super.message);
}

class ImageProcessingFailure extends AppFailure {
  const ImageProcessingFailure(super.message);
}

class ConversionFailure extends AppFailure {
  const ConversionFailure(super.message);
}

class OperationCancelledFailure extends AppFailure {
  const OperationCancelledFailure([super.message = 'Operation cancelled.']);
}
