import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roapp/core/database/database_helper.dart';
import 'package:roapp/features/settings/repositories/settings_repository.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('SettingsRepository', () {
    final repository = SettingsRepository();

    test(
      'persists theme, language, business profile, and backup policy',
      () async {
        final db = await DatabaseHelper.instance.database;
        await db.delete('app_settings');

        await repository.updateThemeMode(ThemeMode.dark);
        await repository.updateLanguageCode('hi');
        await repository.updateDateFormat('dd/MM/yyyy');
        await repository.updateBusinessProfile(
          businessName: 'Ramesh Water Care',
          businessPhone: '+91 9000000000',
          businessAddress: 'Rohini, Delhi',
        );
        await repository.updateBackupPolicy('Manual');

        final loaded = await repository.loadSettings();
        expect(loaded.isInitialized, true);
        expect(loaded.themeMode, ThemeMode.dark);
        expect(loaded.languageCode, 'hi');
        expect(loaded.dateFormat, 'dd/MM/yyyy');
        expect(loaded.businessName, 'Ramesh Water Care');
        expect(loaded.businessPhone, '+91 9000000000');
        expect(loaded.businessAddress, 'Rohini, Delhi');
        expect(loaded.backupPolicy, 'Manual');
        expect(loaded.trialStartedAt, isNotEmpty);
        expect(loaded.trialOverrideUnlocked, false);
      },
    );
  });
}
