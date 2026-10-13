import 'package:get_it/get_it.dart';

import '../../data/repositories/file_repository_impl.dart';
import '../../data/services/image_processor_impl.dart';
import '../../data/services/libreoffice_converter.dart';
import '../../domain/repositories/document_converter.dart';
import '../../domain/repositories/file_repository.dart';
import '../../domain/repositories/image_processor.dart';
import '../../domain/usecases/batch_resize_usecase.dart';
import '../../domain/usecases/convert_document_usecase.dart';
import '../../domain/usecases/export_image_usecase.dart';
import '../../domain/usecases/open_file_usecase.dart';
import '../../presentation/batch/batch_resize_cubit.dart';
import '../../presentation/conversion/conversion_cubit.dart';
import '../../presentation/document_editor/document_editor_cubit.dart';
import '../../presentation/file_manager/file_manager_cubit.dart';
import '../../presentation/image_editor/image_editor_bloc.dart';
import '../../presentation/settings/app_settings_cubit.dart';

final GetIt sl = GetIt.instance;

/// Singletons hold stateless services; cubits are factories so each screen owns its state.
void configureDependencies() {
  sl
    ..registerLazySingleton<FileRepository>(() => const FileRepositoryImpl())
    ..registerLazySingleton<ImageProcessor>(() => const ImageProcessorImpl())
    ..registerLazySingleton<DocumentConverter>(
      () => const LibreOfficeConverter(),
    )
    ..registerLazySingleton(() => OpenFileUseCase(sl()))
    ..registerLazySingleton(() => ExportImageUseCase(sl(), sl()))
    ..registerLazySingleton(() => BatchResizeUseCase(sl(), sl()))
    ..registerLazySingleton(() => ConvertDocumentUseCase(sl(), sl()))
    ..registerLazySingleton(AppSettingsCubit.new)
    ..registerFactory(() => FileManagerCubit(openFile: sl()))
    ..registerFactory(
      () => ImageEditorBloc(
        files: sl(),
        exportImage: sl(),
        processor: sl(),
      ),
    )
    ..registerFactory(() => DocumentEditorCubit(files: sl()))
    ..registerFactory(() => BatchResizeCubit(batch: sl(), files: sl()))
    ..registerFactory(() => ConversionCubit(convert: sl()));
}
