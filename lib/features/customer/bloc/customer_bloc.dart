import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/customer.dart';

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
  CustomerBloc() : super(CustomerInitial()) {
    on<LoadCustomersRequested>(_onLoadCustomers);
    on<SearchCustomers>(_onSearchCustomers);
  }

  void _onLoadCustomers(
    LoadCustomersRequested event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading());

    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Dummy data from React constants
    final customers = [
      const Customer(
        id: '1',
        name: 'Arjun Sharma',
        phone: '+91 98765 43210',
        model: 'Kent Grand+ RO (12L)',
        status: 'Service Due',
        lastService: '15 Oct 2023',
        area: 'West Delhi',
      ),
      const Customer(
        id: '2',
        name: 'Priya Mehra',
        phone: '+91 88223 11445',
        model: 'Pureit Copper+ Mineral',
        status: 'Operational',
        lastService: '02 Jan 2024',
        area: 'Rohini',
      ),
      const Customer(
        id: '3',
        name: 'Vikram Singh',
        phone: '+91 70012 33490',
        model: 'Aquaguard Ritz RO+UV',
        status: 'AMC Plan',
        lastService: '18 Dec 2023',
        area: 'West Delhi',
      ),
      const Customer(
        id: '4',
        name: 'Sneha Kapoor',
        phone: '+91 99112 22334',
        model: 'Livpure Bolt (RO+UF)',
        status: 'Pending Install',
        lastService: 'New Customer',
        area: 'Rohini',
      ),
    ];

    emit(CustomerLoaded(allCustomers: customers, filteredCustomers: customers));
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
