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

class AddInventoryCategory extends InventoryEvent {
  final String categoryName;

  const AddInventoryCategory(this.categoryName);

  @override
  List<Object?> get props => [categoryName];
}

class AddInventoryItem extends InventoryEvent {
  final InventoryItem item;
  const AddInventoryItem(this.item);
  @override
  List<Object?> get props => [item];
}

class UpdateInventoryItem extends InventoryEvent {
  final InventoryItem item;
  const UpdateInventoryItem(this.item);
  @override
  List<Object?> get props => [item];
}

class DeleteInventoryItem extends InventoryEvent {
  final String itemId;
  const DeleteInventoryItem(this.itemId);
  @override
  List<Object?> get props => [itemId];
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
  final List<String> categories;
  final String searchQuery;
  final String selectedCategory;

  const InventoryLoaded({
    required this.allItems,
    required this.filteredItems,
    required this.categories,
    this.searchQuery = '',
    this.selectedCategory = 'All',
  });

  @override
  List<Object?> get props => [
    allItems,
    filteredItems,
    categories,
    searchQuery,
    selectedCategory,
  ];

  InventoryLoaded copyWith({
    List<InventoryItem>? allItems,
    List<InventoryItem>? filteredItems,
    List<String>? categories,
    String? searchQuery,
    String? selectedCategory,
  }) {
    return InventoryLoaded(
      allItems: allItems ?? this.allItems,
      filteredItems: filteredItems ?? this.filteredItems,
      categories: categories ?? this.categories,
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
    on<AddInventoryCategory>(_onAddInventoryCategory);
    on<AddInventoryItem>(_onAddInventoryItem);
    on<UpdateInventoryItem>(_onUpdateInventoryItem);
    on<DeleteInventoryItem>(_onDeleteInventoryItem);
  }

  void _onLoadInventory(
    LoadInventoryRequested event,
    Emitter<InventoryState> emit,
  ) async {
    emit(InventoryLoading());
    try {
      final items = await repository.getInventory();
      final categories = await repository.getCategories();
      emit(
        InventoryLoaded(
          allItems: items,
          filteredItems: items,
          categories: categories,
        ),
      );
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
          selectedCategory: category == 'All' ||
                  currentState.categories.contains(category)
              ? category
              : 'All',
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
          item.name.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  void _onAddInventoryCategory(
    AddInventoryCategory event,
    Emitter<InventoryState> emit,
  ) async {
    try {
      await repository.addCategory(event.categoryName);
      final items = await repository.getInventory();
      final categories = await repository.getCategories();

      final currentState = state is InventoryLoaded
          ? state as InventoryLoaded
          : null;
      final selectedCategory = event.categoryName.trim().isEmpty
          ? (currentState?.selectedCategory ?? 'All')
          : event.categoryName.trim();
      final query = currentState?.searchQuery ?? '';
      final effectiveCategory = categories.contains(selectedCategory)
          ? selectedCategory
          : 'All';

      emit(
        InventoryLoaded(
          allItems: items,
          filteredItems: _filterItems(items, query, effectiveCategory),
          categories: categories,
          searchQuery: query,
          selectedCategory: effectiveCategory,
        ),
      );
    } catch (e) {
      emit(InventoryError(e.toString()));
    }
  }

  void _onAddInventoryItem(
    AddInventoryItem event,
    Emitter<InventoryState> emit,
  ) async {
    try {
      await repository.addInventoryItem(event.item);
      add(LoadInventoryRequested());
    } catch (e) {
      emit(InventoryError(e.toString()));
    }
  }

  void _onUpdateInventoryItem(
    UpdateInventoryItem event,
    Emitter<InventoryState> emit,
  ) async {
    try {
      await repository.updateInventoryItem(event.item);
      add(LoadInventoryRequested());
    } catch (e) {
      emit(InventoryError(e.toString()));
    }
  }

  void _onDeleteInventoryItem(
    DeleteInventoryItem event,
    Emitter<InventoryState> emit,
  ) async {
    try {
      await repository.deleteInventoryItem(event.itemId);
      add(LoadInventoryRequested());
    } catch (e) {
      emit(InventoryError(e.toString()));
    }
  }
}
