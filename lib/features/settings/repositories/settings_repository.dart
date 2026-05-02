import 'package:flutter/material.dart';
import 'package:roapp/core/database/database_helper.dart';
import 'package:roapp/features/settings/models/app_settings.dart';
import 'package:sqflite/sqflite.dart';

class SettingsRepository {
  static const _themeModeKey = 'theme_mode';
  static const _notificationsEnabledKey = 'notifications_enabled';
  static const _autoBackupEnabledKey = 'auto_backup_enabled';
  static const _languageCodeKey = 'language_code';
  static const _dateFormatKey = 'date_format';
  static const _businessNameKey = 'business_name';
  static const _businessPhoneKey = 'business_phone';
  static const _businessAddressKey = 'business_address';
  static const _backupPolicyKey = 'backup_policy';

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
      languageCode: _parseString(settingsMap[_languageCodeKey], 'en'),
      dateFormat: _parseString(settingsMap[_dateFormatKey], 'dd MMM yyyy'),
      businessName: _parseString(
        settingsMap[_businessNameKey],
        'RO Service Manager',
      ),
      businessPhone: _parseString(settingsMap[_businessPhoneKey], ''),
      businessAddress: _parseString(settingsMap[_businessAddressKey], ''),
      backupPolicy: _parseString(
        settingsMap[_backupPolicyKey],
        'Manual + Before Clear',
      ),
    );
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    await _writeSetting(
      _themeModeKey,
      AppSettings(themeMode: mode).themeStorageValue,
    );
  }

  Future<void> updateNotificationsEnabled(bool enabled) async {
    await _writeSetting(_notificationsEnabledKey, enabled ? '1' : '0');
  }

  Future<void> updateAutoBackupEnabled(bool enabled) async {
    await _writeSetting(_autoBackupEnabledKey, enabled ? '1' : '0');
  }

  Future<void> updateLanguageCode(String value) async {
    await _writeSetting(_languageCodeKey, value);
  }

  Future<void> updateDateFormat(String value) async {
    await _writeSetting(_dateFormatKey, value);
  }

  Future<void> updateBusinessProfile({
    required String businessName,
    required String businessPhone,
    required String businessAddress,
  }) async {
    await _writeSetting(_businessNameKey, businessName);
    await _writeSetting(_businessPhoneKey, businessPhone);
    await _writeSetting(_businessAddressKey, businessAddress);
  }

  Future<void> updateBackupPolicy(String value) async {
    await _writeSetting(_backupPolicyKey, value);
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

  String _parseString(String? value, String defaultValue) {
    if (value == null) return defaultValue;
    final trimmed = value.trim();
    return trimmed.isEmpty ? defaultValue : trimmed;
  }
}
