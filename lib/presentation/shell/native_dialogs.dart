import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

import '../../domain/entities/file_kind.dart';

/// Thin wrapper over native file dialogs so screens stay free of picker details.
abstract final class NativeDialogs {
  static Future<String?> openDocumentOrImage() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Open file',
      type: FileType.custom,
      allowedExtensions: [
        ...FileKind.documentExtensions,
        ...FileKind.imageExtensions,
      ],
    );
    return result?.files.single.path;
  }

  static Future<List<String>> openImages() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Choose images',
      type: FileType.custom,
      allowedExtensions: FileKind.imageExtensions,
      allowMultiple: true,
    );
    return result?.paths.whereType<String>().toList() ?? const [];
  }

  static Future<String?> saveAs({
    required String suggestedName,
    required String extension,
  }) async {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save as',
      fileName: suggestedName,
      type: FileType.custom,
      allowedExtensions: [extension],
    );
    return path == null ? null : withExtension(path, extension);
  }

  static Future<String?> chooseFolder() =>
      FilePicker.platform.getDirectoryPath(dialogTitle: 'Choose output folder');

  /// Adds [extension] when the dialog did not already include it.
  static String withExtension(String path, String extension) {
    final wanted = '.$extension';
    return p.extension(path).toLowerCase() == wanted ? path : '$path$wanted';
  }
}
