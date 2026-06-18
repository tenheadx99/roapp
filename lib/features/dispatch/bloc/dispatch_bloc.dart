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

class SelectDispatchDate extends DispatchEvent {
  final DateTime? selectedDate;

  const SelectDispatchDate(this.selectedDate);

  @override
  List<Object?> get props => [selectedDate];
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
  final DateTime? selectedDate;

  const DispatchLoaded({
    required this.allRequests,
    required this.filteredRequests,
    this.activeTab = 'New',
    this.selectedDate,
  });

  @override
  List<Object?> get props => [
    allRequests,
    filteredRequests,
    activeTab,
    selectedDate,
  ];

  DispatchLoaded copyWith({
    List<ServiceRequest>? allRequests,
    List<ServiceRequest>? filteredRequests,
    String? activeTab,
    DateTime? selectedDate,
    bool clearSelectedDate = false,
  }) {
    return DispatchLoaded(
      allRequests: allRequests ?? this.allRequests,
      filteredRequests: filteredRequests ?? this.filteredRequests,
      activeTab: activeTab ?? this.activeTab,
      selectedDate: clearSelectedDate
          ? null
          : (selectedDate ?? this.selectedDate),
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
    on<SelectDispatchDate>(_onSelectDispatchDate);
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
          filteredRequests: _applyFilters(requests, 'New', null),
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
      final filtered = _applyFilters(
        currentState.allRequests,
        event.statusTab,
        currentState.selectedDate,
      );

      emit(
        currentState.copyWith(
          filteredRequests: filtered,
          activeTab: event.statusTab,
        ),
      );
    }
  }

  void _onSelectDispatchDate(
    SelectDispatchDate event,
    Emitter<DispatchState> emit,
  ) {
    if (state is! DispatchLoaded) return;
    final currentState = state as DispatchLoaded;
    emit(
      currentState.copyWith(
        selectedDate: event.selectedDate,
        clearSelectedDate: event.selectedDate == null,
        filteredRequests: _applyFilters(
          currentState.allRequests,
          currentState.activeTab,
          event.selectedDate,
        ),
      ),
    );
  }

  List<ServiceRequest> _filterByTab(List<ServiceRequest> requests, String tab) {
    if (tab.startsWith('New')) {
      return requests.where((r) => r.status == 'new').toList();
    } else if (tab.startsWith('Assigned')) {
      return requests.where((r) => r.status == 'assigned').toList();
    } else if (tab.startsWith('In Progress')) {
      return requests.where((r) => r.status == 'in_progress').toList();
    } else {
      final completed = requests
          .where((r) => r.status == 'completed')
          .toList();
      completed.sort((a, b) {
        final da =
            DateTime.tryParse(a.completedAt ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final db =
            DateTime.tryParse(b.completedAt ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return db.compareTo(da); // newest first
      });
      return completed;
    }
  }

  List<ServiceRequest> _applyFilters(
    List<ServiceRequest> requests,
    String tab,
    DateTime? selectedDate,
  ) {
    final byTab = _filterByTab(requests, tab);
    if (selectedDate == null) {
      return byTab;
    }
    return byTab
        .where((request) => _matchesDate(request, selectedDate))
        .toList();
  }

  bool _matchesDate(ServiceRequest request, DateTime selectedDate) {
    final scheduled = DateTime.tryParse(request.scheduledFor ?? '');
    if (scheduled == null) return false;
    return scheduled.year == selectedDate.year &&
        scheduled.month == selectedDate.month &&
        scheduled.day == selectedDate.day;
  }

  Future<void> _reloadForActiveTab(Emitter<DispatchState> emit) async {
    final activeTab = state is DispatchLoaded
        ? (state as DispatchLoaded).activeTab
        : 'New';
    final selectedDate = state is DispatchLoaded
        ? (state as DispatchLoaded).selectedDate
        : null;
    final requests = await repository.getServiceRequests();
    emit(
      DispatchLoaded(
        allRequests: requests,
        filteredRequests: _applyFilters(requests, activeTab, selectedDate),
        activeTab: activeTab,
        selectedDate: selectedDate,
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
