import 'package:bloc_test/bloc_test.dart';
import 'package:docsy/domain/usecases/convert_document_usecase.dart';
import 'package:docsy/presentation/conversion/conversion_cubit.dart';
import 'package:docsy/presentation/conversion/conversion_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockConvert extends Mock implements ConvertDocumentUseCase {}

class _MockConversionCubit extends MockCubit<ConversionState>
    implements ConversionCubit {}

void main() {
  testWidgets('conversion panel offers PDF conversion for Word files', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => ConversionCubit(convert: _MockConvert()),
          child: ConversionPanel(
            fileName: 'report.docx',
            onConvert: () {},
            onOpenResult: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('report.docx'), findsOneWidget);
    expect(find.text('Convert to PDF…'), findsOneWidget);
  });

  testWidgets('conversion panel shows the failure message from the cubit', (
    tester,
  ) async {
    final cubit = _MockConversionCubit();
    whenListen(
      cubit,
      Stream.value(
        const ConversionState(
          status: ConversionStatus.failure,
          message: 'LibreOffice was not found.',
        ),
      ),
      initialState: const ConversionState(
        status: ConversionStatus.failure,
        message: 'LibreOffice was not found.',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<ConversionCubit>.value(
          value: cubit,
          child: ConversionPanel(
            fileName: 'broken.doc',
            onConvert: () {},
            onOpenResult: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('LibreOffice was not found.'), findsOneWidget);
  });
}
