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
          .where((req) => req.status != 'completed')
          .length;

      final stats = {
        'totalInventory': totalInventory.toString(),
        'pendingService': pendingService.toString(),
        'totalCustomers': totalCustomers.toString(),
        'lowStock': lowStock.toString(),
      };

      var activities = requests
          .toList()
          ..sort(
            (a, b) => _sortScheduleValue(a).compareTo(_sortScheduleValue(b)),
          );

      final activityCards = activities
          .take(3)
          .map(
            (req) => {
              'id': req.id.hashCode,
              'title': '${req.type} Request',
              'desc': req.technicianName != null
                  ? '${req.customerName} • ${req.technicianName}'
                  : req.customerName,
              'time': req.time,
              'color': req.status == 'completed'
                  ? 'green'
                  : (req.status == 'assigned' ? 'blue' : 'orange'),
            },
          )
          .toList();

      if (activityCards.isEmpty) {
        emit(
          DashboardLoaded(
            stats,
            const [
              {
                'id': 1,
                'title': 'System Started',
                'desc': 'No recent activity yet.',
                'time': 'Just now',
                'color': 'blue',
              },
            ],
            const [],
          ),
        );
        return;
      }

      final scheduledServices = List<Map<String, dynamic>>.from(
        requests.map((req) => {
          'id': req.id,
          'title': '${req.type} Request - ${req.address}',
          'customerName': req.customerName,
          'time': req.time,
          'status': req.status,
          'type': req.type,
          'model': req.model,
          'technicianName': req.technicianName,
          'notes': req.notes,
          'scheduledFor': req.scheduledFor,
        }),
      );

      scheduledServices.sort(
        (a, b) => _sortScheduleMap(a).compareTo(_sortScheduleMap(b)),
      );

      emit(DashboardLoaded(stats, activityCards, scheduledServices));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }

  int _sortScheduleValue(dynamic request) {
    final parsed = DateTime.tryParse(request.scheduledFor ?? '');
    return parsed?.millisecondsSinceEpoch ?? 0;
  }

  int _sortScheduleMap(Map<String, dynamic> service) {
    final parsed = DateTime.tryParse(service['scheduledFor'] as String? ?? '');
    return parsed?.millisecondsSinceEpoch ?? 0;
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
