import 'package:path/path.dart' as p;

enum FileKind {
  pdf,
  docx,
  doc,
  rtf,
  txt,
  jpeg,
  png,
  webp,
  bmp,
  gif,
  tiff,
  unsupported;

  bool get isDocument => switch (this) {
    pdf || docx || doc || rtf || txt => true,
    _ => false,
  };

  bool get isImage => switch (this) {
    jpeg || png || webp || bmp || gif || tiff => true,
    _ => false,
  };

  static FileKind fromPath(String path) {
    final ext = p.extension(path).toLowerCase().replaceFirst('.', '');
    return switch (ext) {
      'pdf' => pdf,
      'docx' => docx,
      'doc' => doc,
      'rtf' => rtf,
      'txt' => txt,
      'jpg' || 'jpeg' => jpeg,
      'png' => png,
      'webp' => webp,
      'bmp' => bmp,
      'gif' => gif,
      'tif' || 'tiff' => tiff,
      _ => unsupported,
    };
  }

  static const documentExtensions = [
    'pdf', 'docx', 'doc', 'rtf', 'txt',
  ];

  static const imageExtensions = [
    'jpg', 'jpeg', 'png', 'webp', 'bmp', 'gif', 'tif', 'tiff',
  ];
}
