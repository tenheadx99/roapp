import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../customer/bloc/customer_bloc.dart';
import '../../customer/models/customer.dart';
import '../../customer/repositories/customer_repository.dart';
import '../../customer/screens/customer_list_screen.dart';
import '../../customer/screens/customer_profile_screen.dart';
import '../../dispatch/repositories/dispatch_repository.dart';
import '../../dispatch/screens/dispatch_hub_screen.dart';
import '../../inventory/repositories/inventory_repository.dart';
import '../../inventory/screens/inventory_screen.dart';
import '../../supplier/repositories/supplier_repository.dart';
import '../../supplier/screens/supplier_directory_screen.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  List<_SearchResult> _results = const [];
  List<_SearchResult> _allResults = const [];

  @override
  void initState() {
    super.initState();
    _loadResults();
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilter);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadResults() async {
    setState(() => _isLoading = true);
    final customerRepo = CustomerRepository();
    final dispatchRepo = DispatchRepository();
    final supplierRepo = SupplierRepository();
    final inventoryRepo = InventoryRepository();

    final customers = await customerRepo.getCustomers();
    final requests = await dispatchRepo.getServiceRequests();
    final suppliers = await supplierRepo.getSuppliers();
    final inventory = await inventoryRepo.getInventory();

    final results = <_SearchResult>[
      ...customers.map(
        (customer) => _SearchResult(
          type: 'Customer',
          title: customer.name,
          subtitle: '${customer.phone} • ${customer.area} • ${customer.model}',
          payload: customer,
        ),
      ),
      ...requests.map(
        (request) => _SearchResult(
          type: 'Dispatch',
          title: request.customerName,
          subtitle:
              '${request.type} • ${request.address} • ${request.statusLabel}',
          payload: request.id,
        ),
      ),
      ...suppliers.map(
        (supplier) => _SearchResult(
          type: 'Supplier',
          title: supplier.name,
          subtitle: '${supplier.city} • ${supplier.contactPerson}',
          payload: supplier.id,
        ),
      ),
      ...inventory.map(
        (item) => _SearchResult(
          type: 'Inventory',
          title: item.name,
          subtitle: '${item.category} • Stock ${item.stock} • ${item.supplier}',
          payload: item.id,
        ),
      ),
    ];

    if (!mounted) return;
    setState(() {
      _allResults = results;
      _results = results;
      _isLoading = false;
    });
  }

  void _applyFilter() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _results = _allResults);
      return;
    }
    setState(() {
      _results = _allResults.where((result) {
        return result.title.toLowerCase().contains(query) ||
            result.subtitle.toLowerCase().contains(query) ||
            result.type.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _openResult(_SearchResult result) {
    switch (result.type) {
      case 'Customer':
        final customer = result.payload as Customer;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider(
              create: (_) => CustomerBloc()..add(LoadCustomersRequested()),
              child: CustomerProfileScreen(customer: customer),
            ),
          ),
        );
        break;
      case 'Dispatch':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DispatchHubScreen()),
        );
        break;
      case 'Supplier':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SupplierDirectoryScreen()),
        );
        break;
      case 'Inventory':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const InventoryScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Global Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search customers, requests, suppliers, inventory',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () => _searchController.clear(),
                        icon: const Icon(Icons.close),
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.search_off_outlined, size: 44),
                          const SizedBox(height: 12),
                          Text(
                            _searchController.text.trim().isEmpty
                                ? 'No records yet. Start by creating customers, stock, or requests.'
                                : 'No results matched your search.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CustomerListScreen(),
                                ),
                              );
                            },
                            child: const Text('Open Customers'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: _results.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final result = _results[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(result.type.substring(0, 1)),
                        ),
                        title: Text(result.title),
                        subtitle: Text(result.subtitle),
                        trailing: Text(
                          result.type,
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        onTap: () => _openResult(result),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SearchResult {
  final String type;
  final String title;
  final String subtitle;
  final Object payload;

  const _SearchResult({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.payload,
  });
}
