import 'dart:typed_data';

import '../entities/opened_file.dart';

abstract interface class FileRepository {
  /// Throws [AppFailure] when the file is missing, unreadable or too large.
  Future<OpenedFile> inspect(String path);

  Future<Uint8List> readBytes(String path);

  /// Writes atomically: a temp file is renamed only after a full write.
  Future<void> writeBytes(String path, Uint8List bytes);

  Future<void> copy(String from, String to);

  Future<bool> exists(String path);
}
