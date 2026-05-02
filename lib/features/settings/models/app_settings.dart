import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class AppSettings extends Equatable {
  final ThemeMode themeMode;
  final bool notificationsEnabled;
  final bool autoBackupEnabled;
  final String languageCode;
  final String dateFormat;
  final String businessName;
  final String businessPhone;
  final String businessAddress;
  final String backupPolicy;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.notificationsEnabled = true,
    this.autoBackupEnabled = true,
    this.languageCode = 'en',
    this.dateFormat = 'dd MMM yyyy',
    this.businessName = 'RO Service Manager',
    this.businessPhone = '',
    this.businessAddress = '',
    this.backupPolicy = 'Manual + Before Clear',
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? notificationsEnabled,
    bool? autoBackupEnabled,
    String? languageCode,
    String? dateFormat,
    String? businessName,
    String? businessPhone,
    String? businessAddress,
    String? backupPolicy,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      autoBackupEnabled: autoBackupEnabled ?? this.autoBackupEnabled,
      languageCode: languageCode ?? this.languageCode,
      dateFormat: dateFormat ?? this.dateFormat,
      businessName: businessName ?? this.businessName,
      businessPhone: businessPhone ?? this.businessPhone,
      businessAddress: businessAddress ?? this.businessAddress,
      backupPolicy: backupPolicy ?? this.backupPolicy,
    );
  }

  String get themeStorageValue {
    switch (themeMode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  static ThemeMode themeModeFromStorage(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  @override
  List<Object?> get props => [
    themeMode,
    notificationsEnabled,
    autoBackupEnabled,
    languageCode,
    dateFormat,
    businessName,
    businessPhone,
    businessAddress,
    backupPolicy,
  ];
}
