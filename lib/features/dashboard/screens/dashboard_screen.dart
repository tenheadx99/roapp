import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/db_exporter.dart';
import '../../../core/constants/app_strings.dart';
import '../../../widgets/responsive_layout.dart';
import '../../../widgets/semi_bold_text_view.dart';
import '../../../widgets/sub_regular_text.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/models/user.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../auth/screens/profile_screen.dart';
import '../../customer/screens/customer_list_screen.dart';
import '../../dispatch/screens/dispatch_hub_screen.dart';
import '../../insights/screens/insights_screen.dart';
import '../../inventory/screens/inventory_screen.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../operations/screens/operations_center_screen.dart';
import '../../search/screens/global_search_screen.dart';
import '../../settings/bloc/settings_cubit.dart';
import '../../settings/models/app_settings.dart';
import '../../supplier/screens/supplier_directory_screen.dart';
import '../../technician/screens/technicians_screen.dart';
import '../bloc/dashboard_bloc.dart';
import 'scheduled_services_screen.dart';
// Note: Icon usage and exact colors may need refinement
// but this implements the structure and Bloc usage.

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground =
        theme.appBarTheme.foregroundColor ?? theme.colorScheme.onSurface;
    return BlocProvider(
      create: (_) => DashboardBloc()..add(DashboardDataRequested()),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              final user = authState is AuthAuthenticated
                  ? authState.user
                  : null;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user == null
                        ? AppStrings.businessOverview
                        : 'Welcome, ${user.displayName.split(' ').first}',
                    style: TextStyle(
                      color: foreground,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    AppStrings.businessOverview,
                    style: TextStyle(
                      color: const Color(0xFF64748B).withValues(alpha: 0.95),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            },
          ),
          backgroundColor:
              theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface,
          foregroundColor: foreground,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(Icons.search_rounded, color: foreground),
              tooltip: 'Global Search',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GlobalSearchScreen()),
                );
              },
            ),


            IconButton(
              icon: Icon(Icons.notifications_none, color: foreground),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, authState) {
                final user = authState is AuthAuthenticated
                    ? authState.user
                    : null;
                return InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: user == null
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BlocProvider.value(
                                value: context.read<AuthBloc>(),
                                child: ProfileScreen(user: user),
                              ),
                            ),
                          );
                        },
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFF007FFF),
                    child: Text(
                      user?.initials ?? 'RM',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: const ResponsiveLayout(
          mobile: _MobileDashboardView(),
          desktop: _DesktopDashboardView(),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showQuickCreateSheet(context),
          backgroundColor: const Color(0xFF007FFF),
          child: const Icon(Icons.add, size: 30),
        ),
      ),
    );
  }
}

class _MobileDashboardView extends StatelessWidget {
  const _MobileDashboardView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        if (state is DashboardLoading || state is DashboardInitial) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is DashboardError) {
          return Center(child: Text(state.message));
        } else if (state is DashboardLoaded) {
          final isEmpty =
              (state.stats['totalCustomers'] == '0') &&
              (state.stats['totalInventory'] == '0') &&
              state.scheduledServices.isEmpty;
          return RefreshIndicator(
            onRefresh: () async {
              context.read<DashboardBloc>().add(DashboardDataRequested());
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeBanner(context, state.stats),
                  const SizedBox(height: 20),
                  if (isEmpty) ...[
                    _buildOnboardingCard(context),
                    const SizedBox(height: 20),
                  ],
                  _buildStatsGrid(state.stats, isDesktop: false),
                  const SizedBox(height: 32),
                  _buildQuickActions(context),
                  const SizedBox(height: 16),
                  _buildScheduledServices(context, state.scheduledServices),
                  const SizedBox(height: 16),
                  _buildRecentActivity(
                    context,
                    state.activities.cast<Map<String, dynamic>>(),
                  ),
                ],
              ),
            ),
          );
        }
        return const SizedBox();
      },
    );
  }
}

