import 'dart:typed_data';

import 'package:docsy/core/error/app_failure.dart';
import 'package:docsy/domain/entities/image_edit_settings.dart';
import 'package:docsy/domain/entities/image_geometry.dart';
import 'package:docsy/domain/repositories/file_repository.dart';
import 'package:docsy/domain/repositories/image_processor.dart';
import 'package:docsy/domain/usecases/export_image_usecase.dart';
import 'package:flutter_test/flutter_test.dart' hide ImageInfo;
import 'package:mocktail/mocktail.dart';

class _MockFiles extends Mock implements FileRepository {}

class _MockProcessor extends Mock implements ImageProcessor {}

void main() {
  late _MockFiles files;
  late _MockProcessor processor;
  late ExportImageUseCase useCase;

  setUp(() {
    files = _MockFiles();
    processor = _MockProcessor();
    useCase = ExportImageUseCase(processor, files);
  });

  test('refuses to write over the source image', () async {
    expect(
      () => useCase(
        source: '/pics/a.png',
        destination: '/pics/a.png',
        settings: ImageEditSettings.initial,
      ),
      throwsA(isA<FileAccessFailure>()),
    );
    verifyNever(() => files.writeBytes(any(), any()));
  });

  test('returns null without writing when destination exists', () async {
    when(() => files.exists('/out/a.png')).thenAnswer((_) async => true);

    final result = await useCase(
      source: '/pics/a.png',
      destination: '/out/a.png',
      settings: ImageEditSettings.initial,
    );

    expect(result, isNull);
    verifyNever(() => files.writeBytes(any(), any()));
  });

  test('writes the processed bytes when overwrite is confirmed', () async {
    final encoded = Uint8List.fromList([1, 2, 3]);
    when(() => files.exists('/out/a.png')).thenAnswer((_) async => true);
    when(() => files.readBytes('/pics/a.png'))
        .thenAnswer((_) async => Uint8List(0));
    when(
      () => processor.process(any(), any()),
    ).thenAnswer(
      (_) async => ProcessedImage(bytes: encoded, width: 10, height: 5),
    );
    when(() => files.writeBytes('/out/a.png', encoded))
        .thenAnswer((_) async {});

    final result = await useCase(
      source: '/pics/a.png',
      destination: '/out/a.png',
      settings: ImageEditSettings.initial,
      overwrite: true,
    );

    expect(result?.width, 10);
    expect(result?.height, 5);
    expect(result?.sizeBytes, 3);
    verify(() => files.writeBytes('/out/a.png', encoded)).called(1);
  });
}
