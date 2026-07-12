import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../customer/repositories/customer_repository.dart';
import '../../dispatch/models/service_request.dart';
import '../../dispatch/repositories/dispatch_repository.dart';
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
  final String range; // 'Today', 'This Week', 'This Month', 'All Time', 'Custom'
  final DateTime? customStartDate;
  final DateTime? customEndDate;

  const ChangeTimeRange(
    this.range, {
    this.customStartDate,
    this.customEndDate,
  });

  @override
  List<Object?> get props => [range, customStartDate, customEndDate];
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
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final double revenue;
  final double profit;
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
  final double partsRevenue;
  final double partsCost;
  final double partsProfit;
  final double serviceCharge;

  const InsightsLoaded({
    required this.activeTimeRange,
    this.customStartDate,
    this.customEndDate,
    required this.revenue,
    required this.profit,
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
    this.partsRevenue = 0.0,
    this.partsCost = 0.0,
    this.partsProfit = 0.0,
    this.serviceCharge = 0.0,
  });

  @override
  List<Object?> get props => [
    activeTimeRange,
    customStartDate,
    customEndDate,
    revenue,
    profit,
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
    partsRevenue,
    partsCost,
    partsProfit,
    serviceCharge,
  ];

  InsightsLoaded copyWith({
    String? activeTimeRange,
    DateTime? customStartDate,
    DateTime? customEndDate,
    double? revenue,
    double? profit,
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
    double? partsRevenue,
    double? partsCost,
    double? partsProfit,
    double? serviceCharge,
  }) {
    return InsightsLoaded(
      activeTimeRange: activeTimeRange ?? this.activeTimeRange,
      customStartDate: customStartDate ?? this.customStartDate,
      customEndDate: customEndDate ?? this.customEndDate,
      revenue: revenue ?? this.revenue,
      profit: profit ?? this.profit,
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
      partsRevenue: partsRevenue ?? this.partsRevenue,
      partsCost: partsCost ?? this.partsCost,
      partsProfit: partsProfit ?? this.partsProfit,
      serviceCharge: serviceCharge ?? this.serviceCharge,
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
  final TechnicianRepository techRepo;
  final CustomerRepository customerRepo;
  final DispatchRepository dispatchRepo;
  final OperationsRepository operationsRepo;
  final SupplierRepository supplierRepo;

  InsightsBloc({
    TechnicianRepository? technicianRepository,
    CustomerRepository? customerRepository,
    DispatchRepository? dispatchRepository,
    OperationsRepository? operationsRepository,
    SupplierRepository? supplierRepository,
  })  : techRepo = technicianRepository ?? TechnicianRepository(),
        customerRepo = customerRepository ?? CustomerRepository(),
        dispatchRepo = dispatchRepository ?? DispatchRepository(),
        operationsRepo = operationsRepository ?? OperationsRepository(),
        supplierRepo = supplierRepository ?? SupplierRepository(),
        super(InsightsInitial()) {
    on<LoadInsightsData>(_onLoadData);
    on<ChangeTimeRange>(_onChangeTimeRange);
  }

  void _onLoadData(LoadInsightsData event, Emitter<InsightsState> emit) async {
    await _loadForRange(emit, 'All Time');
  }

  void _onChangeTimeRange(
    ChangeTimeRange event,
    Emitter<InsightsState> emit,
  ) async {
    await _loadForRange(
      emit,
      event.range,
      customStartDate: event.customStartDate,
      customEndDate: event.customEndDate,
    );
  }

  Future<void> _loadForRange(
    Emitter<InsightsState> emit,
    String activeRange, {
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) async {
    emit(InsightsLoading());
    try {
      final technicians = await techRepo.getTechnicians();
      final requests = await dispatchRepo.getServiceRequests();
      final serviceHistory = await customerRepo.getAllServiceHistory();
      final invoices = await operationsRepo.getInvoices();
      final purchaseOrders = await operationsRepo.getPurchaseOrders();
      final suppliers = await supplierRepo.getSuppliers();
      final customers = await customerRepo.getCustomers();

      final historiesInRange = serviceHistory.where((entry) {
        return _matchesRange(
          _parseHistoryDate(entry.date),
          activeRange,
          customStartDate: customStartDate,
          customEndDate: customEndDate,
        );
      }).toList();
      final invoicesInRange = invoices.where((invoice) {
        return _matchesRange(
          DateTime.tryParse(invoice.issueDate),
          activeRange,
          customStartDate: customStartDate,
          customEndDate: customEndDate,
        );
      }).toList();

      final loadByTechnician = <String, int>{};
      for (final technician in technicians) {
        loadByTechnician[technician.name] = 0;
      }

      for (final request in requests) {
        final technicianName = (request.technicianName ?? '').trim();
        if (technicianName.isEmpty || request.status == 'completed') continue;
        loadByTechnician[technicianName] =
            (loadByTechnician[technicianName] ?? 0) + 1;
      }

      for (final entry in historiesInRange) {
        loadByTechnician[entry.technicianName] =
            (loadByTechnician[entry.technicianName] ?? 0) + 1;
      }

      var serviceLoad = loadByTechnician.entries.map((entry) {
        return {'name': entry.key, 'tasks': entry.value, 'color': '#007fff'};
      }).toList();

      if (serviceLoad.isEmpty) {
        serviceLoad = [
          {'name': 'No Technicians', 'tasks': 0, 'color': '#007fff'},
        ];
      }

      final inventoryUsageCounts = <String, int>{};
      var totalPartsUsed = 0;
      for (final entry in historiesInRange) {
        final parts = _parsePartsUsage(entry.partsReplaced);
        for (final part in parts.entries) {
          inventoryUsageCounts[part.key] =
              (inventoryUsageCounts[part.key] ?? 0) + part.value;
          totalPartsUsed += part.value;
        }
      }

      var inventoryUsage = inventoryUsageCounts.entries.map((e) {
        return {
          'name': e.key,
          'value': totalPartsUsed > 0 ? (e.value / totalPartsUsed) * 100 : 0.0,
          'color': '#007fff',
        };
      }).toList();

      if (inventoryUsage.isEmpty) {
        inventoryUsage = [
          {'name': 'No Usage', 'value': 100.0, 'color': '#f1f5f9'},
        ];
      }

      double totalRevenue = 0.0;
      double totalPartsRevenue = 0.0;
      double totalPartsCost = 0.0;
      double totalServiceCharge = 0.0;

      final processedRequestIds = <String>{};
      for (final invoice in invoicesInRange) {
        totalRevenue += invoice.paidAmount;
        totalPartsCost += invoice.supplierPrice;

        final requestId = invoice.id.startsWith('inv-') ? invoice.id.substring(4) : null;
        ServiceRequest? matchingRequest;
        if (requestId != null) {
          processedRequestIds.add(requestId);
          try {
            matchingRequest = requests.firstWhere((r) => r.id == requestId);
          } catch (_) {}
        }

        if (matchingRequest != null) {
          final partsSelPrice = matchingRequest.inventoryItems.fold<double>(0, (sum, item) => sum + item.lineTotal);
          totalPartsRevenue += partsSelPrice;
          final svcCharge = invoice.totalAmount - partsSelPrice;
          totalServiceCharge += svcCharge > 0 ? svcCharge : 0.0;
        } else {
          if (invoice.supplierPrice > 0) {
            totalPartsRevenue += invoice.supplierPrice;
            final svcCharge = invoice.totalAmount - invoice.supplierPrice;
            totalServiceCharge += svcCharge > 0 ? svcCharge : 0.0;
          } else {
            totalServiceCharge += invoice.totalAmount;
          }
        }
      }

      for (final entry in historiesInRange) {
        if (entry.serviceRequestId != null && processedRequestIds.contains(entry.serviceRequestId)) {
          continue;
        }
        final hasInvoiceInDb = invoices.any((inv) => inv.id == 'inv-${entry.serviceRequestId}');
        if (hasInvoiceInDb) {
          continue;
        }

        totalRevenue += entry.cost;

        ServiceRequest? matchingRequest;
        if (entry.serviceRequestId != null) {
          try {
            matchingRequest = requests.firstWhere((r) => r.id == entry.serviceRequestId);
          } catch (_) {}
        }

        if (matchingRequest != null) {
          final partsSelPrice = matchingRequest.inventoryItems.fold<double>(0, (sum, item) => sum + item.lineTotal);
          totalPartsRevenue += partsSelPrice;
          double estSupplierCost = 0.0;
          for (final item in matchingRequest.inventoryItems) {
            estSupplierCost += item.unitPrice * 0.7 * item.quantity;
          }
          totalPartsCost += estSupplierCost;
          final svcCharge = entry.cost - partsSelPrice;
          totalServiceCharge += svcCharge > 0 ? svcCharge : 0.0;
        } else {
          totalServiceCharge += entry.cost;
        }
      }

      final partsProfit = totalPartsRevenue - totalPartsCost;
      final revenue = totalRevenue;
      final profit = partsProfit + totalServiceCharge;

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

      for (final invoice in invoicesInRange) {
        final date = DateTime.tryParse(invoice.issueDate);
        if (date == null) continue;
        const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final label = labels[date.weekday - 1];
        salesTrends[label] = (salesTrends[label] ?? 0) + invoice.paidAmount;
      }
      for (final entry in historiesInRange) {
        if (entry.serviceRequestId != null && processedRequestIds.contains(entry.serviceRequestId)) {
          continue;
        }
        final hasInvoiceInDb = invoices.any((inv) => inv.id == 'inv-${entry.serviceRequestId}');
        if (hasInvoiceInDb) {
          continue;
        }
        final date = _parseHistoryDate(entry.date);
        if (date == null) continue;
        const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final label = labels[date.weekday - 1];
        salesTrends[label] = (salesTrends[label] ?? 0) + entry.cost;
      }

      final revenueByTech = <String, double>{};
      final topParts = <String, int>{};
      final repeatCustomers = <String, int>{};
      final monthlyVolume = <String, int>{};

      for (final invoice in invoicesInRange) {
        final requestId = invoice.id.startsWith('inv-') ? invoice.id.substring(4) : null;
        ServiceRequest? matchingRequest;
        if (requestId != null) {
          try {
            matchingRequest = requests.firstWhere((r) => r.id == requestId);
          } catch (_) {}
        }
        final techName = matchingRequest?.technicianName ?? 'Office';
        revenueByTech[techName] = (revenueByTech[techName] ?? 0) + invoice.paidAmount;
      }
      for (final entry in historiesInRange) {
        if (entry.serviceRequestId != null && processedRequestIds.contains(entry.serviceRequestId)) {
          continue;
        }
        final hasInvoiceInDb = invoices.any((inv) => inv.id == 'inv-${entry.serviceRequestId}');
        if (hasInvoiceInDb) {
          continue;
        }
        revenueByTech[entry.technicianName] =
            (revenueByTech[entry.technicianName] ?? 0) + entry.cost;
      }

      for (final entry in historiesInRange) {
        final date = _parseHistoryDate(entry.date);
        repeatCustomers[entry.customerId] =
            (repeatCustomers[entry.customerId] ?? 0) + 1;
        final parts = _parsePartsUsage(entry.partsReplaced);
        for (final part in parts.entries) {
          topParts[part.key] = (topParts[part.key] ?? 0) + part.value;
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
          customStartDate: customStartDate,
          customEndDate: customEndDate,
          revenue: revenue,
          profit: profit,
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
          partsRevenue: totalPartsRevenue,
          partsCost: totalPartsCost,
          partsProfit: partsProfit,
          serviceCharge: totalServiceCharge,
        ),
      );
    } catch (e, stackTrace) {
      addError(e, stackTrace);
      emit(
        const InsightsError('Could not load insights. Please try again.'),
      );
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

  bool _matchesRange(
    DateTime? date,
    String range, {
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) {
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
        return date.year == now.year && date.month == now.month;
      case 'Custom':
        if (customStartDate != null && customEndDate != null) {
          final checkDate = DateTime(date.year, date.month, date.day);
          final startDate = DateTime(customStartDate.year, customStartDate.month, customStartDate.day);
          final endDate = DateTime(customEndDate.year, customEndDate.month, customEndDate.day);
          return !checkDate.isBefore(startDate) && !checkDate.isAfter(endDate);
        }
        return date.year == now.year && date.month == now.month;
      case 'All Time':
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

  Map<String, int> _parsePartsUsage(String value) {
    final usage = <String, int>{};
    for (final rawPart in value.split(',')) {
      final part = rawPart.trim();
      if (part.isEmpty || part.toLowerCase() == 'none') {
        continue;
      }
      final match = RegExp(r'^(.*?)(?:\s*x\s*(\d+))?$').firstMatch(part);
      final name = (match?.group(1) ?? part).trim();
      final quantity = int.tryParse(match?.group(2) ?? '') ?? 1;
      if (name.isEmpty) continue;
      usage[name] = (usage[name] ?? 0) + quantity;
    }
    return usage;
  }
}
