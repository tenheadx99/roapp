import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/service_request.dart';
import '../repositories/dispatch_repository.dart';

// --- Events ---
abstract class DispatchEvent extends Equatable {
  const DispatchEvent();

  @override
  List<Object?> get props => [];
}

class LoadDispatchRequests extends DispatchEvent {}

class FilterDispatchRequests extends DispatchEvent {
  final String statusTab; // 'New (4)', 'Assigned (12)', 'In Progress (8)'

  const FilterDispatchRequests(this.statusTab);

  @override
  List<Object?> get props => [statusTab];
}

// --- States ---
abstract class DispatchState extends Equatable {
  const DispatchState();

  @override
  List<Object?> get props => [];
}

class DispatchInitial extends DispatchState {}

class DispatchLoading extends DispatchState {}

class DispatchLoaded extends DispatchState {
  final List<ServiceRequest> allRequests;
  final List<ServiceRequest> filteredRequests;
  final String activeTab;

  const DispatchLoaded({
    required this.allRequests,
    required this.filteredRequests,
    this.activeTab = 'New (4)',
  });

  @override
  List<Object?> get props => [allRequests, filteredRequests, activeTab];

  DispatchLoaded copyWith({
    List<ServiceRequest>? allRequests,
    List<ServiceRequest>? filteredRequests,
    String? activeTab,
  }) {
    return DispatchLoaded(
      allRequests: allRequests ?? this.allRequests,
      filteredRequests: filteredRequests ?? this.filteredRequests,
      activeTab: activeTab ?? this.activeTab,
    );
  }
}

class DispatchError extends DispatchState {
  final String message;

  const DispatchError(this.message);

  @override
  List<Object?> get props => [message];
}

// --- Bloc ---
class DispatchBloc extends Bloc<DispatchEvent, DispatchState> {
  final DispatchRepository repository;

  DispatchBloc({DispatchRepository? repository})
    : repository = repository ?? DispatchRepository(),
      super(DispatchInitial()) {
    on<LoadDispatchRequests>(_onLoadRequests);
    on<FilterDispatchRequests>(_onFilterRequests);
  }

  void _onLoadRequests(
    LoadDispatchRequests event,
    Emitter<DispatchState> emit,
  ) async {
    emit(DispatchLoading());
    try {
      final requests = await repository.getServiceRequests();
      final filtered = _filterByTab(requests, 'New (4)');
      emit(DispatchLoaded(allRequests: requests, filteredRequests: filtered));
    } catch (e) {
      emit(DispatchError(e.toString()));
    }
  }

  void _onFilterRequests(
    FilterDispatchRequests event,
    Emitter<DispatchState> emit,
  ) {
    if (state is DispatchLoaded) {
      final currentState = state as DispatchLoaded;
      final filtered = _filterByTab(currentState.allRequests, event.statusTab);

      emit(
        currentState.copyWith(
          filteredRequests: filtered,
          activeTab: event.statusTab,
        ),
      );
    }
  }

  List<ServiceRequest> _filterByTab(List<ServiceRequest> requests, String tab) {
    // Basic mapping based on React tabs
    if (tab.startsWith('New')) {
      return requests.where((r) => r.status == 'new').toList();
    } else if (tab.startsWith('Assigned')) {
      return requests.where((r) => r.status == 'assigned').toList();
    } else {
      return requests.where((r) => r.status == 'in_progress').toList();
    }
  }
}
