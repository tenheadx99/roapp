import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../customer/repositories/customer_repository.dart';
import '../../dispatch/repositories/dispatch_repository.dart';
import '../../inventory/repositories/inventory_repository.dart';
import '../../operations/repositories/operations_repository.dart';
import '../../supplier/repositories/supplier_repository.dart';
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
  final double revenue;
  final double avgTat;
  final Map<String, double> salesTrends;
  final List<Map<String, dynamic>> serviceLoad;
  final List<Map<String, dynamic>> inventoryUsage;
  final List<Map<String, dynamic>> revenueByTechnician;
  final List<Map<String, dynamic>> topParts;
  final List<Map<String, dynamic>> repeatCustomers;
  final List<Map<String, dynamic>> supplierPerformance;
  final Map<String, int> monthlyServiceVolume;
  final int slaBreaches;

  const InsightsLoaded({
    required this.activeTimeRange,
    required this.revenue,
    required this.avgTat,
    required this.salesTrends,
    required this.serviceLoad,
    required this.inventoryUsage,
    required this.revenueByTechnician,
    required this.topParts,
    required this.repeatCustomers,
    required this.supplierPerformance,
    required this.monthlyServiceVolume,
    required this.slaBreaches,
  });

  @override
  List<Object?> get props => [
    activeTimeRange,
    revenue,
    avgTat,
    salesTrends,
    serviceLoad,
    inventoryUsage,
    revenueByTechnician,
    topParts,
    repeatCustomers,
    supplierPerformance,
    monthlyServiceVolume,
    slaBreaches,
  ];

  InsightsLoaded copyWith({
    String? activeTimeRange,
    double? revenue,
    double? avgTat,
    Map<String, double>? salesTrends,
    List<Map<String, dynamic>>? serviceLoad,
    List<Map<String, dynamic>>? inventoryUsage,
    List<Map<String, dynamic>>? revenueByTechnician,
    List<Map<String, dynamic>>? topParts,
    List<Map<String, dynamic>>? repeatCustomers,
    List<Map<String, dynamic>>? supplierPerformance,
    Map<String, int>? monthlyServiceVolume,
    int? slaBreaches,
  }) {
    return InsightsLoaded(
      activeTimeRange: activeTimeRange ?? this.activeTimeRange,
      revenue: revenue ?? this.revenue,
      avgTat: avgTat ?? this.avgTat,
      salesTrends: salesTrends ?? this.salesTrends,
      serviceLoad: serviceLoad ?? this.serviceLoad,
      inventoryUsage: inventoryUsage ?? this.inventoryUsage,
      revenueByTechnician: revenueByTechnician ?? this.revenueByTechnician,
      topParts: topParts ?? this.topParts,
      repeatCustomers: repeatCustomers ?? this.repeatCustomers,
      supplierPerformance: supplierPerformance ?? this.supplierPerformance,
      monthlyServiceVolume: monthlyServiceVolume ?? this.monthlyServiceVolume,
      slaBreaches: slaBreaches ?? this.slaBreaches,
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
    await _loadForRange(emit, 'This Month');
  }

  void _onChangeTimeRange(
    ChangeTimeRange event,
    Emitter<InsightsState> emit,
  ) async {
    await _loadForRange(emit, event.range);
  }

  Future<void> _loadForRange(
    Emitter<InsightsState> emit,
    String activeRange,
  ) async {
    emit(InsightsLoading());
    try {
      final techRepo = TechnicianRepository();
      final invRepo = InventoryRepository();
      final customerRepo = CustomerRepository();
      final dispatchRepo = DispatchRepository();
      final operationsRepo = OperationsRepository();
      final supplierRepo = SupplierRepository();

      final technicians = await techRepo.getTechnicians();
      final inventory = await invRepo.getInventory();
      final serviceHistory = await customerRepo.getAllServiceHistory();
      final requests = await dispatchRepo.getServiceRequests();
      final invoices = await operationsRepo.getInvoices();
      final purchaseOrders = await operationsRepo.getPurchaseOrders();
      final suppliers = await supplierRepo.getSuppliers();
      final customers = await customerRepo.getCustomers();

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

      final revenue =
          serviceHistory.fold<double>(
            0,
            (sum, entry) =>
                _matchesRange(_parseHistoryDate(entry.date), activeRange)
                ? sum + entry.cost
                : sum,
          ) +
          invoices.fold<double>(
            0,
            (sum, invoice) =>
                _matchesRange(DateTime.tryParse(invoice.issueDate), activeRange)
                ? sum + invoice.paidAmount
                : sum,
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
        if (date == null || !_matchesRange(date, activeRange)) continue;
        const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final label = labels[date.weekday - 1];
        salesTrends[label] = (salesTrends[label] ?? 0) + entry.cost;
      }

      final revenueByTech = <String, double>{};
      final topParts = <String, int>{};
      final repeatCustomers = <String, int>{};
      final monthlyVolume = <String, int>{};

      for (final entry in serviceHistory) {
        final date = _parseHistoryDate(entry.date);
        revenueByTech[entry.technicianName] =
            (revenueByTech[entry.technicianName] ?? 0) + entry.cost;
        repeatCustomers[entry.customerId] =
            (repeatCustomers[entry.customerId] ?? 0) + 1;
        for (final rawPart in entry.partsReplaced.split(',')) {
          final part = rawPart.trim();
          if (part.isEmpty) continue;
          topParts[part] = (topParts[part] ?? 0) + 1;
        }
        if (date != null) {
          final label = '${_monthLabel(date.month)} ${date.year}';
          monthlyVolume[label] = (monthlyVolume[label] ?? 0) + 1;
        }
      }

      final revenueByTechnician =
          revenueByTech.entries
              .map((entry) => {'name': entry.key, 'value': entry.value})
              .toList()
            ..sort(
              (a, b) => (b['value'] as double).compareTo(a['value'] as double),
            );

      final topPartsList =
          topParts.entries
              .map((entry) => {'name': entry.key, 'value': entry.value})
              .toList()
            ..sort((a, b) => (b['value'] as int).compareTo(a['value'] as int));

      final repeatCustomersList =
          repeatCustomers.entries.where((entry) => entry.value > 1).map((
              entry,
            ) {
              final customerName = customers
                  .where((customer) => customer.id == entry.key)
                  .map((customer) => customer.name)
                  .firstWhere(
                    (value) => value.trim().isNotEmpty,
                    orElse: () => entry.key,
                  );
              return {'name': customerName, 'value': entry.value};
            }).toList()
            ..sort((a, b) => (b['value'] as int).compareTo(a['value'] as int));

      final supplierPerformance =
          suppliers.map((supplier) {
            final related = purchaseOrders
                .where((order) => order.supplierId == supplier.id)
                .toList();
            final avgLead = related.isEmpty
                ? 0.0
                : related.fold<int>(0, (sum, order) => sum + order.leadDays) /
                      related.length;
            final onTime = related
                .where((order) => order.status == 'received')
                .length;
            return {
              'name': supplier.name,
              'leadDays': avgLead,
              'onTime': onTime,
              'orders': related.length,
            };
          }).toList()..sort(
            (a, b) =>
                (a['leadDays'] as double).compareTo(b['leadDays'] as double),
          );

      final slaBreaches = requests.where((request) {
        final scheduled = DateTime.tryParse(request.scheduledFor ?? '');
        if (request.status == 'completed' || scheduled == null) return false;
        return scheduled.isBefore(
          DateTime.now().subtract(const Duration(hours: 24)),
        );
      }).length;

      emit(
        InsightsLoaded(
          activeTimeRange: activeRange,
          revenue: revenue,
          avgTat: double.parse(avgTat.toStringAsFixed(1)),
          salesTrends: salesTrends,
          serviceLoad: serviceLoad,
          inventoryUsage: inventoryUsage,
          revenueByTechnician: revenueByTechnician,
          topParts: topPartsList.take(5).toList(),
          repeatCustomers: repeatCustomersList.take(5).toList(),
          supplierPerformance: supplierPerformance.take(5).toList(),
          monthlyServiceVolume: monthlyVolume,
          slaBreaches: slaBreaches,
        ),
      );
    } catch (e) {
      emit(InsightsError(e.toString()));
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

  bool _matchesRange(DateTime? date, String range) {
    if (date == null) return false;
    final now = DateTime.now();
    switch (range) {
      case 'Today':
        return date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
      case 'This Week':
        final start = now.subtract(Duration(days: now.weekday - 1));
        return !date.isBefore(DateTime(start.year, start.month, start.day));
      case 'This Month':
      case 'Custom':
        return date.year == now.year && date.month == now.month;
      default:
        return true;
    }
  }

  String _monthLabel(int month) {
    const labels = [
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
    return labels[month - 1];
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
