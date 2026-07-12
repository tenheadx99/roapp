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

  const DashboardLoaded(this.stats, this.activities, this.scheduledServices);

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
  final CustomerRepository customerRepo;
  final InventoryRepository inventoryRepo;
  final DispatchRepository dispatchRepo;

  DashboardBloc({
    CustomerRepository? customerRepository,
    InventoryRepository? inventoryRepository,
    DispatchRepository? dispatchRepository,
  })  : customerRepo = customerRepository ?? CustomerRepository(),
        inventoryRepo = inventoryRepository ?? InventoryRepository(),
        dispatchRepo = dispatchRepository ?? DispatchRepository(),
        super(DashboardInitial()) {
    on<DashboardDataRequested>(_onDataRequested);
    on<DashboardDataClearRequested>(_onDataClearRequested);
  }

  void _onDataRequested(
    DashboardDataRequested event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());

    try {
      final requests = await dispatchRepo.getServiceRequests();
      final customers = await customerRepo.getCustomers();
      final serviceHistory = await customerRepo.getAllServiceHistory();
      final inventoryItems = await inventoryRepo.getInventory();

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
      final healthyItems = inventoryItems
          .where((item) => item.stock > item.lowStockThreshold)
          .length;
      final underwayJobs = requests
          .where(
            (req) => req.status == 'assigned' || req.status == 'in_progress',
          )
          .length;
      final dueThisMonth = customers.where((customer) {
        final upcoming = _parseCustomerDate(customer.upcomingServiceDate);
        if (upcoming == null) return false;
        final now = DateTime.now();
        final monthStart = DateTime(now.year, now.month, 1);
        final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        return !upcoming.isBefore(monthStart) && !upcoming.isAfter(monthEnd);
      }).length;
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      final fourteenDaysAgo = now.subtract(const Duration(days: 14));
      final completedThisWeek = serviceHistory.where((entry) {
        final parsed = _parseFlexibleDate(entry.date);
        return parsed != null && parsed.isAfter(sevenDaysAgo);
      }).length;
      final completedLastWeek = serviceHistory.where((entry) {
        final parsed = _parseFlexibleDate(entry.date);
        return parsed != null &&
            parsed.isAfter(fourteenDaysAgo) &&
            !parsed.isAfter(sevenDaysAgo);
      }).length;

      final stats = {
        'totalInventory': totalInventory.toString(),
        'pendingService': pendingService.toString(),
        'totalCustomers': totalCustomers.toString(),
        'lowStock': lowStock.toString(),
        'totalInventoryBadge': '$healthyItems healthy items',
        'totalInventoryBadgeTone': healthyItems >= lowStock
            ? 'positive'
            : 'neutral',
        'pendingServiceBadge': _buildDeltaBadge(
          completedThisWeek,
          completedLastWeek,
          suffix: 'vs last week',
        ),
        'pendingServiceBadgeTone': completedThisWeek >= completedLastWeek
            ? 'positive'
            : 'negative',
        'totalCustomersBadge': '$dueThisMonth due this month',
        'totalCustomersBadgeTone': dueThisMonth > 0 ? 'neutral' : 'positive',
        'lowStockBadge': lowStock == 0 ? 'All stocked' : '$lowStock attention',
        'lowStockBadgeTone': lowStock == 0 ? 'positive' : 'negative',
        'underwayJobs': underwayJobs.toString(),
      };

      var activities = requests.toList()
        ..sort(
          (a, b) => _sortScheduleValue(b).compareTo(_sortScheduleValue(a)),
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
          DashboardLoaded(stats, const [
            {
              'id': 1,
              'title': 'System Started',
              'desc': 'No recent activity yet.',
              'time': 'Just now',
              'color': 'blue',
            },
          ], const []),
        );
        return;
      }

      final scheduledServices = List<Map<String, dynamic>>.from(
        requests.map(
          (req) => {
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
          },
        ),
      );

      scheduledServices.sort(
        (a, b) => _sortScheduleMap(a).compareTo(_sortScheduleMap(b)),
      );

      emit(DashboardLoaded(stats, activityCards, scheduledServices));
    } catch (e, stackTrace) {
      addError(e, stackTrace);
      emit(
        const DashboardError(
          'Could not load the dashboard. Pull down to retry.',
        ),
      );
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

  DateTime? _parseCustomerDate(String? value) {
    if ((value ?? '').trim().isEmpty) return null;
    return _parseFlexibleDate(value!);
  }

  DateTime? _parseFlexibleDate(String value) {
    final iso = DateTime.tryParse(value);
    if (iso != null) return iso;

    final months = {
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

    final dateAndTime = value.split('•');
    final datePart = dateAndTime.first.trim();
    final timePart = dateAndTime.length > 1 ? dateAndTime.last.trim() : null;

    final commaDate = RegExp(
      r'^([A-Za-z]{3}) (\d{1,2}), (\d{4})$',
    ).firstMatch(datePart);
    if (commaDate != null) {
      final month = months[commaDate.group(1)!];
      final day = int.parse(commaDate.group(2)!);
      final year = int.parse(commaDate.group(3)!);
      final time = _parseTime(timePart);
      return DateTime(year, month!, day, time?.hour ?? 0, time?.minute ?? 0);
    }

    final shortDate = RegExp(
      r'^(\d{2}) ([A-Za-z]{3}) (\d{4})$',
    ).firstMatch(datePart);
    if (shortDate != null) {
      return DateTime(
        int.parse(shortDate.group(3)!),
        months[shortDate.group(2)!]!,
        int.parse(shortDate.group(1)!),
      );
    }

    return null;
  }

  ({int hour, int minute})? _parseTime(String? value) {
    if ((value ?? '').trim().isEmpty) return null;
    final match = RegExp(
      r'^(\d{1,2}):(\d{2}) (AM|PM)$',
    ).firstMatch(value!.trim());
    if (match == null) return null;
    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final meridiem = match.group(3)!;
    if (meridiem == 'PM' && hour != 12) {
      hour += 12;
    } else if (meridiem == 'AM' && hour == 12) {
      hour = 0;
    }
    return (hour: hour, minute: minute);
  }

  String _buildDeltaBadge(int current, int previous, {required String suffix}) {
    if (current == previous) {
      return 'No change';
    }
    final delta = current - previous;
    return '${delta > 0 ? '+' : ''}$delta $suffix';
  }

  void _onDataClearRequested(
    DashboardDataClearRequested event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    try {
      await DatabaseHelper.instance.clearAllData();
      add(DashboardDataRequested());
    } catch (e, stackTrace) {
      addError(e, stackTrace);
      emit(const DashboardError('Could not clear the data. Try again.'));
    }
  }
}
