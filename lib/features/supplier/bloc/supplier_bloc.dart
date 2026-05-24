import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/supplier.dart';
import '../repositories/supplier_repository.dart';

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

class AddSupplier extends SupplierEvent {
  final Supplier supplier;
  const AddSupplier(this.supplier);
  @override
  List<Object?> get props => [supplier];
}

class UpdateSupplier extends SupplierEvent {
  final Supplier supplier;
  const UpdateSupplier(this.supplier);
  @override
  List<Object?> get props => [supplier];
}

class DeleteSupplier extends SupplierEvent {
  final String supplierId;
  const DeleteSupplier(this.supplierId);
  @override
  List<Object?> get props => [supplierId];
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
  final SupplierRepository repository;

  SupplierBloc({SupplierRepository? repository})
    : repository = repository ?? SupplierRepository(),
      super(SupplierInitial()) {
    on<LoadSuppliersRequested>(_onLoadSuppliers);
    on<SearchSuppliers>(_onSearchSuppliers);
    on<FilterSuppliersByCategory>(_onFilterSuppliersByCategory);
    on<AddSupplier>(_onAddSupplier);
    on<UpdateSupplier>(_onUpdateSupplier);
    on<DeleteSupplier>(_onDeleteSupplier);
  }

  void _onLoadSuppliers(
    LoadSuppliersRequested event,
    Emitter<SupplierState> emit,
  ) async {
    emit(SupplierLoading());

    try {
      final suppliers = await repository.getSuppliers();
      emit(
        SupplierLoaded(allSuppliers: suppliers, filteredSuppliers: suppliers),
      );
    } catch (e) {
      emit(SupplierError(e.toString()));
    }
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
          s.city.toLowerCase().contains(query) ||
          s.contactPerson.toLowerCase().contains(query) ||
          s.phone.toLowerCase().contains(query) ||
          s.email.toLowerCase().contains(query) ||
          s.specialties.any(
            (specialty) => specialty.toLowerCase().contains(query),
          );

      final matchesCategory =
          category == 'All Suppliers' ||
          s.specialties.any((specialty) => specialty.trim() == category);

      return matchesSearch && matchesCategory;
    }).toList();
  }

  void _onAddSupplier(AddSupplier event, Emitter<SupplierState> emit) async {
    try {
      await repository.addSupplier(event.supplier);
      add(LoadSuppliersRequested());
    } catch (e) {
      emit(SupplierError(e.toString()));
    }
  }

  void _onUpdateSupplier(
    UpdateSupplier event,
    Emitter<SupplierState> emit,
  ) async {
    try {
      await repository.updateSupplier(event.supplier);
      add(LoadSuppliersRequested());
    } catch (e) {
      emit(SupplierError(e.toString()));
    }
  }

  void _onDeleteSupplier(
    DeleteSupplier event,
    Emitter<SupplierState> emit,
  ) async {
    try {
      await repository.deleteSupplier(event.supplierId);
      add(LoadSuppliersRequested());
    } catch (e) {
      emit(SupplierError(e.toString()));
    }
  }
}
