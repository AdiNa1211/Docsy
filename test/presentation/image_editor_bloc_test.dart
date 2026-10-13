import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:docsy/domain/entities/file_kind.dart';
import 'package:docsy/domain/entities/image_edit_settings.dart';
import 'package:docsy/domain/entities/image_geometry.dart';
import 'package:docsy/domain/entities/opened_file.dart';
import 'package:docsy/domain/repositories/file_repository.dart';
import 'package:docsy/domain/repositories/image_processor.dart';
import 'package:docsy/domain/usecases/export_image_usecase.dart';
import 'package:docsy/presentation/image_editor/image_editor_bloc.dart';
import 'package:flutter_test/flutter_test.dart' hide ImageInfo;
import 'package:mocktail/mocktail.dart';

class _MockFiles extends Mock implements FileRepository {}

class _MockProcessor extends Mock implements ImageProcessor {}

class _MockExport extends Mock implements ExportImageUseCase {}

void main() {
  const path = '/pics/photo.png';
  final bytes = Uint8List.fromList([0, 1, 2]);
  late _MockFiles files;
  late _MockProcessor processor;
  late _MockExport export;

  setUp(() {
    files = _MockFiles();
    processor = _MockProcessor();
    export = _MockExport();

    when(() => files.inspect(path)).thenAnswer(
      (_) async => const OpenedFile(
        path: path,
        kind: FileKind.png,
        sizeBytes: 3,
      ),
    );
    when(() => files.readBytes(path)).thenAnswer((_) async => bytes);
    when(() => processor.inspect(bytes)).thenAnswer(
      (_) async => const ImageInfo(width: 400, height: 200),
    );
    when(
      () => processor.process(
        any(),
        any(),
        previewMaxSide: any(named: 'previewMaxSide'),
      ),
    ).thenAnswer(
      (_) async => ProcessedImage(bytes: bytes, width: 1, height: 1),
    );
  });

  ImageEditorBloc build() => ImageEditorBloc(
    files: files,
    exportImage: export,
    processor: processor,
  );

  blocTest<ImageEditorBloc, ImageEditorState>(
    'opening an image loads its size and becomes ready',
    build: build,
    act: (bloc) => bloc.add(const ImageOpened(path)),
    wait: const Duration(milliseconds: 400),
    verify: (bloc) {
      expect(bloc.state.status, ImageEditorStatus.ready);
      expect(bloc.state.info, const ImageInfo(width: 400, height: 200));
      expect(bloc.state.previewBytes, isNotNull);
    },
  );

  blocTest<ImageEditorBloc, ImageEditorState>(
    'percent resize is recorded in history and can be undone',
    build: build,
    seed: () => ImageEditorState(
      status: ImageEditorStatus.ready,
      info: const ImageInfo(width: 400, height: 200),
      file: const OpenedFile(path: path, kind: FileKind.png, sizeBytes: 3),
    ),
    act: (bloc) async {
      bloc.add(const ImagePercentChanged(50));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      bloc.add(const ImageUndoRequested());
    },
    wait: const Duration(milliseconds: 400),
    verify: (bloc) {
      expect(bloc.state.settings, ImageEditSettings.initial);
      expect(bloc.state.redoStack.length, 1);
      expect(bloc.state.canUndo, isFalse);
    },
  );

  blocTest<ImageEditorBloc, ImageEditorState>(
    'width change with aspect lock updates height to match',
    build: build,
    seed: () => ImageEditorState(
      status: ImageEditorStatus.ready,
      info: const ImageInfo(width: 400, height: 200),
      file: const OpenedFile(path: path, kind: FileKind.png, sizeBytes: 3),
    ),
    act: (bloc) => bloc.add(const ImagePixelWidthChanged(100)),
    wait: const Duration(milliseconds: 400),
    verify: (bloc) {
      expect(bloc.state.settings.width, 100);
      expect(bloc.state.settings.height, 50);
      expect(bloc.state.outputSize, const TargetSize(width: 100, height: 50));
    },
  );

  blocTest<ImageEditorBloc, ImageEditorState>(
    'export asks for confirmation when the destination exists',
    build: build,
    setUp: () {
      when(
        () => export(
          source: any(named: 'source'),
          destination: any(named: 'destination'),
          settings: any(named: 'settings'),
          overwrite: false,
        ),
      ).thenAnswer((_) async => null);
    },
    act: (bloc) async {
      bloc.add(const ImageOpened(path));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      bloc.add(const ImageExportRequested(destination: '/out/photo.png'));
    },
    wait: const Duration(milliseconds: 300),
    verify: (bloc) {
      expect(bloc.state.overwritePrompt, '/out/photo.png');
      expect(bloc.state.exporting, isFalse);
    },
  );
}