class _DesktopDashboardView extends StatelessWidget {
  const _DesktopDashboardView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        if (state is DashboardLoading || state is DashboardInitial) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is DashboardError) {
          return Center(child: Text(state.message));
        } else if (state is DashboardLoaded) {
          final isEmpty =
              (state.stats['totalCustomers'] == '0') &&
              (state.stats['totalInventory'] == '0') &&
              state.scheduledServices.isEmpty;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeBanner(context, state.stats, isDesktop: true),
                const SizedBox(height: 20),
                if (isEmpty) ...[
                  _buildOnboardingCard(context, isDesktop: true),
                  const SizedBox(height: 20),
                ],
                _buildStatsGrid(state.stats, isDesktop: true),
                const SizedBox(height: 32),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: _buildScheduledServices(
                              context,
                              state.scheduledServices,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: _buildRecentActivity(
                              context,
                              state.activities.cast<Map<String, dynamic>>(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: _buildQuickActions(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }
        return const SizedBox();
      },
    );
  }
}

Widget _buildWelcomeBanner(
  BuildContext context,
  Map<String, dynamic> stats, {
  bool isDesktop = false,
}) {
  final authState = context.watch<AuthBloc>().state;
  final settings = context.watch<SettingsCubit>().state;
  final user = authState is AuthAuthenticated ? authState.user : null;
  final pendingService = stats['pendingService'] ?? '0';
  final lowStock = stats['lowStock'] ?? '0';

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF007FFF), Color(0xFF38BDF8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF007FFF).withValues(alpha: 0.2),
          blurRadius: 22,
          offset: const Offset(0, 12),
        ),
      ],
    ),
    child: isDesktop
        ? Row(
            children: [
              Expanded(
                child: _buildWelcomeText(
                  context,
                  user,
                  pendingService.toString(),
                  lowStock.toString(),
                  settings,
                ),
              ),
              const SizedBox(width: 20),
              _buildWelcomeActions(context),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeText(
                context,
                user,
                pendingService.toString(),
                lowStock.toString(),
                settings,
              ),
              const SizedBox(height: 16),
              _buildWelcomeActions(context),
            ],
          ),
  );
}

Widget _buildWelcomeText(
  BuildContext context,
  User? user,
  String pendingService,
  String lowStock,
  AppSettings settings,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Good to see you${user == null ? '' : ', ${user.displayName.split(' ').first}'}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'You currently have $pendingService active service requests and $lowStock low-stock alerts that may need attention.',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.92),
          fontSize: 14,
          height: 1.4,
        ),
      ),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          settings.trialOverrideUnlocked
              ? 'Admin override is active for this installation.'
              : 'Trial access: ${settings.daysRemainingInTrial} day(s) remaining.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.95),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ],
  );
}

Widget _buildWelcomeActions(BuildContext context) {
  return Wrap(
    spacing: 10,
    runSpacing: 10,
    children: [
      _WelcomeActionChip(
        icon: Icons.add_task_outlined,
        label: 'Add Request',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DispatchHubScreen()),
          );
        },
      ),
      _WelcomeActionChip(
        icon: Icons.person_outline,
        label: 'View Profile',
        onTap: () {
          final authState = context.read<AuthBloc>().state;
          if (authState is! AuthAuthenticated) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<AuthBloc>(),
                child: ProfileScreen(user: authState.user),
              ),
            ),
          );
        },
      ),
      _WelcomeActionChip(
        icon: Icons.search_rounded,
        label: 'Search',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GlobalSearchScreen()),
          );
        },
      ),
      _WelcomeActionChip(
        icon: Icons.notifications_none,
        label: 'Notifications',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          );
        },
      ),
    ],
  );
}

Widget _buildStatsGrid(Map<String, dynamic> stats, {required bool isDesktop}) {
  return GridView.count(
    crossAxisCount: isDesktop ? 4 : 2,
    crossAxisSpacing: 16,
    mainAxisSpacing: 16,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    childAspectRatio: isDesktop ? 1.5 : 1.2,
    children: [
      _StatCard(
        title: AppStrings.totalInventory,
        value: stats['totalInventory'],
        icon: Icons.inventory_2_outlined,
        iconBgColor: Colors.blue.shade50,
        iconColor: Colors.blue.shade600,
        badgeLabel: stats['totalInventoryBadge'] as String,
        badgeTone: stats['totalInventoryBadgeTone'] as String,
      ),
      _StatCard(
        title: AppStrings.pendingService,
        value: stats['pendingService'],
        icon: Icons.build_outlined,
        iconBgColor: const Color(0xFF007FFF).withValues(alpha: 0.1),
        iconColor: const Color(0xFF007FFF),
        badgeLabel:
            '${stats['underwayJobs']} underway • ${stats['pendingServiceBadge']}',
        badgeTone: stats['pendingServiceBadgeTone'] as String,
      ),
      _StatCard(
        title: AppStrings.totalCustomers,
        value: stats['totalCustomers'],
        icon: Icons.group_outlined,
        iconBgColor: Colors.grey.shade100,
        iconColor: Colors.grey.shade600,
        badgeLabel: stats['totalCustomersBadge'] as String,
        badgeTone: stats['totalCustomersBadgeTone'] as String,
      ),
      _StatCard(
        title: AppStrings.lowStock,
        value: stats['lowStock'],
        icon: Icons.warning_amber_rounded,
        iconBgColor: Colors.red.shade50,
        iconColor: Colors.red.shade600,
        badgeLabel: stats['lowStockBadge'] as String,
        badgeTone: stats['lowStockBadgeTone'] as String,
        isAlert: true,
      ),
    ],
  );
}

