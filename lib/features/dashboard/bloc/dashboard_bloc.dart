import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// --- Events ---
abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

class DashboardDataRequested extends DashboardEvent {}

// --- States ---
abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  // In a real app these would be typed data structures
  final Map<String, dynamic> stats;
  final List<dynamic> activities;

  const DashboardLoaded(this.stats, this.activities);

  @override
  List<Object?> get props => [stats, activities];
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError(this.message);

  @override
  List<Object?> get props => [message];
}

// --- Bloc ---
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc() : super(DashboardInitial()) {
    on<DashboardDataRequested>(_onDataRequested);
  }

  void _onDataRequested(
    DashboardDataRequested event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    // Dummy data matching React DashboardScreen
    final stats = {
      'totalInventory': '142',
      'pendingService': '12',
      'totalCustomers': '850',
      'lowStock': '3',
    };

    final activities = [
      {
        'id': 1,
        'title': 'Service Completed',
        'desc': 'RO Maintenance: John Doe',
        'time': '2 mins ago',
        'color': 'green',
      },
      {
        'id': 2,
        'title': 'New Customer',
        'desc': 'Riverside Apt • Block B-402',
        'time': '1 hour ago',
        'color': 'blue',
      },
      {
        'id': 3,
        'title': 'Maintenance Scheduled',
        'desc': 'Filter Change: Sarah Smith',
        'time': '3 hours ago',
        'color': 'orange',
      },
    ];

    emit(DashboardLoaded(stats, activities));
  }
}
