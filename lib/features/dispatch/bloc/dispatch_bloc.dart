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
  final String statusTab;

  const FilterDispatchRequests(this.statusTab);

  @override
  List<Object?> get props => [statusTab];
}

class AddServiceRequest extends DispatchEvent {
  final ServiceRequest request;
  const AddServiceRequest(this.request);
  @override
  List<Object?> get props => [request];
}

class UpdateServiceRequest extends DispatchEvent {
  final ServiceRequest request;
  const UpdateServiceRequest(this.request);
  @override
  List<Object?> get props => [request];
}

class DeleteServiceRequest extends DispatchEvent {
  final String requestId;
  const DeleteServiceRequest(this.requestId);
  @override
  List<Object?> get props => [requestId];
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
    this.activeTab = 'New',
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
    on<AddServiceRequest>(_onAddServiceRequest);
    on<UpdateServiceRequest>(_onUpdateServiceRequest);
    on<DeleteServiceRequest>(_onDeleteServiceRequest);
  }

  void _onLoadRequests(
    LoadDispatchRequests event,
    Emitter<DispatchState> emit,
  ) async {
    emit(DispatchLoading());
    try {
      final requests = await repository.getServiceRequests();
      emit(
        DispatchLoaded(
          allRequests: requests,
          filteredRequests: _filterByTab(requests, 'New'),
          activeTab: 'New',
        ),
      );
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
    if (tab.startsWith('New')) {
      return requests.where((r) => r.status == 'new').toList();
    } else if (tab.startsWith('Assigned')) {
      return requests.where((r) => r.status == 'assigned').toList();
    } else if (tab.startsWith('In Progress')) {
      return requests.where((r) => r.status == 'in_progress').toList();
    } else {
      return requests.where((r) => r.status == 'completed').toList();
    }
  }

  Future<void> _reloadForActiveTab(Emitter<DispatchState> emit) async {
    final activeTab = state is DispatchLoaded
        ? (state as DispatchLoaded).activeTab
        : 'New';
    final requests = await repository.getServiceRequests();
    emit(
      DispatchLoaded(
        allRequests: requests,
        filteredRequests: _filterByTab(requests, activeTab),
        activeTab: activeTab,
      ),
    );
  }

  void _onAddServiceRequest(
    AddServiceRequest event,
    Emitter<DispatchState> emit,
  ) async {
    try {
      await repository.addServiceRequest(event.request);
      await _reloadForActiveTab(emit);
    } catch (e) {
      emit(DispatchError(e.toString()));
    }
  }

  void _onUpdateServiceRequest(
    UpdateServiceRequest event,
    Emitter<DispatchState> emit,
  ) async {
    try {
      await repository.updateServiceRequest(event.request);
      await _reloadForActiveTab(emit);
    } catch (e) {
      emit(DispatchError(e.toString()));
    }
  }

  void _onDeleteServiceRequest(
    DeleteServiceRequest event,
    Emitter<DispatchState> emit,
  ) async {
    try {
      await repository.deleteServiceRequest(event.requestId);
      await _reloadForActiveTab(emit);
    } catch (e) {
      emit(DispatchError(e.toString()));
    }
  }
}