Widget _buildQuickActions(BuildContext context) {
  final actions = [
    _QuickActionItem(
      icon: Icons.people_outline,
      label: 'Customers',
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CustomerListScreen()),
      ),
    ),
    _QuickActionItem(
      icon: Icons.inventory_2_outlined,
      label: 'Inventory',
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const InventoryScreen()),
      ),
    ),
    _QuickActionItem(
      icon: Icons.precision_manufacturing_outlined,
      label: 'Suppliers',
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SupplierDirectoryScreen()),
      ),
    ),
    _QuickActionItem(
      icon: Icons.build_outlined,
      label: 'Dispatch',
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DispatchHubScreen()),
      ),
    ),
    _QuickActionItem(
      icon: Icons.engineering_outlined,
      label: 'Technicians',
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TechniciansScreen()),
      ),
    ),
    _QuickActionItem(
      icon: Icons.receipt_long_outlined,
      label: 'Operations',
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const OperationsCenterScreen()),
      ),
    ),
    _QuickActionItem(
      icon: Icons.insights_outlined,
      label: 'Insights',
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const InsightsScreen()),
      ),
    ),
  ];

  return LayoutBuilder(
    builder: (context, constraints) {
      final maxWidth = constraints.maxWidth.isFinite
          ? constraints.maxWidth
          : MediaQuery.of(context).size.width - 32;
      final crossAxisCount = maxWidth >= 360 ? 3 : 2;
      final spacing = 12.0;
      final buttonWidth =
          (maxWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SemiBoldTextView(text: 'Quick Actions', fontSize: 16),
          const SizedBox(height: 16),
          Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: actions
                .map(
                  (action) => _QuickActionBtn(
                    icon: action.icon,
                    label: action.label,
                    width: buttonWidth,
                    onTap: action.onTap,
                  ),
                )
                .toList(),
          ),
        ],
      );
    },
  );
}

