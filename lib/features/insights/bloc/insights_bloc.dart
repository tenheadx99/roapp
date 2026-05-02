import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../customer/repositories/customer_repository.dart';
import '../../dispatch/repositories/dispatch_repository.dart';
import '../../inventory/repositories/inventory_repository.dart';
import '../../technician/repositories/technician_repository.dart';

// --- Events ---
abstract class InsightsEvent extends Equatable {
  const InsightsEvent();

  @override
  List<Object?> get props => [];
}

class LoadInsightsData extends InsightsEvent {}

class ChangeTimeRange extends InsightsEvent {
  final String range; // 'Today', 'This Week', 'This Month', 'Custom'

  const ChangeTimeRange(this.range);

  @override
  List<Object?> get props => [range];
}

// --- States ---
abstract class InsightsState extends Equatable {
  const InsightsState();

  @override
  List<Object?> get props => [];
}

class InsightsInitial extends InsightsState {}

class InsightsLoading extends InsightsState {}

class InsightsLoaded extends InsightsState {
  final String activeTimeRange;

  // Dummy data just for state, UI will render directly based on state
  final double revenue;
  final double avgTat;
  final Map<String, double> salesTrends;
  final List<Map<String, dynamic>> serviceLoad;
  final List<Map<String, dynamic>> inventoryUsage;

  const InsightsLoaded({
    required this.activeTimeRange,
    required this.revenue,
    required this.avgTat,
    required this.salesTrends,
    required this.serviceLoad,
    required this.inventoryUsage,
  });

  @override
  List<Object?> get props => [
    activeTimeRange,
    revenue,
    avgTat,
    salesTrends,
    serviceLoad,
    inventoryUsage,
  ];

  InsightsLoaded copyWith({
    String? activeTimeRange,
    double? revenue,
    double? avgTat,
    Map<String, double>? salesTrends,
    List<Map<String, dynamic>>? serviceLoad,
    List<Map<String, dynamic>>? inventoryUsage,
  }) {
    return InsightsLoaded(
      activeTimeRange: activeTimeRange ?? this.activeTimeRange,
      revenue: revenue ?? this.revenue,
      avgTat: avgTat ?? this.avgTat,
      salesTrends: salesTrends ?? this.salesTrends,
      serviceLoad: serviceLoad ?? this.serviceLoad,
      inventoryUsage: inventoryUsage ?? this.inventoryUsage,
    );
  }
}

class InsightsError extends InsightsState {
  final String message;

  const InsightsError(this.message);

  @override
  List<Object?> get props => [message];
}

// --- Bloc ---
class InsightsBloc extends Bloc<InsightsEvent, InsightsState> {
  InsightsBloc() : super(InsightsInitial()) {
    on<LoadInsightsData>(_onLoadData);
    on<ChangeTimeRange>(_onChangeTimeRange);
  }

  void _onLoadData(LoadInsightsData event, Emitter<InsightsState> emit) async {
    emit(InsightsLoading());
    try {
      final techRepo = TechnicianRepository();
      final invRepo = InventoryRepository();
      final customerRepo = CustomerRepository();
      final dispatchRepo = DispatchRepository();

      final technicians = await techRepo.getTechnicians();
      final inventory = await invRepo.getInventory();
      final serviceHistory = await customerRepo.getAllServiceHistory();
      final requests = await dispatchRepo.getServiceRequests();

      var serviceLoad = technicians.map((t) {
        return {'name': t.name, 'tasks': t.tasksToday, 'color': '#007fff'};
      }).toList();

      if (serviceLoad.isEmpty) {
        serviceLoad = [
          {'name': 'No Technicians', 'tasks': 0, 'color': '#007fff'},
        ];
      }

      final Map<String, double> categoryStock = {};
      int totalStock = 0;
      for (var item in inventory) {
        categoryStock[item.category] =
            (categoryStock[item.category] ?? 0) + item.stock;
        totalStock += item.stock;
      }

      var inventoryUsage = categoryStock.entries.map((e) {
        return {
          'name': e.key,
          'value': totalStock > 0 ? (e.value / totalStock) * 100 : 0.0,
          'color': '#007fff',
        };
      }).toList();

      if (inventoryUsage.isEmpty) {
        inventoryUsage = [
          {'name': 'No Elements', 'value': 100.0, 'color': '#f1f5f9'},
        ];
      }

      final revenue = serviceHistory.fold<double>(
        0,
        (sum, entry) => sum + entry.cost,
      );
      final openRequests = requests
          .where((request) => request.status != 'completed')
          .length;
      final avgTat = technicians.isEmpty
          ? 0.0
          : ((openRequests / technicians.length) * 1.8 + 1.2);

      final salesTrends = <String, double>{
        'Mon': 0,
        'Tue': 0,
        'Wed': 0,
        'Thu': 0,
        'Fri': 0,
        'Sat': 0,
        'Sun': 0,
      };

      for (final entry in serviceHistory) {
        final date = _parseHistoryDate(entry.date);
        if (date == null) continue;
        const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final label = labels[date.weekday - 1];
        salesTrends[label] = (salesTrends[label] ?? 0) + entry.cost;
      }

      emit(
        InsightsLoaded(
          activeTimeRange: 'Today',
          revenue: revenue,
          avgTat: double.parse(avgTat.toStringAsFixed(1)),
          salesTrends: salesTrends,
          serviceLoad: serviceLoad,
          inventoryUsage: inventoryUsage,
        ),
      );
    } catch (e) {
      emit(InsightsError(e.toString()));
    }
  }

  void _onChangeTimeRange(ChangeTimeRange event, Emitter<InsightsState> emit) {
    if (state is InsightsLoaded) {
      final currentState = state as InsightsLoaded;

      // In a real app, this would recalculate or fetch new data based on the range.
      // Here we just update the active range text.
      emit(currentState.copyWith(activeTimeRange: event.range));
    }
  }

  DateTime? _parseHistoryDate(String value) {
    final parts = value.split('•').first.trim();
    final commaParts = parts.split(',');
    if (commaParts.length < 2) return null;

    final left = commaParts.first.trim().split(' ');
    final year = int.tryParse(commaParts.last.trim());
    if (left.length < 2 || year == null) return null;

    final month = _monthNumber(left.first);
    final day = int.tryParse(left[1]);
    if (month == null || day == null) return null;

    return DateTime(year, month, day);
  }

  int? _monthNumber(String value) {
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
    return months[value];
  }
}
