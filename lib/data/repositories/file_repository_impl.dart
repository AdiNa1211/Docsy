import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../../core/constants/app_limits.dart';
import '../../core/error/app_failure.dart';
import '../../domain/entities/file_kind.dart';
import '../../domain/entities/opened_file.dart';
import '../../domain/repositories/file_repository.dart';

class FileRepositoryImpl implements FileRepository {
  const FileRepositoryImpl();

  @override
  Future<OpenedFile> inspect(String path) async {
    final file = File(path);
    try {
      if (!await file.exists()) {
        throw FileAccessFailure('File not found: ${p.basename(path)}');
      }
      final size = await file.length();
      if (size > AppLimits.maxFileBytes) {
        throw FileTooLargeFailure(
          'This file is larger than ${AppLimits.maxFileBytes ~/ (1024 * 1024)} MB.',
        );
      }
      return OpenedFile(
        path: path,
        kind: FileKind.fromPath(path),
        sizeBytes: size,
      );
    } on FileSystemException catch (e) {
      throw FileAccessFailure('Cannot access ${p.basename(path)}: ${e.message}');
    }
  }

  @override
  Future<Uint8List> readBytes(String path) async {
    try {
      return await File(path).readAsBytes();
    } on FileSystemException catch (e) {
      throw FileAccessFailure('Cannot read ${p.basename(path)}: ${e.message}');
    }
  }

  @override
  Future<void> writeBytes(String path, Uint8List bytes) async {
    final temp = File('$path.${DateTime.now().microsecondsSinceEpoch}.tmp');
    try {
      await temp.writeAsBytes(bytes, flush: true);
      await temp.rename(path);
    } on FileSystemException catch (e) {
      if (await temp.exists()) await temp.delete();
      throw FileAccessFailure(
        'Could not save ${p.basename(path)}. Check permissions and disk space. (${e.message})',
      );
    }
  }

  @override
  Future<void> copy(String from, String to) async {
    try {
      await File(from).copy(to);
    } on FileSystemException catch (e) {
      throw FileAccessFailure('Could not copy to ${p.basename(to)}: ${e.message}');
    }
  }

  @override
  Future<bool> exists(String path) => File(path).exists();
}
