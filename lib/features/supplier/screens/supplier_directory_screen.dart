import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_strings.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/regular_text_view.dart';
import '../../../widgets/semi_bold_text_view.dart';
import '../../../widgets/sub_regular_text.dart';
import '../../../widgets/responsive_layout.dart';
import '../bloc/supplier_bloc.dart';
import '../models/supplier.dart';
import 'add_supplier_bottom_sheet.dart';

class SupplierDirectoryScreen extends StatelessWidget {
  const SupplierDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SupplierBloc()..add(LoadSuppliersRequested()),
      child: Builder(
        builder: (context) {
          return ResponsiveLayout(
            mobile: _MobileSupplierView(),
            desktop: _DesktopSupplierView(),
          );
        },
      ),
    );
  }
}

class _MobileSupplierView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          _buildSearchAndFilters(context),
          const Expanded(child: _SupplierList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSupplier(context),
        backgroundColor: const Color(0xFF007FFF),
        icon: const Icon(Icons.add, size: 20, color: Colors.white),
        label: const SemiBoldTextView(
          text: AppStrings.addSupplier,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _DesktopSupplierView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar / Sidebar Navigation could go here, but for now just the filter part
          Container(
            width: 300,
            color: Colors.white,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SemiBoldTextView(
                      text: AppStrings.supplierDirectory,
                      fontSize: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                CustomTextField(
                  hintText: AppStrings.searchSuppliersHint,
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF94A3B8),
                  ),
                  onChanged: (val) {
                    context.read<SupplierBloc>().add(SearchSuppliers(val));
                  },
                ),
                const SizedBox(height: 24),
                const SemiBoldTextView(text: 'Categories', fontSize: 16),
                const SizedBox(height: 12),
                Expanded(
                  child: BlocBuilder<SupplierBloc, SupplierState>(
                    builder: (context, state) {
                      String selectedCategory = AppStrings.allSuppliers;
                      if (state is SupplierLoaded) {
                        selectedCategory = state.selectedCategory;
                      }
                      return ListView(
                        children: [
                          _buildFilterItem(
                            context,
                            AppStrings.allSuppliers,
                            selectedCategory == AppStrings.allSuppliers,
                          ),
                          _buildFilterItem(
                            context,
                            AppStrings.membranes,
                            selectedCategory == AppStrings.membranes,
                          ),
                          _buildFilterItem(
                            context,
                            AppStrings.pumps,
                            selectedCategory == AppStrings.pumps,
                          ),
                          _buildFilterItem(
                            context,
                            AppStrings.filters,
                            selectedCategory == AppStrings.filters,
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddSupplier(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007FFF),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const SemiBoldTextView(
                      text: AppStrings.addSupplier,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  color: Colors.transparent,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SemiBoldTextView(
                        text: 'Suppliers Overview',
                        fontSize: 24,
                      ),
                    ],
                  ),
                ),
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: _SupplierList(isDesktop: true),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterItem(BuildContext context, String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: () =>
            context.read<SupplierBloc>().add(FilterSuppliersByCategory(label)),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF007FFF).withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.check_circle : Icons.circle_outlined,
                size: 18,
                color: isSelected
                    ? const Color(0xFF007FFF)
                    : const Color(0xFF94A3B8),
              ),
              const SizedBox(width: 12),
              RegularTextView(
                text: label,
                color: isSelected
                    ? const Color(0xFF007FFF)
                    : const Color(0xFF475569),
                fontSize: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildSearchAndFilters(BuildContext context) {
  return Container(
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
              prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
              onChanged: (val) {
                context.read<SupplierBloc>().add(SearchSuppliers(val));
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
                    isSelected: selectedCategory == AppStrings.allSuppliers,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    context,
                    AppStrings.membranes,
                    isSelected: selectedCategory == AppStrings.membranes,
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
                    isSelected: selectedCategory == AppStrings.filters,
                  ),
                ],
              ),
            ),
          ],
        );
      },
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

class _SupplierList extends StatelessWidget {
  final bool isDesktop;
  const _SupplierList({this.isDesktop = false});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SupplierBloc, SupplierState>(
      builder: (context, state) {
        if (state is SupplierLoading || state is SupplierInitial) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is SupplierError) {
          return Center(child: Text(state.message));
        } else if (state is SupplierLoaded) {
          final suppliers = state.filteredSuppliers;
          if (suppliers.isEmpty) {
            return const Center(
              child: RegularTextView(text: AppStrings.noSuppliersFound),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16, isDesktop ? 0 : 16, 16, 8),
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
                child: RefreshIndicator(
                  onRefresh: () async => context
                      .read<SupplierBloc>()
                      .add(LoadSuppliersRequested()),
                  child: isDesktop
                    ? GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 400,
                              childAspectRatio: 1.2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                        itemCount: suppliers.length,
                        itemBuilder: (context, index) =>
                            _SupplierCard(supplier: suppliers[index]),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ).copyWith(bottom: 80),
                        itemCount: suppliers.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) =>
                            _SupplierCard(supplier: suppliers[index]),
                      ),
                ),
              ),
            ],
          );
        }
        return const SizedBox();
      },
    );
  }
}

