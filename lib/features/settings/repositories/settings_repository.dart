import 'package:flutter/material.dart';
import 'package:roapp/core/database/database_helper.dart';
import 'package:roapp/features/settings/models/app_settings.dart';
import 'package:sqflite/sqflite.dart';

class SettingsRepository {
  static const _themeModeKey = 'theme_mode';
  static const _notificationsEnabledKey = 'notifications_enabled';
  static const _autoBackupEnabledKey = 'auto_backup_enabled';

  final DatabaseHelper dbHelper;

  SettingsRepository({DatabaseHelper? dbHelper})
    : dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<AppSettings> loadSettings() async {
    final db = await dbHelper.database;
    final records = await db.query('app_settings');
    final settingsMap = <String, String>{
      for (final row in records)
        row['key'] as String: row['value'] as String? ?? '',
    };

    return AppSettings(
      themeMode: AppSettings.themeModeFromStorage(settingsMap[_themeModeKey]),
      notificationsEnabled: _parseBool(
        settingsMap[_notificationsEnabledKey],
        defaultValue: true,
      ),
      autoBackupEnabled: _parseBool(
        settingsMap[_autoBackupEnabledKey],
        defaultValue: true,
      ),
    );
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    await _writeSetting(_themeModeKey, AppSettings(themeMode: mode).themeStorageValue);
  }

  Future<void> updateNotificationsEnabled(bool enabled) async {
    await _writeSetting(_notificationsEnabledKey, enabled ? '1' : '0');
  }

  Future<void> updateAutoBackupEnabled(bool enabled) async {
    await _writeSetting(_autoBackupEnabledKey, enabled ? '1' : '0');
  }

  Future<void> _writeSetting(String key, String value) async {
    final db = await dbHelper.database;
    await db.insert('app_settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  bool _parseBool(String? value, {required bool defaultValue}) {
    if (value == null || value.isEmpty) return defaultValue;
    return value == '1' || value.toLowerCase() == 'true';
  }
}
