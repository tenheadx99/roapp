import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/technician.dart';
import '../repositories/technician_repository.dart';

// --- Events ---
abstract class TechnicianEvent extends Equatable {
  const TechnicianEvent();

  @override
  List<Object?> get props => [];
}

class LoadTechnicians extends TechnicianEvent {}

class SearchTechnicians extends TechnicianEvent {
  final String query;

  const SearchTechnicians(this.query);

  @override
  List<Object?> get props => [query];
}

class FilterTechnicians extends TechnicianEvent {
  final String filter; // 'All', 'North District', 'Downtown', etc.

  const FilterTechnicians(this.filter);

  @override
  List<Object?> get props => [filter];
}

class AddTechnician extends TechnicianEvent {
  final Technician technician;
  const AddTechnician(this.technician);
  @override
  List<Object?> get props => [technician];
}

class UpdateTechnician extends TechnicianEvent {
  final Technician technician;
  const UpdateTechnician(this.technician);
  @override
  List<Object?> get props => [technician];
}

class DeleteTechnician extends TechnicianEvent {
  final String technicianId;
  const DeleteTechnician(this.technicianId);
  @override
  List<Object?> get props => [technicianId];
}

// --- States ---
abstract class TechnicianState extends Equatable {
  const TechnicianState();

  @override
  List<Object?> get props => [];
}

class TechnicianInitial extends TechnicianState {}

class TechnicianLoading extends TechnicianState {}

class TechnicianLoaded extends TechnicianState {
  final List<Technician> allTechnicians;
  final List<Technician> filteredTechnicians;
  final String searchQuery;
  final String activeFilter;

  const TechnicianLoaded({
    required this.allTechnicians,
    required this.filteredTechnicians,
    this.searchQuery = '',
    this.activeFilter = 'All',
  });

  @override
  List<Object?> get props => [
    allTechnicians,
    filteredTechnicians,
    searchQuery,
    activeFilter,
  ];

  TechnicianLoaded copyWith({
    List<Technician>? allTechnicians,
    List<Technician>? filteredTechnicians,
    String? searchQuery,
    String? activeFilter,
  }) {
    return TechnicianLoaded(
      allTechnicians: allTechnicians ?? this.allTechnicians,
      filteredTechnicians: filteredTechnicians ?? this.filteredTechnicians,
      searchQuery: searchQuery ?? this.searchQuery,
      activeFilter: activeFilter ?? this.activeFilter,
    );
  }
}

class TechnicianError extends TechnicianState {
  final String message;

  const TechnicianError(this.message);

  @override
  List<Object?> get props => [message];
}

// --- Bloc ---
class TechnicianBloc extends Bloc<TechnicianEvent, TechnicianState> {
  final TechnicianRepository repository;

  TechnicianBloc({TechnicianRepository? repository})
    : repository = repository ?? TechnicianRepository(),
      super(TechnicianInitial()) {
    on<LoadTechnicians>(_onLoadTechnicians);
    on<SearchTechnicians>(_onSearchTechnicians);
    on<FilterTechnicians>(_onFilterTechnicians);
    on<AddTechnician>(_onAddTechnician);
    on<UpdateTechnician>(_onUpdateTechnician);
    on<DeleteTechnician>(_onDeleteTechnician);
  }

  void _onLoadTechnicians(
    LoadTechnicians event,
    Emitter<TechnicianState> emit,
  ) async {
    emit(TechnicianLoading());

    try {
      final technicians = await repository.getTechnicians();
      emit(
        TechnicianLoaded(
          allTechnicians: technicians,
          filteredTechnicians: technicians,
        ),
      );
    } catch (e) {
      emit(TechnicianError(e.toString()));
    }
  }

  void _onSearchTechnicians(
    SearchTechnicians event,
    Emitter<TechnicianState> emit,
  ) {
    if (state is TechnicianLoaded) {
      final currentState = state as TechnicianLoaded;
      final query = event.query.toLowerCase();

      final filtered = _getFiltered(
        currentState.allTechnicians,
        query,
        currentState.activeFilter,
      );

      emit(
        currentState.copyWith(
          filteredTechnicians: filtered,
          searchQuery: query,
        ),
      );
    }
  }

  void _onFilterTechnicians(
    FilterTechnicians event,
    Emitter<TechnicianState> emit,
  ) {
    if (state is TechnicianLoaded) {
      final currentState = state as TechnicianLoaded;

      final filtered = _getFiltered(
        currentState.allTechnicians,
        currentState.searchQuery,
        event.filter,
      );

      emit(
        currentState.copyWith(
          filteredTechnicians: filtered,
          activeFilter: event.filter,
        ),
      );
    }
  }

  List<Technician> _getFiltered(
    List<Technician> techs,
    String query,
    String filter,
  ) {
    return techs.where((t) {
      final matchesQuery =
          t.name.toLowerCase().contains(query) ||
          t.region.toLowerCase().contains(query);
      final matchesFilter = filter == 'All' || t.region == filter;
      return matchesQuery && matchesFilter;
    }).toList();
  }

  void _onAddTechnician(
    AddTechnician event,
    Emitter<TechnicianState> emit,
  ) async {
    try {
      await repository.addTechnician(event.technician);
      add(LoadTechnicians());
    } catch (e) {
      emit(TechnicianError(e.toString()));
    }
  }

  void _onUpdateTechnician(
    UpdateTechnician event,
    Emitter<TechnicianState> emit,
  ) async {
    try {
      await repository.updateTechnician(event.technician);
      add(LoadTechnicians());
    } catch (e) {
      emit(TechnicianError(e.toString()));
    }
  }

  void _onDeleteTechnician(
    DeleteTechnician event,
    Emitter<TechnicianState> emit,
  ) async {
    try {
      await repository.deleteTechnician(event.technicianId);
      add(LoadTechnicians());
    } catch (e) {
      emit(TechnicianError(e.toString()));
    }
  }
}