void _showAddSupplier(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: context.read<SupplierBloc>(),
      child: const AddSupplierBottomSheet(),
    ),
  );
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
                      if (supplier.phone.isNotEmpty ||
                          supplier.email.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: SubRegularText(
                            text: [
                              if (supplier.phone.isNotEmpty) supplier.phone,
                              if (supplier.email.isNotEmpty) supplier.email,
                            ].join(' • '),
                          ),
                        ),
                    ],
                  ),
                ),
                _buildActionButtons(context),
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
                  onTap: () => _showProcurementDialog(context),
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

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: () {
            final bloc = context.read<SupplierBloc>();
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => BlocProvider.value(
                value: bloc,
                child: AddSupplierBottomSheet(supplierToEdit: supplier),
              ),
            );
          },
          child: _ActionButton(
            icon: Icons.edit_outlined,
            backgroundColor: Colors.blue.shade50,
            iconColor: Colors.blue.shade600,
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: () => _launchContact(
            context,
            supplier.phone,
            Uri(scheme: 'tel', path: supplier.phone),
            'Phone number missing for this supplier.',
          ),
          child: _ActionButton(
            icon: Icons.phone_outlined,
            backgroundColor: const Color(0xFF007FFF).withOpacity(0.1),
            iconColor: const Color(0xFF007FFF),
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: () => _launchContact(
            context,
            supplier.email,
            Uri(
              scheme: 'mailto',
              path: supplier.email,
              queryParameters: {'subject': 'RO Parts Requirement'},
            ),
            'Email address missing for this supplier.',
          ),
          child: _ActionButton(
            icon: Icons.chat_bubble_outline,
            backgroundColor: Colors.green.shade50,
            iconColor: Colors.green.shade600,
          ),
        ),
      ],
    );
  }

  Future<void> _launchContact(
    BuildContext context,
    String value,
    Uri uri,
    String fallbackMessage,
  ) async {
    if (value.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(fallbackMessage)));
      return;
    }

    final launched = await launchUrl(uri);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open the selected contact action.'),
        ),
      );
    }
  }

  void _showProcurementDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          supplier.activePOs > 0 ? 'Purchase Orders' : 'Create Purchase Order',
        ),
        content: Text(
          supplier.activePOs > 0
              ? '${supplier.name} currently has ${supplier.activePOs} active purchase orders. Create another one for urgent replenishment if needed.'
              : 'Create a new purchase order for ${supplier.name} and track it from the supplier directory.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<SupplierBloc>().add(
                UpdateSupplier(
                  supplier.copyWith(activePOs: supplier.activePOs + 1),
                ),
              );
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Purchase order created for ${supplier.name}. Active POs: ${supplier.activePOs + 1}',
                  ),
                ),
              );
            },
            child: const Text('Create PO'),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;

  const _ActionButton({
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      child: Icon(icon, color: iconColor, size: 18),
    );
  }
}
