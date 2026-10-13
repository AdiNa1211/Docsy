import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/error/app_failure.dart';
import '../../core/utils/cancellation_token.dart';
import '../../domain/usecases/convert_document_usecase.dart';

enum ConversionStatus { idle, converting, overwriteRequired, done, failure, cancelled }

class ConversionState extends Equatable {
  const ConversionState({
    this.status = ConversionStatus.idle,
    this.outputPath,
    this.message,
  });

  final ConversionStatus status;
  final String? outputPath;
  final String? message;

  @override
  List<Object?> get props => [status, outputPath, message];
}

class ConversionCubit extends Cubit<ConversionState> {
  ConversionCubit({required ConvertDocumentUseCase convert})
    : _convert = convert,
      super(const ConversionState());

  final ConvertDocumentUseCase _convert;
  CancellationToken? _token;

  Future<void> convertToPdf({
    required String source,
    required String destination,
    bool overwrite = false,
  }) async {
    if (state.status == ConversionStatus.converting) return;
    final token = _token = CancellationToken();
    emit(const ConversionState(status: ConversionStatus.converting));
    try {
      final output = await _convert(
        source: source,
        destination: destination,
        overwrite: overwrite,
        cancellation: token,
      );
      if (output == null) {
        emit(
          ConversionState(
            status: ConversionStatus.overwriteRequired,
            outputPath: destination,
            message: 'The destination already exists.',
          ),
        );
        return;
      }
      emit(
        ConversionState(
          status: ConversionStatus.done,
          outputPath: output,
          message: 'Saved PDF. Formatting may differ from the original.',
        ),
      );
    } on OperationCancelledFailure {
      emit(const ConversionState(status: ConversionStatus.cancelled));
    } catch (e) {
      emit(
        ConversionState(
          status: ConversionStatus.failure,
          message: e is AppFailure ? e.message : 'Conversion failed: $e',
        ),
      );
    }
  }

  void cancel() => _token?.cancel();

  void reset() => emit(const ConversionState());
}
