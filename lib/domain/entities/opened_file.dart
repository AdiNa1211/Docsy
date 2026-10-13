import 'package:equatable/equatable.dart';
import 'package:path/path.dart' as p;

import 'file_kind.dart';

class OpenedFile extends Equatable {
  const OpenedFile({
    required this.path,
    required this.kind,
    required this.sizeBytes,
  });

  final String path;
  final FileKind kind;
  final int sizeBytes;

  String get name => p.basename(path);
  String get directory => p.dirname(path);
  String get baseName => p.basenameWithoutExtension(path);

  @override
  List<Object?> get props => [path, kind, sizeBytes];
}
