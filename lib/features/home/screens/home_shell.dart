import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/bloc/auth_bloc.dart';
import '../../auth/screens/profile_screen.dart';
import '../../customer/screens/customer_list_screen.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../dispatch/screens/dispatch_hub_screen.dart';
import '../../insights/screens/insights_screen.dart';
import '../../inventory/screens/inventory_screen.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../operations/screens/operations_center_screen.dart';
import '../../supplier/screens/supplier_directory_screen.dart';
import '../../technician/screens/technicians_screen.dart';

/// Root shell with persistent navigation: a bottom [NavigationBar] on
/// phones and a [NavigationRail] on wide layouts, over a lazily built
/// [IndexedStack] so switching tabs preserves each tab's state.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  static HomeShellState? of(BuildContext context) =>
      context.findAncestorStateOfType<HomeShellState>();

  @override
  State<HomeShell> createState() => HomeShellState();
}

class HomeShellState extends State<HomeShell> {
  int _index = 0;
  final Set<int> _builtTabs = {0};

  void switchTab(int index) {
    if (index < 0 || index >= _destinations.length) return;
    setState(() {
      _index = index;
      _builtTabs.add(index);
    });
  }

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    NavigationDestination(
      icon: Icon(Icons.build_circle_outlined),
      selectedIcon: Icon(Icons.build_circle),
      label: 'Dispatch',
    ),
    NavigationDestination(
      icon: Icon(Icons.people_alt_outlined),
      selectedIcon: Icon(Icons.people_alt),
      label: 'Customers',
    ),
    NavigationDestination(
      icon: Icon(Icons.receipt_long_outlined),
      selectedIcon: Icon(Icons.receipt_long),
      label: 'Operations',
    ),
    NavigationDestination(
      icon: Icon(Icons.grid_view_outlined),
      selectedIcon: Icon(Icons.grid_view),
      label: 'More',
    ),
  ];

  Widget _tab(int index) {
    if (!_builtTabs.contains(index)) return const SizedBox.shrink();
    switch (index) {
      case 0:
        return const DashboardScreen();
      case 1:
        return const DispatchHubScreen();
      case 2:
        return const CustomerListScreen();
      case 3:
        return const OperationsCenterScreen();
      default:
        return const _MoreScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    final stack = IndexedStack(
      index: _index,
      children: List.generate(_destinations.length, _tab),
    );

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: switchTab,
              labelType: NavigationRailLabelType.all,
              destinations: _destinations
                  .map(
                    (d) => NavigationRailDestination(
                      icon: d.icon,
                      selectedIcon: d.selectedIcon,
                      label: Text(d.label),
                    ),
                  )
                  .toList(),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: stack),
          ],
        ),
      );
    }

    return Scaffold(
      body: stack,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: switchTab,
        destinations: _destinations,
      ),
    );
  }
}

class _MoreScreen extends StatelessWidget {
  const _MoreScreen();

  @override
  Widget build(BuildContext context) {
    final entries = [
      (
        Icons.inventory_2_outlined,
        'Inventory',
        () => const InventoryScreen(),
      ),
      (
        Icons.precision_manufacturing_outlined,
        'Suppliers',
        () => const SupplierDirectoryScreen(),
      ),
      (
        Icons.engineering_outlined,
        'Technicians',
        () => const TechniciansScreen(),
      ),
      (
        Icons.query_stats_outlined,
        'Insights',
        () => const InsightsScreen(),
      ),
      (
        Icons.notifications_outlined,
        'Notifications',
        () => const NotificationsScreen(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'More',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          for (final (icon, label, builder) in entries)
            ListTile(
              leading: Icon(icon),
              title: Text(label),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => builder()),
              ),
            ),
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is! AuthAuthenticated) return const SizedBox.shrink();
              return ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Profile & Settings'),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfileScreen(user: state.user),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
