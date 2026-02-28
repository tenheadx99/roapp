import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/customer.dart';
import '../repositories/customer_repository.dart';

// --- Events ---
abstract class CustomerEvent extends Equatable {
  const CustomerEvent();

  @override
  List<Object?> get props => [];
}

class LoadCustomersRequested extends CustomerEvent {}

class SearchCustomers extends CustomerEvent {
  final String query;

  const SearchCustomers(this.query);

  @override
  List<Object?> get props => [query];
}

class FilterCustomersRequested extends CustomerEvent {
  final String filterOption;

  const FilterCustomersRequested(this.filterOption);

  @override
  List<Object?> get props => [filterOption];
}

class AddCustomer extends CustomerEvent {
  final Customer customer;
  const AddCustomer(this.customer);
  @override
  List<Object?> get props => [customer];
}

class UpdateCustomer extends CustomerEvent {
  final Customer customer;
  const UpdateCustomer(this.customer);
  @override
  List<Object?> get props => [customer];
}

class DeleteCustomer extends CustomerEvent {
  final String customerId;
  const DeleteCustomer(this.customerId);
  @override
  List<Object?> get props => [customerId];
}

// --- States ---
abstract class CustomerState extends Equatable {
  const CustomerState();

  @override
  List<Object?> get props => [];
}

class CustomerInitial extends CustomerState {}

class CustomerLoading extends CustomerState {}

class CustomerLoaded extends CustomerState {
  final List<Customer> allCustomers;
  final List<Customer> filteredCustomers;
  final String searchQuery;
  final String currentFilter;

  const CustomerLoaded({
    required this.allCustomers,
    required this.filteredCustomers,
    this.searchQuery = '',
    this.currentFilter = 'All Records',
  });

  @override
  List<Object?> get props => [
    allCustomers,
    filteredCustomers,
    searchQuery,
    currentFilter,
  ];

  CustomerLoaded copyWith({
    List<Customer>? allCustomers,
    List<Customer>? filteredCustomers,
    String? searchQuery,
    String? currentFilter,
  }) {
    return CustomerLoaded(
      allCustomers: allCustomers ?? this.allCustomers,
      filteredCustomers: filteredCustomers ?? this.filteredCustomers,
      searchQuery: searchQuery ?? this.searchQuery,
      currentFilter: currentFilter ?? this.currentFilter,
    );
  }
}

class CustomerError extends CustomerState {
  final String message;

  const CustomerError(this.message);

  @override
  List<Object?> get props => [message];
}

// --- Bloc ---
class CustomerBloc extends Bloc<CustomerEvent, CustomerState> {
  final CustomerRepository repository;

  CustomerBloc({CustomerRepository? repository})
    : repository = repository ?? CustomerRepository(),
      super(CustomerInitial()) {
    on<LoadCustomersRequested>(_onLoadCustomers);
    on<SearchCustomers>(_onSearchCustomers);
    on<FilterCustomersRequested>(_onFilterCustomers);
    on<AddCustomer>(_onAddCustomer);
    on<UpdateCustomer>(_onUpdateCustomer);
    on<DeleteCustomer>(_onDeleteCustomer);
  }

  void _onLoadCustomers(
    LoadCustomersRequested event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading());

    try {
      final customers = await repository.getCustomers();
      emit(
        CustomerLoaded(allCustomers: customers, filteredCustomers: customers),
      );
    } catch (e) {
      emit(CustomerError(e.toString()));
    }
  }

  void _onSearchCustomers(SearchCustomers event, Emitter<CustomerState> emit) {
    if (state is CustomerLoaded) {
      final currentState = state as CustomerLoaded;
      final query = event.query.toLowerCase();

      final filtered = _applyFilters(
        currentState.allCustomers,
        query,
        currentState.currentFilter,
      );

      emit(
        currentState.copyWith(filteredCustomers: filtered, searchQuery: query),
      );
    }
  }

  void _onFilterCustomers(
    FilterCustomersRequested event,
    Emitter<CustomerState> emit,
  ) {
    if (state is CustomerLoaded) {
      final currentState = state as CustomerLoaded;

      final filtered = _applyFilters(
        currentState.allCustomers,
        currentState.searchQuery,
        event.filterOption,
      );

      emit(
        currentState.copyWith(
          filteredCustomers: filtered,
          currentFilter: event.filterOption,
        ),
      );
    }
  }

  List<Customer> _applyFilters(
    List<Customer> customers,
    String query,
    String filterOption,
  ) {
    return customers.where((c) {
      final matchesQuery =
          query.isEmpty ||
          c.name.toLowerCase().contains(query) ||
          c.phone.contains(query) ||
          c.model.toLowerCase().contains(query);

      bool matchesFilter = true;
      if (filterOption == 'Service Due') {
        matchesFilter = c.status == 'Service Due';
      } else if (filterOption == 'Area: West Delhi') {
        matchesFilter = c.area == 'West Delhi';
      }

      return matchesQuery && matchesFilter;
    }).toList();
  }

  void _onAddCustomer(AddCustomer event, Emitter<CustomerState> emit) async {
    try {
      await repository.addCustomer(event.customer);
      add(LoadCustomersRequested());
    } catch (e) {
      emit(CustomerError(e.toString()));
    }
  }

  void _onUpdateCustomer(
    UpdateCustomer event,
    Emitter<CustomerState> emit,
  ) async {
    try {
      await repository.updateCustomer(event.customer);
      add(LoadCustomersRequested());
    } catch (e) {
      emit(CustomerError(e.toString()));
    }
  }

  void _onDeleteCustomer(
    DeleteCustomer event,
    Emitter<CustomerState> emit,
  ) async {
    try {
      await repository.deleteCustomer(event.customerId);
      add(LoadCustomersRequested());
    } catch (e) {
      emit(CustomerError(e.toString()));
    }
  }
}
