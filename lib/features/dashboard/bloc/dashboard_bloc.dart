import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../customer/repositories/customer_repository.dart';
import '../../dispatch/repositories/dispatch_repository.dart';
import '../../inventory/repositories/inventory_repository.dart';
import '../../../core/database/database_helper.dart';

// --- Events ---
abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

class DashboardDataRequested extends DashboardEvent {}

class DashboardDataClearRequested extends DashboardEvent {}

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
  final List<dynamic> scheduledServices;

  const DashboardLoaded(
    this.stats,
    this.activities,
    this.scheduledServices,
  );

  @override
  List<Object?> get props => [stats, activities, scheduledServices];
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
    on<DashboardDataClearRequested>(_onDataClearRequested);
  }

  void _onDataRequested(
    DashboardDataRequested event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());

    try {
      final customerRepo = CustomerRepository();
      final inventoryRepo = InventoryRepository();
      final dispatchRepo = DispatchRepository();

      final customers = await customerRepo.getCustomers();
      final inventoryItems = await inventoryRepo.getInventory();
      final requests = await dispatchRepo.getServiceRequests();

      final totalCustomers = customers.length;
      final totalInventory = inventoryItems.fold<int>(
        0,
        (sum, item) => sum + item.stock,
      );
      final lowStock = inventoryItems
          .where((item) => item.stock <= item.lowStockThreshold)
          .length;
      final pendingService = requests
          .where((req) => req.status == 'Pending')
          .length;

      final stats = {
        'totalInventory': totalInventory.toString(),
        'pendingService': pendingService.toString(),
        'totalCustomers': totalCustomers.toString(),
        'lowStock': lowStock.toString(),
      };

      var activities = requests
          .take(3)
          .map(
            (req) => {
              'id': req.id.hashCode,
              'title': '${req.type} Request',
              'desc': req.customerName,
              'time': req.time,
              'color': req.status == 'Completed' ? 'green' : 'orange',
            },
          )
          .toList();

      if (activities.isEmpty) {
        activities = [
          {
            'id': 1,
            'title': 'System Started',
            'desc': 'No recent activity yet.',
            'time': 'Just now',
            'color': 'blue',
          },
        ];
      }

      // Sort requests by time assuming time string is comparable like 'HH:MM' or 'YYYY-MM-DD'
      // Taking top 5
      final scheduledServices = List<Map<String, dynamic>>.from(
        requests.map((req) => {
          'id': req.id,
          'title': '${req.type} Request - ${req.address}',
          'customerName': req.customerName,
          'time': req.time,
          'status': req.status,
          'type': req.type,
          'model': req.model,
        })
      );
      
      // Basic string sort by time (you might need proper DateTime parsing if formats vary)
      scheduledServices.sort((a, b) => (a['time'] as String).compareTo(b['time'] as String));

      emit(DashboardLoaded(stats, activities, scheduledServices));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }

  void _onDataClearRequested(
    DashboardDataClearRequested event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    try {
      await DatabaseHelper.instance.clearAllData();
      add(DashboardDataRequested());
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }
}
