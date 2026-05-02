import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/db_exporter.dart';
import '../../../core/constants/app_strings.dart';
import '../../../widgets/responsive_layout.dart';

import '../../../widgets/semi_bold_text_view.dart';
import '../../../widgets/sub_regular_text.dart';
import '../../customer/screens/customer_list_screen.dart';
import '../../dispatch/screens/dispatch_hub_screen.dart';
import '../../insights/screens/insights_screen.dart';
import '../../inventory/screens/inventory_screen.dart';
import '../../notifications/screens/notifications_screen.dart';
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
    return BlocProvider(
      create: (_) => DashboardBloc()..add(DashboardDataRequested()),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7F8),
        appBar: AppBar(
          title: const Text(
            AppStrings.businessOverview,
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.download_rounded, color: Color(0xFF007FFF)),
              tooltip: 'Download Database',
              onPressed: () => DbExporter.exportDatabase(),
            ),
            Builder(
              builder: (buttonContext) => IconButton(
                icon: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
                tooltip: 'Clear All Data',
                onPressed: () {
                  bool shouldBackup = true;
                  final passwordController = TextEditingController();

                  showDialog(
                    context: buttonContext,
                    builder: (dialogContext) => StatefulBuilder(
                      builder: (context, setDialogState) => AlertDialog(
                        title: const Text('Confirm Data Clearance'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'This action will delete all customers, inventory, and history. It cannot be undone.',
                              style: TextStyle(fontSize: 13, color: Colors.grey),
                            ),
                            const SizedBox(height: 20),
                            CheckboxListTile(
                              value: shouldBackup,
                              onChanged: (val) => setDialogState(() => shouldBackup = val ?? false),
                              title: const Text('Backup before deleting', style: TextStyle(fontSize: 14)),
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: passwordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Enter Password to Confirm',
                                hintText: 'password123',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                            onPressed: () async {
                              // Verify password (matching the default credentials)
                              if (passwordController.text == "password123") {
                                if (shouldBackup) {
                                  await DbExporter.exportDatabase();
                                }
                                if (buttonContext.mounted) {
                                  buttonContext.read<DashboardBloc>().add(DashboardDataClearRequested());
                                }
                                if (dialogContext.mounted) {
                                  Navigator.pop(dialogContext);
                                }
                              } else {
                                ScaffoldMessenger.of(dialogContext).showSnackBar(
                                  const SnackBar(content: Text('Incorrect password!'), backgroundColor: Colors.red),
                                );
                              }
                            },
                            child: const Text('Confirm & Clear'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.notifications_none, color: Colors.black),
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
            const CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(
                'https://i.pravatar.cc/150?u=a042581f4e29026024d',
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: const ResponsiveLayout(
          mobile: _MobileDashboardView(),
          desktop: _DesktopDashboardView(),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {},
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
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsGrid(state.stats, isDesktop: false),
                const SizedBox(height: 32),
                _buildQuickActions(context),
                const SizedBox(height: 16),
                _buildScheduledServices(context, state.scheduledServices),
                const SizedBox(height: 16),
                _buildRecentActivity(
                  state.activities.cast<Map<String, dynamic>>(),
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
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: _buildScheduledServices(context, state.scheduledServices),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: _buildRecentActivity(
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
                          color: Colors.white,
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
        trend: '+5%',
        trendIsUp: true,
      ),
      _StatCard(
        title: AppStrings.pendingService,
        value: stats['pendingService'],
        icon: Icons.build_outlined,
        iconBgColor: const Color(0xFF007FFF).withValues(alpha: 0.1),
        iconColor: const Color(0xFF007FFF),
        trend: '+2%',
        trendIsUp: true,
      ),
      _StatCard(
        title: AppStrings.totalCustomers,
        value: stats['totalCustomers'],
        icon: Icons.group_outlined,
        iconBgColor: Colors.grey.shade100,
        iconColor: Colors.grey.shade600,
        trend: '-1%',
        trendIsUp: false,
      ),
      _StatCard(
        title: AppStrings.lowStock,
        value: stats['lowStock'],
        icon: Icons.warning_amber_rounded,
        iconBgColor: Colors.red.shade50,
        iconColor: Colors.red.shade600,
        trend: 'Alert',
        trendIsUp: false,
        isAlert: true,
      ),
    ],
  );
}

Widget _buildQuickActions(BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SemiBoldTextView(text: 'Quick Actions', fontSize: 16),
      const SizedBox(height: 16),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _QuickActionBtn(
            icon: Icons.people_outline,
            label: 'Customers',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CustomerListScreen()),
            ),
          ),
          _QuickActionBtn(
            icon: Icons.inventory_2_outlined,
            label: 'Inventory',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const InventoryScreen()),
            ),
          ),
          _QuickActionBtn(
            icon: Icons.precision_manufacturing_outlined,
            label: 'Suppliers',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SupplierDirectoryScreen(),
              ),
            ),
          ),
          _QuickActionBtn(
            icon: Icons.build_outlined,
            label: 'Dispatch',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DispatchHubScreen()),
            ),
          ),
          _QuickActionBtn(
            icon: Icons.engineering_outlined,
            label: 'Technicians',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TechniciansScreen()),
            ),
          ),
          _QuickActionBtn(
            icon: Icons.insights_outlined,
            label: 'Insights',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const InsightsScreen()),
            ),
          ),
        ],
      ),
    ],
  );
}

Widget _buildScheduledServices(BuildContext context, List<dynamic> scheduledServices) {
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
            final isPending = service['status'] == 'Pending';

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
                      border: Border.all(color: Colors.blue.shade200.withOpacity(0.5)),
                    ),
                    child: Icon(Icons.build_circle_outlined, color: Colors.blue.shade600, size: 20),
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
                        SubRegularText(text: 'Customer: ${service['customerName']}'),
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
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isPending ? Colors.orange.shade50 : Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  service['status'],
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isPending ? Colors.orange.shade700 : Colors.green.shade700,
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

Widget _buildRecentActivity(List<Map<String, dynamic>> activities) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SemiBoldTextView(text: AppStrings.recentActivity, fontSize: 16),
          TextButton(
            onPressed: () {},
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
                    border: Border.all(color: iconColor.withOpacity(0.2)),
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

class _QuickActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width:
            MediaQuery.of(context).size.width / 3 -
            24, // 3 items per row approx
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
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

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String trend;
  final bool trendIsUp;
  final bool isAlert;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.trend,
    required this.trendIsUp,
    this.isAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isAlert
                      ? Colors.red.shade50
                      : trendIsUp
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    if (!isAlert)
                      Icon(
                        trendIsUp ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 10,
                        color: trendIsUp
                            ? Colors.green.shade600
                            : Colors.red.shade600,
                      ),
                    const SizedBox(width: 2),
                    Text(
                      trend,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isAlert
                            ? Colors.red.shade600
                            : trendIsUp
                            ? Colors.green.shade600
                            : Colors.red.shade600,
                      ),
                    ),
                  ],
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
}
