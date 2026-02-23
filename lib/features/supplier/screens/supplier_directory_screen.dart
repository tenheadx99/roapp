import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/regular_text_view.dart';
import '../../../widgets/semi_bold_text_view.dart';
import '../../../widgets/sub_regular_text.dart';
import '../bloc/supplier_bloc.dart';
import '../models/supplier.dart';

class SupplierDirectoryScreen extends StatelessWidget {
  const SupplierDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SupplierBloc()..add(LoadSuppliersRequested()),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7F8),
        appBar: AppBar(
          title: const SemiBoldTextView(
            text: AppStrings.supplierDirectory,
            color: Colors.black,
            fontSize: 16,
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: BlocBuilder<SupplierBloc, SupplierState>(
                builder: (context, state) {
                  String selectedCategory = AppStrings.allSuppliers;
                  if (state is SupplierLoaded) {
                    selectedCategory = state.selectedCategory;
                  }

                  return Column(
                    children: [
                      CustomTextField(
                        hintText: AppStrings.searchSuppliersHint,
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFF94A3B8),
                        ),
                        onChanged: (val) {
                          context.read<SupplierBloc>().add(
                            SearchSuppliers(val),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip(
                              context,
                              AppStrings.allSuppliers,
                              isSelected:
                                  selectedCategory == AppStrings.allSuppliers,
                            ),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                              context,
                              AppStrings.membranes,
                              isSelected:
                                  selectedCategory == AppStrings.membranes,
                            ),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                              context,
                              AppStrings.pumps,
                              isSelected: selectedCategory == AppStrings.pumps,
                            ),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                              context,
                              AppStrings.filters,
                              isSelected:
                                  selectedCategory == AppStrings.filters,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Expanded(
              child: BlocBuilder<SupplierBloc, SupplierState>(
                builder: (context, state) {
                  if (state is SupplierLoading || state is SupplierInitial) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is SupplierError) {
                    return Center(child: Text(state.message));
                  } else if (state is SupplierLoaded) {
                    final suppliers = state.filteredSuppliers;
                    if (suppliers.isEmpty) {
                      return const Center(
                        child: RegularTextView(
                          text: AppStrings.noSuppliersFound,
                        ),
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            '${AppStrings.verifiedPartners} (${suppliers.length})',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF94A3B8),
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ).copyWith(bottom: 80),
                            itemCount: suppliers.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              return _SupplierCard(supplier: suppliers[index]);
                            },
                          ),
                        ),
                      ],
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(AppStrings.comingSoon)),
            );
          },
          backgroundColor: const Color(0xFF007FFF),
          icon: const Icon(Icons.add, size: 20),
          label: const SemiBoldTextView(
            text: AppStrings.newPO,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    String label, {
    bool isSelected = false,
  }) {
    return GestureDetector(
      onTap: () {
        context.read<SupplierBloc>().add(FilterSuppliersByCategory(label));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF007FFF) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }
}

class _SupplierCard extends StatelessWidget {
  final Supplier supplier;

  const _SupplierCard({required this.supplier});

  @override
  Widget build(BuildContext context) {
    final bool isInactive = supplier.status == 'inactive';

    return Opacity(
      opacity: isInactive ? 0.8 : 1.0,
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: SemiBoldTextView(
                              text: supplier.name,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isInactive
                                  ? Colors.grey.shade300
                                  : Colors.green.shade500,
                              border: Border.all(
                                color: isInactive
                                    ? Colors.transparent
                                    : Colors.green.shade100,
                                width: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      SubRegularText(
                        text: '${supplier.contactPerson} • ${supplier.city}',
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text(AppStrings.comingSoon)),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF007FFF).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.phone_outlined,
                          color: Color(0xFF007FFF),
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text(AppStrings.comingSoon)),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.chat_bubble_outline,
                          color: Colors.green.shade600,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...supplier.specialties.map(
                  (spec) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      spec.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFF8FAFC), height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      supplier.activePOs > 0
                          ? Icons.inventory_2_outlined
                          : Icons.refresh_outlined,
                      size: 14,
                      color: const Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      supplier.activePOs > 0
                          ? '${supplier.activePOs} ${AppStrings.activePOs}'
                          : '${AppStrings.lastOrder} 2mo ago',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text(AppStrings.comingSoon)),
                    );
                  },
                  child: Row(
                    children: [
                      Text(
                        supplier.activePOs > 0
                            ? AppStrings.viewPurchaseOrders
                            : AppStrings.reorder,
                        style: const TextStyle(
                          color: Color(0xFF007FFF),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: Color(0xFF007FFF),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
