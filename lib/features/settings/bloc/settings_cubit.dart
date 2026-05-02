import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roapp/features/settings/models/app_settings.dart';
import 'package:roapp/features/settings/repositories/settings_repository.dart';

class SettingsCubit extends Cubit<AppSettings> {
  final SettingsRepository repository;

  SettingsCubit({SettingsRepository? repository})
    : repository = repository ?? SettingsRepository(),
      super(const AppSettings());

  Future<void> loadSettings() async {
    emit(await repository.loadSettings());
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await repository.updateThemeMode(mode);
    emit(state.copyWith(themeMode: mode));
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await repository.updateNotificationsEnabled(enabled);
    emit(state.copyWith(notificationsEnabled: enabled));
  }

  Future<void> setAutoBackupEnabled(bool enabled) async {
    await repository.updateAutoBackupEnabled(enabled);
    emit(state.copyWith(autoBackupEnabled: enabled));
  }
}
