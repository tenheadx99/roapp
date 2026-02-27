import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/inventory_item.dart';
import '../repositories/inventory_repository.dart';

// --- Events ---
abstract class InventoryEvent extends Equatable {
  const InventoryEvent();

  @override
  List<Object?> get props => [];
}

class LoadInventoryRequested extends InventoryEvent {}

class SearchInventory extends InventoryEvent {
  final String query;

  const SearchInventory(this.query);

  @override
  List<Object?> get props => [query];
}

class FilterInventoryByCategory extends InventoryEvent {
  final String category;

  const FilterInventoryByCategory(this.category);

  @override
  List<Object?> get props => [category];
}

// --- States ---
abstract class InventoryState extends Equatable {
  const InventoryState();

  @override
  List<Object?> get props => [];
}

class InventoryInitial extends InventoryState {}

class InventoryLoading extends InventoryState {}

class InventoryLoaded extends InventoryState {
  final List<InventoryItem> allItems;
  final List<InventoryItem> filteredItems;
  final String searchQuery;
  final String selectedCategory;

  const InventoryLoaded({
    required this.allItems,
    required this.filteredItems,
    this.searchQuery = '',
    this.selectedCategory = 'All',
  });

  @override
  List<Object?> get props => [
    allItems,
    filteredItems,
    searchQuery,
    selectedCategory,
  ];

  InventoryLoaded copyWith({
    List<InventoryItem>? allItems,
    List<InventoryItem>? filteredItems,
    String? searchQuery,
    String? selectedCategory,
  }) {
    return InventoryLoaded(
      allItems: allItems ?? this.allItems,
      filteredItems: filteredItems ?? this.filteredItems,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
    );
  }
}

class InventoryError extends InventoryState {
  final String message;

  const InventoryError(this.message);

  @override
  List<Object?> get props => [message];
}

// --- Bloc ---
class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  final InventoryRepository repository;

  InventoryBloc({InventoryRepository? repository})
    : repository = repository ?? InventoryRepository(),
      super(InventoryInitial()) {
    on<LoadInventoryRequested>(_onLoadInventory);
    on<SearchInventory>(_onSearchInventory);
    on<FilterInventoryByCategory>(_onFilterByCategory);
  }

  void _onLoadInventory(
    LoadInventoryRequested event,
    Emitter<InventoryState> emit,
  ) async {
    emit(InventoryLoading());
    try {
      final items = await repository.getInventory();
      emit(InventoryLoaded(allItems: items, filteredItems: items));
    } catch (e) {
      emit(InventoryError(e.toString()));
    }
  }

  void _onSearchInventory(SearchInventory event, Emitter<InventoryState> emit) {
    if (state is InventoryLoaded) {
      final currentState = state as InventoryLoaded;
      final query = event.query.toLowerCase();

      final filtered = _filterItems(
        currentState.allItems,
        query,
        currentState.selectedCategory,
      );

      emit(currentState.copyWith(filteredItems: filtered, searchQuery: query));
    }
  }

  void _onFilterByCategory(
    FilterInventoryByCategory event,
    Emitter<InventoryState> emit,
  ) {
    if (state is InventoryLoaded) {
      final currentState = state as InventoryLoaded;
      final category = event.category;

      final filtered = _filterItems(
        currentState.allItems,
        currentState.searchQuery,
        category,
      );

      emit(
        currentState.copyWith(
          filteredItems: filtered,
          selectedCategory: category,
        ),
      );
    }
  }

  List<InventoryItem> _filterItems(
    List<InventoryItem> items,
    String query,
    String category,
  ) {
    return items.where((item) {
      final matchesCategory = category == 'All' || item.category == category;
      final matchesQuery =
          item.name.toLowerCase().contains(query) ||
          item.sku.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
  }
}