Widget _buildScheduledServices(
  BuildContext context,
  List<dynamic> scheduledServices,
) {
  final top5Scheduled = scheduledServices.take(5).toList();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SemiBoldTextView(text: 'Scheduled Services', fontSize: 16),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ScheduledServicesScreen(
                    scheduledServices: scheduledServices,
                  ),
                ),
              );
            },
            child: const Text(
              'View All',
              style: TextStyle(
                color: Color(0xFF007FFF),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 4),
      if (top5Scheduled.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: SubRegularText(text: 'No upcoming scheduled services.'),
        )
      else
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: top5Scheduled.length,
          separatorBuilder: (context, index) => const Divider(indent: 52),
          itemBuilder: (context, index) {
            final service = top5Scheduled[index] as Map<String, dynamic>;
            final status = service['status'] as String? ?? 'new';
            final statusLabel = status.replaceAll('_', ' ').toUpperCase();
            final isPending = status != 'completed';

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.blue.shade200.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Icon(
                      Icons.build_circle_outlined,
                      color: Colors.blue.shade600,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SemiBoldTextView(
                          text: service['title'] as String,
                          fontSize: 14,
                        ),
                        const SizedBox(height: 2),
                        SubRegularText(
                          text: 'Customer: ${service['customerName']}',
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              service['time'] as String,
                              style: const TextStyle(
                                color: Color(0xFF007FFF),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (service['status'] != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isPending
                                      ? Colors.orange.shade50
                                      : Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isPending
                                        ? Colors.orange.shade700
                                        : Colors.green.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
    ],
  );
}

Widget _buildRecentActivity(
  BuildContext context,
  List<Map<String, dynamic>> activities,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SemiBoldTextView(text: AppStrings.recentActivity, fontSize: 16),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DispatchHubScreen()),
              );
            },
            child: const Text(
              AppStrings.viewAll,
              style: TextStyle(
                color: Color(0xFF007FFF),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 4),
      ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: activities.length,
        separatorBuilder: (context, index) => const Divider(indent: 52),
        itemBuilder: (context, index) {
          final activity = activities[index];
          IconData iconToUse;
          Color iconColor;
          Color iconBg;
          switch (activity['color']) {
            case 'green':
              iconToUse = Icons.check_circle_outline;
              iconColor = Colors.green.shade600;
              iconBg = Colors.green.shade50;
              break;
            case 'blue':
              iconToUse = Icons.person_add_alt_1_outlined;
              iconColor = Colors.blue.shade600;
              iconBg = Colors.blue.shade50;
              break;
            case 'orange':
            default:
              iconToUse = Icons.calendar_today_outlined;
              iconColor = Colors.orange.shade600;
              iconBg = Colors.orange.shade50;
              break;
          }

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: iconColor.withValues(alpha: 0.2)),
                  ),
                  child: Icon(iconToUse, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SemiBoldTextView(
                        text: activity['title'] as String,
                        fontSize: 14,
                      ),
                      const SizedBox(height: 2),
                      SubRegularText(text: activity['desc'] as String),
                      const SizedBox(height: 4),
                      Text(
                        activity['time'] as String,
                        style: const TextStyle(
                          color: Color(0xFF007FFF),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ],
  );
}

void _showQuickCreateSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Theme.of(context).cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SemiBoldTextView(text: 'Quick Create', fontSize: 18),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.person_add_alt_1_outlined),
                title: const Text('New Customer'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CustomerListScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.build_circle_outlined),
                title: const Text('Service Request'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DispatchHubScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.inventory_2_outlined),
                title: const Text('Inventory Item'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const InventoryScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.receipt_long_outlined),
                title: const Text('Invoice / AMC / PO'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const OperationsCenterScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.precision_manufacturing_outlined),
                title: const Text('Supplier'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SupplierDirectoryScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildOnboardingCard(BuildContext context, {bool isDesktop = false}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFBFDBFE)),
    ),
    child: isDesktop
        ? Row(
            children: [
              const Expanded(child: _OnboardingCopy()),
              const SizedBox(width: 20),
              _OnboardingActions(),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _OnboardingCopy(),
              SizedBox(height: 16),
              _OnboardingActions(),
            ],
          ),
  );
}

class _OnboardingCopy extends StatelessWidget {
  const _OnboardingCopy();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Set up your first workflow',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          'Dummy data is gone, so this space starts clean. Create your first customer, product category, or service request to turn the dashboard into a live operations view.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _OnboardingActions extends StatelessWidget {
  const _OnboardingActions();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        FilledButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CustomerListScreen()),
            );
          },
          icon: const Icon(Icons.people_outline),
          label: const Text('First Customer'),
        ),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const InventoryScreen()),
            );
          },
          icon: const Icon(Icons.category_outlined),
          label: const Text('First Category'),
        ),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DispatchHubScreen()),
            );
          },
          icon: const Icon(Icons.build_outlined),
          label: const Text('First Request'),
        ),
      ],
    );
  }
}

class _QuickActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final double width;
  final VoidCallback onTap;

  const _QuickActionBtn({
    required this.icon,
    required this.label,
    required this.width,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF007FFF), size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF475569),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

class _WelcomeActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _WelcomeActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String badgeLabel;
  final String badgeTone;
  final bool isAlert;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.badgeLabel,
    required this.badgeTone,
    this.isAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    final badgeColors = _badgeColors(badgeTone, isAlert);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColors.$1,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badgeLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: badgeColors.$2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: isAlert
                      ? Colors.red.shade600
                      : const Color(0xFF0F172A),
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  (Color, Color) _badgeColors(String tone, bool isAlertCard) {
    if (isAlertCard || tone == 'negative') {
      return (Colors.red.shade50, Colors.red.shade700);
    }
    if (tone == 'positive') {
      return (Colors.green.shade50, Colors.green.shade700);
    }
    return (Colors.blueGrey.shade50, Colors.blueGrey.shade700);
  }
}
