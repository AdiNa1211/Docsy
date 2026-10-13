import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppSettingsState extends Equatable {
  const AppSettingsState({this.themeMode = ThemeMode.system});

  final ThemeMode themeMode;

  @override
  List<Object?> get props => [themeMode];
}

class AppSettingsCubit extends Cubit<AppSettingsState> {
  AppSettingsCubit() : super(const AppSettingsState());

  void setThemeMode(ThemeMode mode) => emit(AppSettingsState(themeMode: mode));

  void toggleTheme(Brightness current) => setThemeMode(
    current == Brightness.dark ? ThemeMode.light : ThemeMode.dark,
  );
}
