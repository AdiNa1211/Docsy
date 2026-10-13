import 'dart:typed_data';

import 'package:docsy/core/utils/text_codec.dart';
import 'package:docsy/domain/repositories/file_repository.dart';
import 'package:docsy/presentation/document_editor/document_editor_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFiles extends Mock implements FileRepository {}

void main() {
  late _MockFiles files;

  setUp(() {
    files = _MockFiles();
    registerFallbackValue(Uint8List(0));
  });

  test('load decodes the file and starts clean', () async {
    when(() => files.readBytes('/d/a.txt'))
        .thenAnswer((_) async => Uint8List.fromList('hello'.codeUnits));
    final cubit = DocumentEditorCubit(files: files);

    await cubit.load('/d/a.txt');

    expect(cubit.state.text, 'hello');
    expect(cubit.state.isDirty, isFalse);
    await cubit.close();
  });

  test('a quick burst of typing is one undo step', () async {
    final cubit = DocumentEditorCubit(files: files);
    cubit
      ..edit('a')
      ..edit('ab')
      ..edit('abc');

    expect(cubit.state.undoStack, ['']);
    cubit.undo();
    expect(cubit.state.text, '');
    cubit.redo();
    expect(cubit.state.text, 'abc');
    await cubit.close();
  });

  test('save writes with the original encoding and clears dirty state', () async {
    when(() => files.writeBytes(any(), any())).thenAnswer((_) async {});
    final cubit = DocumentEditorCubit(files: files);
    cubit.edit('x');
    expect(cubit.state.isDirty, isTrue);

    final saved = await cubit.save(target: '/d/out.txt');

    expect(saved, isTrue);
    expect(cubit.state.isDirty, isFalse);
    verify(
      () => files.writeBytes('/d/out.txt', encodeText('x', TextEncodingKind.utf8)),
    ).called(1);
    await cubit.close();
  });

  test('save fails with a clear message when the encoding cannot store the text', () async {
    // 0xE9 is invalid UTF-8, so the file is loaded as Latin-1.
    when(() => files.readBytes('/d/latin.txt'))
        .thenAnswer((_) async => Uint8List.fromList([0x63, 0xE9]));
    final cubit = DocumentEditorCubit(files: files);
    await cubit.load('/d/latin.txt');
    cubit.edit('€');

    final saved = await cubit.save();

    expect(saved, isFalse);
    expect(cubit.state.message, contains('Save As UTF-8'));
    verifyNever(() => files.writeBytes(any(), any()));
    await cubit.close();
  });
}
