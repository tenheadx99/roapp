import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/semi_bold_text_view.dart';
import '../../../widgets/sub_regular_text.dart';
import '../../supplier/screens/supplier_directory_screen.dart';
import '../bloc/inventory_bloc.dart';
import '../models/inventory_item.dart';
import 'add_inventory_item_bottom_sheet.dart';
import '../../../widgets/responsive_layout.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => InventoryBloc()..add(LoadInventoryRequested()),
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: const Color(0xFFF5F7F8),
            appBar: AppBar(
              title: const Text(
                'Parts & Filters',
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
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SupplierDirectoryScreen(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Manage Suppliers',
                        style: TextStyle(
                          color: Color(0xFF007FFF),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            body: const ResponsiveLayout(
              mobile: _MobileInventoryView(),
              desktop: _DesktopInventoryView(),
            ),
          );
        },
      ),
    );
  }
}

class _MobileInventoryView extends StatelessWidget {
  const _MobileInventoryView();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              _buildAddActions(context),
              const SizedBox(height: 16),
              _buildSearchField(context),
              const SizedBox(height: 12),
              _buildCategoryFilters(context),
            ],
          ),
        ),
        Expanded(child: _buildInventoryList(context, isDesktop: false)),
      ],
    );
  }
}

class _DesktopInventoryView extends StatelessWidget {
  const _DesktopInventoryView();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Sidebar for filters
        Container(
          width: 280,
          color: Colors.white,
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SemiBoldTextView(text: 'Actions', fontSize: 18),
              const SizedBox(height: 16),
              _buildAddActions(context),
              const SizedBox(height: 32),
              const SemiBoldTextView(text: 'Search', fontSize: 18),
              const SizedBox(height: 16),
              _buildSearchField(context),
              const SizedBox(height: 32),
              const SemiBoldTextView(text: 'Categories', fontSize: 18),
              const SizedBox(height: 16),
              Expanded(child: _buildCategoryFilters(context, isVertical: true)),
            ],
          ),
        ),
        const VerticalDivider(width: 1, color: Color(0xFFE2E8F0)),
        // Main content area
        Expanded(
          child: Container(
            color: const Color(0xFFF8FAFC),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SemiBoldTextView(text: 'Stock Items', fontSize: 20),
                const SizedBox(height: 24),
                Expanded(child: _buildInventoryList(context, isDesktop: true)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

Widget _buildAddActions(BuildContext context) {
  return Row(
    children: [
      Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF007FFF).withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.upload_outlined,
          color: Color(0xFF007FFF),
          size: 20,
        ),
      ),
      const SizedBox(width: 8),
      GestureDetector(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (builderContext) => BlocProvider.value(
              value: context.read<InventoryBloc>(),
              child: const AddInventoryItemBottomSheet(),
            ),
          );
        },
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF007FFF),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF007FFF).withOpacity(0.2),
                blurRadius: 8,
              ),
            ],
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 20),
        ),
      ),
    ],
  );
}

Widget _buildSearchField(BuildContext context) {
  return BlocBuilder<InventoryBloc, InventoryState>(
    builder: (context, state) {
      return CustomTextField(
        hintText: "Search item name...",
        prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
        onChanged: (val) {
          context.read<InventoryBloc>().add(SearchInventory(val));
        },
      );
    },
  );
}

Widget _buildCategoryFilters(BuildContext context, {bool isVertical = false}) {
  return BlocBuilder<InventoryBloc, InventoryState>(
    builder: (context, state) {
      String currentCategory = 'All';
      if (state is InventoryLoaded) {
        currentCategory = state.selectedCategory;
      }

      final categories = ['All', 'Pumps', 'Membranes', 'Filters', 'UV Lamps'];

      if (isVertical) {
        return ListView.separated(
          itemCount: categories.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final cat = categories[index];
            final isSelected = cat == currentCategory;
            return GestureDetector(
              onTap: () {
                context.read<InventoryBloc>().add(
                  FilterInventoryByCategory(cat),
                );
              },
              child: _buildCategoryChip(
                cat,
                isSelected: isSelected,
                isFullWidth: true,
              ),
            );
          },
        );
      }

      return SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          separatorBuilder: (context, index) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final cat = categories[index];
            final isSelected = cat == currentCategory;
            return GestureDetector(
              onTap: () {
                context.read<InventoryBloc>().add(
                  FilterInventoryByCategory(cat),
                );
              },
              child: _buildCategoryChip(cat, isSelected: isSelected),
            );
          },
        ),
      );
    },
  );
}

Widget _buildInventoryList(BuildContext context, {required bool isDesktop}) {
  return BlocBuilder<InventoryBloc, InventoryState>(
    builder: (context, state) {
      if (state is InventoryLoading || state is InventoryInitial) {
        return const Center(child: CircularProgressIndicator());
      } else if (state is InventoryError) {
        return Center(child: Text(state.message));
      } else if (state is InventoryLoaded) {
        final items = state.filteredItems;
        if (items.isEmpty) {
          return const Center(child: Text('No inventory items found.'));
        }

        if (isDesktop) {
          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 400,
              mainAxisExtent: 160,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return _InventoryCard(item: items[index]);
            },
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return _InventoryCard(item: items[index]);
          },
        );
      }
      return const SizedBox();
    },
  );
}

Widget _buildCategoryChip(
  String label, {
  bool isSelected = false,
  bool isFullWidth = false,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: isSelected ? const Color(0xFF007FFF) : Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0),
      ),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isSelected ? Colors.white : const Color(0xFF475569),
      ),
      textAlign: isFullWidth ? TextAlign.left : TextAlign.center,
    ),
  );
}

class _InventoryCard extends StatelessWidget {
  final InventoryItem item;

  const _InventoryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isLowStock = item.stock <= item.lowStockThreshold;

    return Container(
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
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SemiBoldTextView(text: item.name, fontSize: 16),
                    SubRegularText(
                      text: 'MRP: \$${item.mrp.toStringAsFixed(2)} | Supplier: ${item.supplier}',
                    ),
                  ],
                ),
              ),
              Text(
                '\$${item.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Color(0xFF007FFF),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isLowStock
                      ? Colors.red.shade50
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      isLowStock
                          ? Icons.warning_amber_rounded
                          : Icons.inventory_2_outlined,
                      size: 16,
                      color: isLowStock
                          ? Colors.red.shade600
                          : const Color(0xFF475569),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${item.stock} in Stock ${isLowStock ? '(Low)' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isLowStock
                            ? Colors.red.shade600
                            : const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (builderContext) => BlocProvider.value(
                      value: context.read<InventoryBloc>(),
                      child: AddInventoryItemBottomSheet(itemToEdit: item),
                    ),
                  );
                },
                child: Row(
                  children: [
                    const Text(
                      'Details',
                      style: TextStyle(
                        color: Color(0xFF007FFF),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: Color(0xFF007FFF),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
