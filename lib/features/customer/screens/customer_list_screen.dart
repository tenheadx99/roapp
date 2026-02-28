import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/semi_bold_text_view.dart';
import '../../../widgets/sub_regular_text.dart';
import '../bloc/customer_bloc.dart';
import '../models/customer.dart';
import 'add_customer_bottom_sheet.dart';
import 'customer_profile_screen.dart';

class CustomerListScreen extends StatelessWidget {
  const CustomerListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CustomerBloc()..add(LoadCustomersRequested()),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7F8),
        appBar: AppBar(
          title: const Text(
            'Customer Database',
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(), // Placeholder
          ),
        ),
        body: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  BlocBuilder<CustomerBloc, CustomerState>(
                    builder: (context, state) {
                      return CustomTextField(
                        hintText: "Search by name, contact, or model...",
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFF94A3B8),
                        ),
                        onChanged: (val) {
                          context.read<CustomerBloc>().add(
                            SearchCustomers(val),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: BlocBuilder<CustomerBloc, CustomerState>(
                      builder: (context, state) {
                        String currentFilter = 'All Records';
                        if (state is CustomerLoaded) {
                          currentFilter = state.currentFilter;
                        }
                        return Row(
                          children: [
                            _buildFilterChip(
                              'All Records',
                              icon: Icons.filter_list,
                              isSelected: currentFilter == 'All Records',
                              onTap: () => context.read<CustomerBloc>().add(
                                const FilterCustomersRequested('All Records'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                              'Service Due',
                              isSelected: currentFilter == 'Service Due',
                              onTap: () => context.read<CustomerBloc>().add(
                                const FilterCustomersRequested('Service Due'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                              'Area: West Delhi',
                              isSelected: currentFilter == 'Area: West Delhi',
                              onTap: () => context.read<CustomerBloc>().add(
                                const FilterCustomersRequested(
                                  'Area: West Delhi',
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: BlocBuilder<CustomerBloc, CustomerState>(
                builder: (context, state) {
                  if (state is CustomerLoading || state is CustomerInitial) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is CustomerError) {
                    return Center(child: Text(state.message));
                  } else if (state is CustomerLoaded) {
                    final customers = state.filteredCustomers;
                    if (customers.isEmpty) {
                      return const Center(child: Text('No customers found.'));
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: customers.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _CustomerCard(
                          customer: customers[index],
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => CustomerProfileScreen(
                                  customer: customers[index],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
        floatingActionButton: Builder(
          builder: (context) {
            return FloatingActionButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => BlocProvider.value(
                    value: context.read<CustomerBloc>(),
                    child: const AddCustomerBottomSheet(),
                  ),
                );
              },
              backgroundColor: const Color(0xFF007FFF),
              child: const Icon(
                Icons.person_add,
                size: 28,
                color: Colors.white,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String label, {
    IconData? icon,
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF007FFF) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final Customer customer;
  final VoidCallback onTap;

  const _CustomerCard({required this.customer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Color statusBgColor;
    Color statusTextColor;
    switch (customer.status) {
      case 'Service Due':
        statusBgColor = Colors.red.shade100;
        statusTextColor = Colors.red.shade600;
        break;
      case 'Operational':
        statusBgColor = Colors.green.shade100;
        statusTextColor = Colors.green.shade600;
        break;
      case 'AMC Plan':
        statusBgColor = const Color(0xFF007FFF).withOpacity(0.1);
        statusTextColor = const Color(0xFF007FFF);
        break;
      default:
        statusBgColor = Colors.amber.shade100;
        statusTextColor = Colors.amber.shade600;
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SemiBoldTextView(text: customer.name, fontSize: 16),
                      SubRegularText(text: customer.phone),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    customer.status.toUpperCase(),
                    style: TextStyle(
                      color: statusTextColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      fontStyle: customer.status == 'Service Due'
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.water_drop_outlined,
                  color: Color(0xFF007FFF),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  customer.model,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF334155),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: Color(0xFFF8FAFC), height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'LAST SERVICE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF94A3B8),
                        letterSpacing: -0.5,
                      ),
                    ),
                    SemiBoldTextView(
                      text: customer.lastService,
                      fontSize: 14,
                      color: const Color(0xFF475569),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF007FFF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.phone_outlined,
                        color: Color(0xFF007FFF),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF007FFF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.history,
                        color: Color(0xFF007FFF),
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
