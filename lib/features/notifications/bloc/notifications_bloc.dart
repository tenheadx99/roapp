import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../customer/repositories/customer_repository.dart';
import '../../dispatch/repositories/dispatch_repository.dart';
import '../../inventory/repositories/inventory_repository.dart';

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

  NotificationsBloc({
    InventoryRepository? inventoryRepository,
    DispatchRepository? dispatchRepository,
    CustomerRepository? customerRepository,
  }) : inventoryRepository = inventoryRepository ?? InventoryRepository(),
       dispatchRepository = dispatchRepository ?? DispatchRepository(),
       customerRepository = customerRepository ?? CustomerRepository(),
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
      final inventory = await inventoryRepository.getInventory();
      final requests = await dispatchRepository.getServiceRequests();
      final customers = await customerRepository.getCustomers();

      final notifications = <Map<String, dynamic>>[];

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

      final unassignedDueCustomers = customers
          .where((customer) => customer.status == 'Service Due')
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
