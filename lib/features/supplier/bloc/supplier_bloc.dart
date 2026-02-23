import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/supplier.dart';

// --- Events ---
abstract class SupplierEvent extends Equatable {
  const SupplierEvent();

  @override
  List<Object?> get props => [];
}

class LoadSuppliersRequested extends SupplierEvent {}

class SearchSuppliers extends SupplierEvent {
  final String query;

  const SearchSuppliers(this.query);

  @override
  List<Object?> get props => [query];
}

class FilterSuppliersByCategory extends SupplierEvent {
  final String category;

  const FilterSuppliersByCategory(this.category);

  @override
  List<Object?> get props => [category];
}

// --- States ---
abstract class SupplierState extends Equatable {
  const SupplierState();

  @override
  List<Object?> get props => [];
}

class SupplierInitial extends SupplierState {}

class SupplierLoading extends SupplierState {}

class SupplierLoaded extends SupplierState {
  final List<Supplier> allSuppliers;
  final List<Supplier> filteredSuppliers;
  final String searchQuery;
  final String selectedCategory;

  const SupplierLoaded({
    required this.allSuppliers,
    required this.filteredSuppliers,
    this.searchQuery = '',
    this.selectedCategory = 'All Suppliers',
  });

  @override
  List<Object?> get props => [
    allSuppliers,
    filteredSuppliers,
    searchQuery,
    selectedCategory,
  ];

  SupplierLoaded copyWith({
    List<Supplier>? allSuppliers,
    List<Supplier>? filteredSuppliers,
    String? searchQuery,
    String? selectedCategory,
  }) {
    return SupplierLoaded(
      allSuppliers: allSuppliers ?? this.allSuppliers,
      filteredSuppliers: filteredSuppliers ?? this.filteredSuppliers,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
    );
  }
}

class SupplierError extends SupplierState {
  final String message;

  const SupplierError(this.message);

  @override
  List<Object?> get props => [message];
}

// --- Bloc ---
class SupplierBloc extends Bloc<SupplierEvent, SupplierState> {
  SupplierBloc() : super(SupplierInitial()) {
    on<LoadSuppliersRequested>(_onLoadSuppliers);
    on<SearchSuppliers>(_onSearchSuppliers);
    on<FilterSuppliersByCategory>(_onFilterSuppliersByCategory);
  }

  void _onLoadSuppliers(
    LoadSuppliersRequested event,
    Emitter<SupplierState> emit,
  ) async {
    emit(SupplierLoading());

    await Future.delayed(const Duration(milliseconds: 500));

    final suppliers = [
      const Supplier(
        id: '1',
        name: 'AquaTech Solutions',
        contactPerson: 'Rajesh Kumar',
        city: 'New Delhi',
        specialties: ['Dow Membranes', 'Booster Pumps'],
        activePOs: 8,
        status: 'active',
      ),
      const Supplier(
        id: '2',
        name: 'PureFlow Filtration Ltd.',
        contactPerson: 'Amit Shah',
        city: 'Mumbai',
        specialties: ['Sediment Filters', 'Pre-Filters'],
        activePOs: 3,
        status: 'active',
      ),
      const Supplier(
        id: '3',
        name: 'Z-Electron Components',
        contactPerson: 'Vikram Singh',
        city: 'Bengaluru',
        specialties: ['SMPS Adapters', 'Solenoid Valves'],
        activePOs: 0,
        status: 'inactive',
      ),
    ];

    emit(SupplierLoaded(allSuppliers: suppliers, filteredSuppliers: suppliers));
  }

  void _onSearchSuppliers(SearchSuppliers event, Emitter<SupplierState> emit) {
    if (state is SupplierLoaded) {
      final currentState = state as SupplierLoaded;
      final query = event.query.toLowerCase();

      final filtered = _filterSuppliers(
        currentState.allSuppliers,
        query,
        currentState.selectedCategory,
      );

      emit(
        currentState.copyWith(filteredSuppliers: filtered, searchQuery: query),
      );
    }
  }

  void _onFilterSuppliersByCategory(
    FilterSuppliersByCategory event,
    Emitter<SupplierState> emit,
  ) {
    if (state is SupplierLoaded) {
      final currentState = state as SupplierLoaded;
      final category = event.category;

      final filtered = _filterSuppliers(
        currentState.allSuppliers,
        currentState.searchQuery,
        category,
      );

      emit(
        currentState.copyWith(
          filteredSuppliers: filtered,
          selectedCategory: category,
        ),
      );
    }
  }

  List<Supplier> _filterSuppliers(
    List<Supplier> allSuppliers,
    String query,
    String category,
  ) {
    return allSuppliers.where((s) {
      final matchesSearch =
          s.name.toLowerCase().contains(query) ||
          s.city.toLowerCase().contains(query);

      final matchesCategory =
          category == 'All Suppliers' || s.specialties.contains(category);

      return matchesSearch && matchesCategory;
    }).toList();
  }
}
