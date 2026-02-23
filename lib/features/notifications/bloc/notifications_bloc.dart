import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
  NotificationsBloc() : super(NotificationsInitial()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<FilterNotifications>(_onFilterNotifications);
    on<MarkNotificationRead>(_onMarkRead);
  }

  void _onLoadNotifications(
    LoadNotifications event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(NotificationsLoading());
    await Future.delayed(const Duration(milliseconds: 500));

    final notifications = [
      {
        'id': '1',
        'type': 'urgent',
        'category': 'Inventory',
        'title': 'Critical: Low Stock',
        'time': '2m ago',
        'content':
            'RO Filter Membrane stock is below 10 units. Reorder required immediately to avoid service delays.',
        'isRead': false,
        'icon': 'package',
      },
      {
        'id': '2',
        'type': 'urgent',
        'category': 'Service',
        'title': 'Overdue Maintenance',
        'time': '1h ago',
        'content':
            'AMC for Mr. Sharma (ID: #4402) was due yesterday. No technician assigned yet.',
        'isRead': false,
        'icon': 'alert',
      },
      {
        'id': '3',
        'type': 'normal',
        'category': 'Service',
        'title': 'New Service Request',
        'time': '3h ago',
        'content': 'Customer requested a TDS check at Sector 45, Green Villa.',
        'isRead': false,
        'icon': 'wrench',
      },
      {
        'id': '4',
        'type': 'normal',
        'category': 'Inventory',
        'title': 'Stock Delivered',
        'time': '5h ago',
        'content':
            'Consignment #INV-9021 (Sediment Filters) has been received at Main Hub.',
        'isRead': true,
        'icon': 'truck',
      },
    ];

    emit(
      NotificationsLoaded(
        allNotifications: notifications,
        filteredNotifications: notifications,
      ),
    );
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
