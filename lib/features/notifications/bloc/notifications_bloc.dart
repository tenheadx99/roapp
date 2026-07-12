import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../customer/models/customer.dart';
import '../../customer/repositories/customer_repository.dart';
import '../../dispatch/repositories/dispatch_repository.dart';
import '../../inventory/repositories/inventory_repository.dart';
import '../../operations/repositories/operations_repository.dart';
import '../../settings/repositories/settings_repository.dart';

// --- Events ---
abstract class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object?> get props => [];
}

class LoadNotifications extends NotificationsEvent {}

class FilterNotifications extends NotificationsEvent {
  final String category; // 'All', 'Inventory', 'Service'

  const FilterNotifications(this.category);

  @override
  List<Object?> get props => [category];
}

class MarkNotificationRead extends NotificationsEvent {
  final String id;

  const MarkNotificationRead(this.id);

  @override
  List<Object?> get props => [id];
}

// --- States ---
abstract class NotificationsState extends Equatable {
  const NotificationsState();

  @override
  List<Object?> get props => [];
}

class NotificationsInitial extends NotificationsState {}

class NotificationsLoading extends NotificationsState {}

class NotificationsLoaded extends NotificationsState {
  final List<Map<String, dynamic>> allNotifications;
  final List<Map<String, dynamic>> filteredNotifications;
  final String activeCategory;

  const NotificationsLoaded({
    required this.allNotifications,
    required this.filteredNotifications,
    this.activeCategory = 'All',
  });

  @override
  List<Object?> get props => [
    allNotifications,
    filteredNotifications,
    activeCategory,
  ];

  NotificationsLoaded copyWith({
    List<Map<String, dynamic>>? allNotifications,
    List<Map<String, dynamic>>? filteredNotifications,
    String? activeCategory,
  }) {
    return NotificationsLoaded(
      allNotifications: allNotifications ?? this.allNotifications,
      filteredNotifications:
          filteredNotifications ?? this.filteredNotifications,
      activeCategory: activeCategory ?? this.activeCategory,
    );
  }
}

class NotificationsError extends NotificationsState {
  final String message;

  const NotificationsError(this.message);

  @override
  List<Object?> get props => [message];
}

