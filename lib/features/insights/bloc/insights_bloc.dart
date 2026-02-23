import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    await Future.delayed(const Duration(milliseconds: 500));

    emit(
      const InsightsLoaded(
        activeTimeRange: 'Today',
        revenue: 14290,
        avgTat: 3.8,
        salesTrends: {
          'Mon': 40,
          'Tue': 60,
          'Wed': 55,
          'Thu': 85,
          'Fri': 100,
          'Sat': 45,
          'Sun': 30,
        },
        serviceLoad: [
          {'name': 'Alex Johnson', 'tasks': 42, 'color': '#007fff'},
          {'name': 'Maria Garcia', 'tasks': 28, 'color': '#007fff99'},
          {'name': 'Sam Wilson', 'tasks': 15, 'color': '#007fff4d'},
        ],
        inventoryUsage: [
          {'name': 'Sediment Filters', 'value': 65.0, 'color': '#007fff'},
          {'name': 'RO Membranes', 'value': 25.0, 'color': '#007fff66'},
          {'name': 'Others', 'value': 10.0, 'color': '#f1f5f9'},
        ],
      ),
    );
  }

  void _onChangeTimeRange(ChangeTimeRange event, Emitter<InsightsState> emit) {
    if (state is InsightsLoaded) {
      final currentState = state as InsightsLoaded;

      // In a real app, this would recalculate or fetch new data based on the range.
      // Here we just update the active range text.
      emit(currentState.copyWith(activeTimeRange: event.range));
    }
  }
}
