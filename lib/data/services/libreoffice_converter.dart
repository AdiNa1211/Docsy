import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../core/error/app_failure.dart';
import '../../core/utils/cancellation_token.dart';
import '../../domain/repositories/document_converter.dart';

/// Converts DOC/DOCX/RTF to PDF with LibreOffice headless.
/// Output goes to a private temp folder and never beside the input.
class LibreOfficeConverter implements DocumentConverter {
  const LibreOfficeConverter({this.timeout = const Duration(minutes: 5)});

  final Duration timeout;

  @override
  Future<String> convertToPdf(
    String inputPath, {
    CancellationToken? cancellation,
  }) async {
    final executable = await _findSoffice();
    if (executable == null) {
      throw const ConversionFailure(
        'LibreOffice was not found. Install it to convert DOC, DOCX and RTF files.',
      );
    }

    final workDir = await Directory.systemTemp.createTemp('docsy_convert_');
    final profileDir = Directory(p.join(workDir.path, 'profile'));
    final outDir = Directory(p.join(workDir.path, 'out'))..createSync();

    final process = await Process.start(executable, [
      '--headless',
      '--norestore',
      '-env:UserInstallation=${Uri.file(profileDir.path)}',
      '--convert-to',
      'pdf',
      '--outdir',
      outDir.path,
      inputPath,
    ]);
    cancellation?.onCancel(process.kill);

    final stderrText = process.stderr.transform(const SystemEncoding().decoder);
    final stderrBuffer = StringBuffer();
    final stderrSub = stderrText.listen(stderrBuffer.write);

    final int exitCode;
    try {
      exitCode = await process.exitCode.timeout(timeout, onTimeout: () {
        process.kill();
        throw const ConversionFailure('Conversion timed out.');
      });
    } finally {
      await stderrSub.cancel();
    }

    if (cancellation?.isCancelled ?? false) {
      await _cleanup(workDir);
      throw const OperationCancelledFailure();
    }

    final expected = File(
      p.join(outDir.path, '${p.basenameWithoutExtension(inputPath)}.pdf'),
    );
    if (exitCode != 0 || !expected.existsSync()) {
      await _cleanup(workDir);
      final detail = stderrBuffer.toString().trim();
      throw ConversionFailure(
        'Conversion failed.${detail.isEmpty ? '' : ' $detail'}',
      );
    }
    return expected.path;
  }

  Future<void> _cleanup(Directory dir) async {
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  Future<String?> _findSoffice() async {
    final candidates = <String>[
      if (Platform.isMacOS) '/Applications/LibreOffice.app/Contents/MacOS/soffice',
      if (Platform.isWindows) ...[
        r'C:\Program Files\LibreOffice\program\soffice.exe',
        r'C:\Program Files (x86)\LibreOffice\program\soffice.exe',
      ],
      if (Platform.isLinux) ...['/usr/bin/soffice', '/usr/bin/libreoffice'],
    ];
    for (final path in candidates) {
      if (File(path).existsSync()) return path;
    }
    final lookup = Platform.isWindows ? 'where' : 'which';
    for (final name in ['soffice', 'libreoffice']) {
      final result = await Process.run(lookup, [name]);
      if (result.exitCode == 0) {
        return result.stdout.toString().split(RegExp(r'\r?\n')).first.trim();
      }
    }
    return null;
  }
}