// --- Bloc ---
class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final InventoryRepository inventoryRepository;
  final DispatchRepository dispatchRepository;
  final CustomerRepository customerRepository;
  final SettingsRepository settingsRepository;
  final OperationsRepository operationsRepository;
  final DateTime Function() nowProvider;

  NotificationsBloc({
    InventoryRepository? inventoryRepository,
    DispatchRepository? dispatchRepository,
    CustomerRepository? customerRepository,
    SettingsRepository? settingsRepository,
    OperationsRepository? operationsRepository,
    DateTime Function()? nowProvider,
  }) : inventoryRepository = inventoryRepository ?? InventoryRepository(),
       dispatchRepository = dispatchRepository ?? DispatchRepository(),
       customerRepository = customerRepository ?? CustomerRepository(),
       settingsRepository = settingsRepository ?? SettingsRepository(),
       operationsRepository = operationsRepository ?? OperationsRepository(),
       nowProvider = nowProvider ?? DateTime.now,
       super(NotificationsInitial()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<FilterNotifications>(_onFilterNotifications);
    on<MarkNotificationRead>(_onMarkRead);
  }

  void _onLoadNotifications(
    LoadNotifications event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(NotificationsLoading());
    try {
      final settings = await settingsRepository.loadSettings();
      if (!settings.notificationsEnabled) {
        emit(
          const NotificationsLoaded(
            allNotifications: [
              {
                'id': 'notifications-disabled',
                'type': 'normal',
                'category': 'Service',
                'title': 'Notifications Paused',
                'time': 'Now',
                'content':
                    'Service alerts are currently turned off from your profile preferences.',
                'isRead': true,
                'icon': 'alert',
                'actionLabel': 'Open Dashboard',
                'actionRoute': 'dashboard',
              },
            ],
            filteredNotifications: [
              {
                'id': 'notifications-disabled',
                'type': 'normal',
                'category': 'Service',
                'title': 'Notifications Paused',
                'time': 'Now',
                'content':
                    'Service alerts are currently turned off from your profile preferences.',
                'isRead': true,
                'icon': 'alert',
                'actionLabel': 'Open Dashboard',
                'actionRoute': 'dashboard',
              },
            ],
          ),
        );
        return;
      }

      final inventory = await inventoryRepository.getInventory();
      final requests = await dispatchRepository.getServiceRequests();
      final customers = await customerRepository.getCustomers();

      final notifications = <Map<String, dynamic>>[];
      final now = nowProvider();

      final lowStockItems = inventory
          .where((item) => item.stock <= item.lowStockThreshold)
          .take(3);
      for (final item in lowStockItems) {
        notifications.add({
          'id': 'inventory-${item.id}',
          'type': 'urgent',
          'category': 'Inventory',
          'title': 'Critical: Low Stock',
          'time': 'Now',
          'content':
              '${item.name} is at ${item.stock} units, below the threshold of ${item.lowStockThreshold}.',
          'isRead': false,
          'icon': 'package',
          'actionLabel': 'Open Inventory',
          'actionRoute': 'inventory',
        });
      }

      final contracts = await operationsRepository.getContracts();
      final customerById = {
        for (final customer in customers) customer.id: customer,
      };
      final renewalDueContracts = contracts.where(
        (contract) =>
            contract.status.toLowerCase() == 'active' && contract.isRenewalDue,
      );
      for (final contract in renewalDueContracts) {
        final customer = customerById[contract.customerId];
        final endDate = DateTime.tryParse(contract.endDate);
        notifications.add({
          'id': 'amc-renewal-${contract.id}',
          'type': 'urgent',
          'category': 'Service',
          'title': 'AMC Renewal Due',
          'time': endDate == null ? 'Soon' : _formatDate(endDate),
          'content':
              '${customer?.name ?? 'A customer'}\'s "${contract.contractName}" ends '
              '${endDate == null ? 'soon' : 'on ${_formatDate(endDate)}'}. Reach out to renew.',
          'isRead': false,
          'icon': 'alert',
          'actionLabel': 'Open Operations',
          'actionRoute': 'operations',
        });
      }

      final customersWithReminder = <String>{};
      for (final customer in customers) {
        final reminder = _buildServiceReminderNotification(customer, now);
        if (reminder == null) continue;

        notifications.add(reminder);
        customersWithReminder.add(customer.id);
      }

      final unassignedDueCustomers = customers
          .where(
            (customer) =>
                customer.status == 'Service Due' &&
                !customersWithReminder.contains(customer.id),
          )
          .take(3);
      for (final customer in unassignedDueCustomers) {
        notifications.add({
          'id': 'customer-${customer.id}',
          'type': 'urgent',
          'category': 'Service',
          'title': 'Service Follow-up Needed',
          'time': customer.upcomingServiceDate ?? customer.lastService,
          'content':
              '${customer.name} in ${customer.area} is marked as Service Due. Schedule a visit soon.',
          'isRead': false,
          'icon': 'alert',
          'actionLabel': 'Open Dispatch',
          'actionRoute': 'dispatch',
        });
      }

      for (final request in requests.where((req) => req.status == 'new')) {
        notifications.add({
          'id': 'request-${request.id}',
          'type': 'normal',
          'category': 'Service',
          'title': 'New Service Request',
          'time': request.time,
          'content': '${request.customerName} requested ${request.type}.',
          'isRead': false,
          'icon': 'wrench',
          'actionLabel': 'Review Request',
          'actionRoute': 'dispatch',
        });
      }

      for (final request in requests.where((req) => req.status == 'assigned')) {
        notifications.add({
          'id': 'assigned-${request.id}',
          'type': 'normal',
          'category': 'Service',
          'title': 'Technician Assigned',
          'time': request.time,
          'content':
              '${request.technicianName ?? 'A technician'} has been assigned to ${request.customerName}.',
          'isRead': false,
          'icon': 'wrench',
          'actionLabel': 'Open Dispatch',
          'actionRoute': 'dispatch',
        });
      }

      if (notifications.isEmpty) {
        notifications.add({
          'id': 'empty-state',
          'type': 'normal',
          'category': 'Service',
          'title': 'Everything Looks Good',
          'time': 'Now',
          'content':
              'No urgent inventory or service issues were found in the local database.',
          'isRead': true,
          'icon': 'truck',
          'actionLabel': 'Open Dashboard',
          'actionRoute': 'dashboard',
        });
      }

      emit(
        NotificationsLoaded(
          allNotifications: notifications,
          filteredNotifications: notifications,
        ),
      );
    } catch (e) {
      emit(NotificationsError(e.toString()));
    }
  }

  Map<String, dynamic>? _buildServiceReminderNotification(
    Customer customer,
    DateTime now,
  ) {
    final lastServiceDate = _parseFlexibleDate(customer.lastService);
    if (lastServiceDate == null) {
      return null;
    }

    final today = _stripTime(now);
    final threeMonthDueDate = _stripTime(
      lastServiceDate.add(const Duration(days: 90)),
    );
    final sixMonthDueDate = _stripTime(
      lastServiceDate.add(const Duration(days: 180)),
    );

    if (!today.isBefore(sixMonthDueDate)) {
      return {
        'id': 'service-reminder-6-${customer.id}',
        'type': 'urgent',
        'category': 'Service',
        'title': '6-Month Service Reminder',
        'time': _formatDate(sixMonthDueDate),
        'content':
            '${customer.name} in ${customer.area} is due for a 6-month service follow-up. Last service was on ${customer.lastService}.',
        'isRead': false,
        'icon': 'alert',
        'actionLabel': 'Open Dispatch',
        'actionRoute': 'dispatch',
      };
    }

    if (!today.isBefore(threeMonthDueDate)) {
      return {
        'id': 'service-reminder-3-${customer.id}',
        'type': 'normal',
        'category': 'Service',
        'title': '3-Month Service Reminder',
        'time': _formatDate(threeMonthDueDate),
        'content':
            '${customer.name} in ${customer.area} is due for the routine 3-month service follow-up. Last service was on ${customer.lastService}.',
        'isRead': false,
        'icon': 'alert',
        'actionLabel': 'Open Dispatch',
        'actionRoute': 'dispatch',
      };
    }

    return null;
  }

  DateTime _stripTime(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  String _formatDate(DateTime value) {
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final day = value.day.toString().padLeft(2, '0');
    final month = monthNames[value.month - 1];
    return '$day $month ${value.year}';
  }

  DateTime? _parseFlexibleDate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == 'N/A' || trimmed == 'Never') {
      return null;
    }

    final iso = DateTime.tryParse(trimmed);
    if (iso != null) return iso;

    const months = {
      'Jan': 1,
      'Feb': 2,
      'Mar': 3,
      'Apr': 4,
      'May': 5,
      'Jun': 6,
      'Jul': 7,
      'Aug': 8,
      'Sep': 9,
      'Oct': 10,
      'Nov': 11,
      'Dec': 12,
    };

    final shortDate = RegExp(
      r'^(\d{2}) ([A-Za-z]{3}) (\d{4})$',
    ).firstMatch(trimmed);
    if (shortDate != null) {
      return DateTime(
        int.parse(shortDate.group(3)!),
        months[shortDate.group(2)!]!,
        int.parse(shortDate.group(1)!),
      );
    }

    final commaDate = RegExp(
      r'^([A-Za-z]{3}) (\d{1,2}), (\d{4})$',
    ).firstMatch(trimmed);
    if (commaDate != null) {
      return DateTime(
        int.parse(commaDate.group(3)!),
        months[commaDate.group(1)!]!,
        int.parse(commaDate.group(2)!),
      );
    }

    return null;
  }

  void _onFilterNotifications(
    FilterNotifications event,
    Emitter<NotificationsState> emit,
  ) {
    if (state is NotificationsLoaded) {
      final currentState = state as NotificationsLoaded;
      final filtered = _filterByCategory(
        currentState.allNotifications,
        event.category,
      );

      emit(
        currentState.copyWith(
          filteredNotifications: filtered,
          activeCategory: event.category,
        ),
      );
    }
  }

  void _onMarkRead(
    MarkNotificationRead event,
    Emitter<NotificationsState> emit,
  ) {
    if (state is NotificationsLoaded) {
      final currentState = state as NotificationsLoaded;

      final updatedAll = currentState.allNotifications.map((n) {
        if (n['id'] == event.id) {
          final newMap = Map<String, dynamic>.from(n);
          newMap['isRead'] = true;
          return newMap;
        }
        return n;
      }).toList();

      final filtered = _filterByCategory(
        updatedAll,
        currentState.activeCategory,
      );

      emit(
        currentState.copyWith(
          allNotifications: updatedAll,
          filteredNotifications: filtered,
        ),
      );
    }
  }

  List<Map<String, dynamic>> _filterByCategory(
    List<Map<String, dynamic>> notifications,
    String category,
  ) {
    if (category == 'All') return notifications;
    return notifications.where((n) => n['category'] == category).toList();
  }
}
