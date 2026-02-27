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

  const CustomerLoaded({
    required this.allCustomers,
    required this.filteredCustomers,
    this.searchQuery = '',
  });

  @override
  List<Object?> get props => [allCustomers, filteredCustomers, searchQuery];

  CustomerLoaded copyWith({
    List<Customer>? allCustomers,
    List<Customer>? filteredCustomers,
    String? searchQuery,
  }) {
    return CustomerLoaded(
      allCustomers: allCustomers ?? this.allCustomers,
      filteredCustomers: filteredCustomers ?? this.filteredCustomers,
      searchQuery: searchQuery ?? this.searchQuery,
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
      final filtered = currentState.allCustomers.where((c) {
        return c.name.toLowerCase().contains(query) ||
            c.phone.contains(query) ||
            c.model.toLowerCase().contains(query);
      }).toList();

      emit(
        currentState.copyWith(filteredCustomers: filtered, searchQuery: query),
      );
    }
  }
}
