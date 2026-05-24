import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class AppSettings extends Equatable {
  final ThemeMode themeMode;
  final bool notificationsEnabled;
  final bool autoBackupEnabled;
  final bool isInitialized;
  final String languageCode;
  final String dateFormat;
  final String businessName;
  final String businessPhone;
  final String businessAddress;
  final String backupPolicy;
  final String trialStartedAt;
  final bool trialOverrideUnlocked;

  static const int trialPeriodDays = 30;

  const AppSettings({
    this.themeMode = ThemeMode.light,
    this.notificationsEnabled = true,
    this.autoBackupEnabled = true,
    this.isInitialized = false,
    this.languageCode = 'en',
    this.dateFormat = 'dd MMM yyyy',
    this.businessName = 'RO Service Manager',
    this.businessPhone = '',
    this.businessAddress = '',
    this.backupPolicy = 'Manual + Before Clear',
    this.trialStartedAt = '',
    this.trialOverrideUnlocked = false,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? notificationsEnabled,
    bool? autoBackupEnabled,
    bool? isInitialized,
    String? languageCode,
    String? dateFormat,
    String? businessName,
    String? businessPhone,
    String? businessAddress,
    String? backupPolicy,
    String? trialStartedAt,
    bool? trialOverrideUnlocked,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      autoBackupEnabled: autoBackupEnabled ?? this.autoBackupEnabled,
      isInitialized: isInitialized ?? this.isInitialized,
      languageCode: languageCode ?? this.languageCode,
      dateFormat: dateFormat ?? this.dateFormat,
      businessName: businessName ?? this.businessName,
      businessPhone: businessPhone ?? this.businessPhone,
      businessAddress: businessAddress ?? this.businessAddress,
      backupPolicy: backupPolicy ?? this.backupPolicy,
      trialStartedAt: trialStartedAt ?? this.trialStartedAt,
      trialOverrideUnlocked:
          trialOverrideUnlocked ?? this.trialOverrideUnlocked,
    );
  }

  DateTime? get trialStartedOn => DateTime.tryParse(trialStartedAt);

  DateTime? get trialEndsOn =>
      trialStartedOn?.add(const Duration(days: trialPeriodDays));

  bool get isTrialExpired {
    final endsOn = trialEndsOn;
    if (endsOn == null) return false;
    return DateTime.now().isAfter(endsOn);
  }

  int get daysRemainingInTrial {
    final endsOn = trialEndsOn;
    if (endsOn == null) return trialPeriodDays;
    final remaining = endsOn.difference(DateTime.now()).inDays + 1;
    return remaining < 0 ? 0 : remaining;
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
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.light;
    }
  }

  @override
  List<Object?> get props => [
    themeMode,
    notificationsEnabled,
    autoBackupEnabled,
    isInitialized,
    languageCode,
    dateFormat,
    businessName,
    businessPhone,
    businessAddress,
    backupPolicy,
    trialStartedAt,
    trialOverrideUnlocked,
  ];
}
