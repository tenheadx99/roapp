import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:roapp/features/customer/repositories/customer_repository.dart';
import 'package:roapp/features/inventory/repositories/inventory_repository.dart';
import 'package:roapp/features/operations/repositories/operations_repository.dart';
import 'package:roapp/features/settings/repositories/settings_repository.dart';

/// Schedules device notifications for upcoming work so the owner hears about
/// due services, AMC renewals, and low stock without opening the app.
///
/// Scheduling runs on every app launch: it recomputes the next 7 days from
/// the local database and replaces all previously scheduled notifications.
class LocalNotificationService {
  LocalNotificationService._();
  static final LocalNotificationService instance = LocalNotificationService._();

  static const _digestHour = 9; // 9:00 AM local time
  static const _daysAhead = 7;
  static const _channel = AndroidNotificationDetails(
    'reminders',
    'Service Reminders',
    channelDescription:
        'Due services, AMC renewals, and low-stock alerts from RO Manager.',
    importance: Importance.high,
    priority: Priority.high,
  );

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  bool get _supportedPlatform =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<void> init() async {
    if (_initialized || !_supportedPlatform) return;

    tz_data.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (e) {
      debugPrint('Could not resolve local timezone, using default: $e');
    }

    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/launcher_icon'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  /// Recomputes and reschedules the daily reminder digests for the next
  /// [_daysAhead] days. Call after [init].
  Future<void> refreshSchedules() async {
    if (!_initialized) return;

    try {
      final settings = await SettingsRepository().loadSettings();
      if (!settings.notificationsEnabled) {
        await _plugin.cancelAll();
        return;
      }

      final digests = await _buildDailyDigests();
      await _plugin.cancelAll();

      for (final digest in digests) {
        if (digest.body.isEmpty) continue;
        final scheduledAt = tz.TZDateTime(
          tz.local,
          digest.day.year,
          digest.day.month,
          digest.day.day,
          _digestHour,
        );
        if (!scheduledAt.isAfter(tz.TZDateTime.now(tz.local))) continue;
        await _plugin.zonedSchedule(
          digest.id,
          digest.title,
          digest.body,
          scheduledAt,
          const NotificationDetails(android: _channel),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    } catch (e) {
      debugPrint('Failed to schedule reminder notifications: $e');
    }
  }

  Future<List<_DailyDigest>> _buildDailyDigests() async {
    final customers = await CustomerRepository().getCustomers();
    final contracts = await OperationsRepository().getContracts();
    final inventory = await InventoryRepository().getInventory();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final serviceDueByDay = <DateTime, int>{};
    for (final customer in customers) {
      final due = _parseFlexibleDate(customer.upcomingServiceDate ?? '');
      if (due == null) continue;
      var dueDay = DateTime(due.year, due.month, due.day);
      if (dueDay.isBefore(today)) dueDay = today; // overdue → surface today
      serviceDueByDay.update(dueDay, (count) => count + 1, ifAbsent: () => 1);
    }

    final renewalsByDay = <DateTime, int>{};
    for (final contract in contracts) {
      if (contract.status.toLowerCase() != 'active') continue;
      final reminder = DateTime.tryParse(contract.renewalReminderDate);
      if (reminder == null) continue;
      var reminderDay = DateTime(reminder.year, reminder.month, reminder.day);
      if (reminderDay.isBefore(today)) reminderDay = today;
      renewalsByDay.update(
        reminderDay,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }

    final lowStockCount = inventory
        .where((item) => item.stock <= item.lowStockThreshold)
        .length;

    final digests = <_DailyDigest>[];
    for (var offset = 0; offset < _daysAhead; offset++) {
      final day = today.add(Duration(days: offset));
      final parts = <String>[
        if ((serviceDueByDay[day] ?? 0) > 0)
          '${serviceDueByDay[day]} service visit(s) due',
        if ((renewalsByDay[day] ?? 0) > 0)
          '${renewalsByDay[day]} AMC renewal(s) to follow up',
        if (offset == 0 && lowStockCount > 0)
          '$lowStockCount item(s) low on stock',
      ];
      digests.add(
        _DailyDigest(
          id: offset,
          day: day,
          title: 'RO Manager — today\'s reminders',
          body: parts.join(' • '),
        ),
      );
    }
    return digests;
  }

  DateTime? _parseFlexibleDate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == 'N/A' || trimmed == 'Never') return null;

    final iso = DateTime.tryParse(trimmed);
    if (iso != null) return iso;

    const months = {
      'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
      'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
    };
    final shortDate =
        RegExp(r'^(\d{2}) ([A-Za-z]{3}) (\d{4})$').firstMatch(trimmed);
    if (shortDate != null) {
      return DateTime(
        int.parse(shortDate.group(3)!),
        months[shortDate.group(2)!]!,
        int.parse(shortDate.group(1)!),
      );
    }
    final commaDate =
        RegExp(r'^([A-Za-z]{3}) (\d{1,2}), (\d{4})$').firstMatch(trimmed);
    if (commaDate != null) {
      return DateTime(
        int.parse(commaDate.group(3)!),
        months[commaDate.group(1)!]!,
        int.parse(commaDate.group(2)!),
      );
    }
    return null;
  }
}

class _DailyDigest {
  final int id;
  final DateTime day;
  final String title;
  final String body;

  const _DailyDigest({
    required this.id,
    required this.day,
    required this.title,
    required this.body,
  });
}
