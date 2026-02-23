import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/technician.dart';

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
  TechnicianBloc() : super(TechnicianInitial()) {
    on<LoadTechnicians>(_onLoadTechnicians);
    on<SearchTechnicians>(_onSearchTechnicians);
    on<FilterTechnicians>(_onFilterTechnicians);
  }

  void _onLoadTechnicians(
    LoadTechnicians event,
    Emitter<TechnicianState> emit,
  ) async {
    emit(TechnicianLoading());
    await Future.delayed(const Duration(milliseconds: 500));

    final technicians = [
      const Technician(
        id: '1',
        name: 'Ravi Kumar',
        phone: '+91 98765 00001',
        region: 'North District',
        hubs: ['Hub A', 'Hub C'],
        tasksToday: 5,
        status: 'online',
        avatar:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuD4Sx1YCi58f2ilhJyNTxSaQFbgKcz_LvEdOFfhLLcWGGQpuwK2i1UO1Pf1R-91BdyKuR6oUASBI6C64cOVRUb0aua0pPcSYXFWMb2Y05px20SWNIIMlDyNq_1GySh9p1s_nv5NTPt1O2vZS_r74EIxHzIfyUuYuUr3J_Lrd6Us7MB_rIizokhySFMCrfJaGIRxtCGRm9U_grwST1htLPLIU19JqM7qTz_eUHiBgsjKemZWkOUWswtT3M1XOEWpgZ-3t9xH3-M_abF1',
      ),
      const Technician(
        id: '2',
        name: 'Amit Shah',
        phone: '+91 98765 00002',
        region: 'Downtown',
        hubs: ['Hub B'],
        tasksToday: 3,
        status: 'busy',
        avatar:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuDQF2X7f56qnt3s-Vw27eONB8sH1Q8Z3K-Pz3R8KqF4PqO3qS0zE2vA4QoV7nL3P4q5P1W3gE1U7R1R6Y1tC11v3J0H52-4S432QpA7kO_aX0A2B1vV5p4yZ2J0uG4C9Y_H4L0c1Z6E3Q6S2y_7U1O6zE2vA4QoV7nL3P4q5P1W3gE1U7R1R6Y1tC1',
      ),
      const Technician(
        id: '3',
        name: 'Priya Sharma',
        phone: '+91 98765 00003',
        region: 'Industrial Park',
        hubs: ['Hub D'],
        tasksToday: 0,
        status: 'on-leave',
      ),
    ];

    emit(
      TechnicianLoaded(
        allTechnicians: technicians,
        filteredTechnicians: technicians,
      ),
    );
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
}
