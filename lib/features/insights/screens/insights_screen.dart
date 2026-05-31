import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/currency_formatter.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../widgets/semi_bold_text_view.dart';
import '../bloc/insights_bloc.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => InsightsBloc()..add(LoadInsightsData()),
      child: const _InsightsView(),
    );
  }
}

class _InsightsView extends StatelessWidget {
  const _InsightsView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground =
        theme.appBarTheme.foregroundColor ?? theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Insights',
          style: TextStyle(
            color: foreground,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor:
            theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface,
        foregroundColor: foreground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: foreground),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocBuilder<InsightsBloc, InsightsState>(
        builder: (context, state) {
          if (state is InsightsLoading || state is InsightsInitial) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is InsightsError) {
            return Center(child: Text(state.message));
          } else if (state is InsightsLoaded) {
            return SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTimeRangeFilter(context, state.activeTimeRange),
                  _buildStatsCards(context, state),
                  _buildProfitBreakdownCard(context, state),
                  _buildSalesTrends(context, state),
                  _buildServiceLoad(context, state),
                  _buildInventoryUsage(context, state),
                  _buildPerformanceHighlights(context, state),
                  _buildCriticalAlerts(context, state),
                ],
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildTimeRangeFilter(BuildContext context, String activeRange) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final ranges = ['Today', 'This Week', 'This Month', 'Custom'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: ranges.map((range) {
          final isActive = range == activeRange;
          return GestureDetector(
            onTap: () {
              context.read<InsightsBloc>().add(ChangeTimeRange(range));
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF007FFF)
                    : (isDark ? theme.cardColor : Colors.white),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive
                      ? Colors.transparent
                      : (isDark
                            ? const Color(0xFF1F2937)
                            : Colors.grey.shade200),
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  if (range == 'Custom') ...[
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: isActive
                          ? Colors.white
                          : (isDark
                                ? const Color(0xFFCBD5E1)
                                : const Color(0xFF64748B)),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    range,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isActive
                          ? Colors.white
                          : (isDark
                                ? const Color(0xFFCBD5E1)
                                : const Color(0xFF64748B)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatsCards(BuildContext context, InsightsLoaded state) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? theme.cardColor : Colors.white;
    final borderColor = isDark ? const Color(0xFF1F2937) : Colors.grey.shade100;
    final titleColor = isDark
        ? const Color(0xFFCBD5E1)
        : const Color(0xFF64748B);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
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
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'REVENUE',
                            style: TextStyle(
                              color: titleColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          const Icon(Icons.trending_up, color: Color(0xFF10B981), size: 18),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        formatRupee(state.revenue.toInt()),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Collected in ${state.activeTimeRange.toLowerCase()}',
                        style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
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
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'NET PROFIT',
                            style: TextStyle(
                              color: titleColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF059669), size: 18),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        formatRupee(state.profit.toInt()),
                        style: const TextStyle(
                          color: Color(0xFF059669),
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Estimated profit margin',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.01),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF007FFF).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.timer_outlined,
                        color: Color(0xFF007FFF),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AVERAGE TURNAROUND TIME',
                          style: TextStyle(
                            color: titleColor,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${state.avgTat} Hours',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  'Across ${state.serviceLoad.length} tech(s)',
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
  }

  Widget _buildProfitBreakdownCard(BuildContext context, InsightsLoaded state) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? theme.cardColor : Colors.white;
    final borderColor = isDark ? const Color(0xFF1F2937) : Colors.grey.shade100;
    final titleColor = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B);

    final double profit = state.profit;
    final double partsProfit = state.partsProfit;
    final double serviceCharge = state.serviceCharge;

    double partsShare = 0.0;
    double serviceShare = 0.0;
    if (profit > 0) {
      partsShare = (partsProfit / profit).clamp(0.0, 1.0);
      serviceShare = (serviceCharge / profit).clamp(0.0, 1.0);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
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
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF007FFF).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.pie_chart_outline_rounded,
                        color: Color(0xFF007FFF),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PROFIT REALIZATION',
                          style: TextStyle(
                            color: titleColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Visual Breakdown of Earnings',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Margin: ${(profit > 0 && state.revenue > 0 ? (profit / state.revenue * 100).toStringAsFixed(0) : "0")}%',
                    style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Segmented Progress Bar
            if (profit > 0) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  height: 10,
                  child: Row(
                    children: [
                      if (partsShare > 0)
                        Expanded(
                          flex: (partsShare * 100).round().clamp(1, 100),
                          child: Container(
                            color: const Color(0xFF007FFF), // Parts Profit (Blue)
                          ),
                        ),
                      if (serviceShare > 0)
                        Expanded(
                          flex: (serviceShare * 100).round().clamp(1, 100),
                          child: Container(
                            color: const Color(0xFF10B981), // Service Charge (Green)
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF007FFF),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Parts Profit (${(partsShare * 100).toStringAsFixed(0)}%)',
                        style: TextStyle(
                          fontSize: 11,
                          color: titleColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Service Fee (${(serviceShare * 100).toStringAsFixed(0)}%)',
                        style: TextStyle(
                          fontSize: 11,
                          color: titleColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1F2937) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'No profit breakdown available for this range.',
                    style: TextStyle(
                      fontSize: 12,
                      color: titleColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
            // Detailed Breakdown Table/List
            _buildBreakdownRow(
              context,
              'Parts Selling Price',
              state.partsRevenue,
              icon: Icons.sell_outlined,
              iconColor: const Color(0xFF007FFF),
              isHeading: false,
            ),
            const SizedBox(height: 10),
            _buildBreakdownRow(
              context,
              'Parts Supplier Price',
              -state.partsCost,
              icon: Icons.inventory_2_outlined,
              iconColor: Colors.grey,
              isHeading: false,
              isNegative: true,
            ),
            const Divider(height: 20),
            _buildBreakdownRow(
              context,
              'Item Profit (Selling - Supplier)',
              state.partsProfit,
              icon: Icons.trending_up_rounded,
              iconColor: const Color(0xFF007FFF),
              isHeading: false,
              boldValue: true,
            ),
            const SizedBox(height: 10),
            _buildBreakdownRow(
              context,
              'Service Charge',
              state.serviceCharge,
              icon: Icons.handyman_outlined,
              iconColor: const Color(0xFF10B981),
              isHeading: false,
              boldValue: true,
            ),
            const Divider(height: 24, thickness: 1.5),
            _buildBreakdownRow(
              context,
              'Total Profit (Item Profit + Service)',
              state.profit,
              icon: Icons.account_balance_wallet,
              iconColor: const Color(0xFF10B981),
              isHeading: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownRow(
    BuildContext context,
    String label,
    double value, {
    required IconData icon,
    required Color iconColor,
    required bool isHeading,
    bool isNegative = false,
    bool boldValue = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final valueStyle = TextStyle(
      fontSize: isHeading ? 16 : 13,
      fontWeight: isHeading || boldValue ? FontWeight.bold : FontWeight.w500,
      color: isHeading
          ? const Color(0xFF10B981)
          : (isNegative
              ? (isDark ? Colors.redAccent.shade100 : Colors.red.shade700)
              : (isDark ? Colors.white : const Color(0xFF0F172A))),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: isHeading ? 18 : 16, color: iconColor),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: isHeading ? 14 : 12,
                fontWeight: isHeading ? FontWeight.bold : FontWeight.w500,
                color: isHeading
                    ? (isDark ? Colors.white : const Color(0xFF0F172A))
                    : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
              ),
            ),
          ],
        ),
        Text(
          formatRupee(value.toInt().abs()),
          style: valueStyle,
        ),
      ],
    );
  }

  Widget _buildSalesTrends(BuildContext context, InsightsLoaded state) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? theme.cardColor : Colors.white;
    final borderColor = isDark ? const Color(0xFF1F2937) : Colors.grey.shade100;
    final subtle = isDark ? const Color(0xFF94A3B8) : Colors.grey.shade500;
    final spots = <BarChartGroupData>[];
    int i = 0;
    state.salesTrends.forEach((key, value) {
      spots.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: value,
              color: key == 'Fri'
                  ? const Color(0xFF007FFF)
                  : const Color(0xFF007FFF).withValues(alpha: 0.25),
              width: 24,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
      i++;
    });

    final days = state.salesTrends.keys.toList();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SemiBoldTextView(text: 'Sales Trends', fontSize: 18),
                  Text(
                    'Revenue growth over the last 7 days',
                    style: TextStyle(fontSize: 12, color: subtle),
                  ),
                ],
              ),
              Icon(Icons.info_outline, color: subtle, size: 18),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 188,
            child: ClipRect(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 120,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= days.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              days[index],
                              style: TextStyle(
                                color: subtle,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                        reservedSize: 28,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: spots,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceLoad(BuildContext context, InsightsLoaded state) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF1F2937) : Colors.grey.shade100,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SemiBoldTextView(text: 'Service Load', fontSize: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Text(
                      'By Technician',
                      style: TextStyle(
                        color: Color(0xFF007FFF),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: Color(0xFF007FFF),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...state.serviceLoad.map((tech) {
            final tasks = tech['tasks'] as int;
            final maxTasks = 50;
            final percentage = tasks / maxTasks;

            Color barColor;
            if (tech['color'] == '#007fff') {
              barColor = const Color(0xFF007FFF);
            } else if (tech['color'] == '#007fff99')
              barColor = const Color(0xFF007FFF).withValues(alpha: 0.6);
            else
              barColor = const Color(0xFF007FFF).withValues(alpha: 0.3);

            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        tech['name'],
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$tasks Tasks',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage,
                      backgroundColor: const Color(0xFFF1F5F9),
                      color: barColor,
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildInventoryUsage(BuildContext context, InsightsLoaded state) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF1F2937) : Colors.grey.shade100,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SemiBoldTextView(text: 'Inventory Usage', fontSize: 18),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                height: 110,
                width: 110,
                child: Stack(
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 5,
                        centerSpaceRadius: 35,
                        sections: state.inventoryUsage.map((entry) {
                          Color color;
                          if (entry['color'] == '#007fff') {
                            color = const Color(0xFF007FFF);
                          } else if (entry['color'] == '#007fff66')
                            color = const Color(
                              0xFF007FFF,
                            ).withValues(alpha: 0.6);
                          else
                            color = const Color(0xFFF1F5F9);

                          return PieChartSectionData(
                            color: color,
                            value: entry['value'] as double,
                            title: '',
                            radius: 10,
                          );
                        }).toList(),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${state.inventoryUsage.length}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Text(
                            'CATS',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: state.inventoryUsage.map((entry) {
                    Color color;
                    if (entry['color'] == '#007fff') {
                      color = const Color(0xFF007FFF);
                    } else if (entry['color'] == '#007fff66')
                      color = const Color(0xFF007FFF).withValues(alpha: 0.6);
                    else
                      color = const Color(0xFFF1F5F9);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${entry['name']} (${entry['value'].toInt()}%)',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceHighlights(
    BuildContext context,
    InsightsLoaded state,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SemiBoldTextView(text: 'Business Intelligence', fontSize: 18),
            const SizedBox(height: 16),
            _MetricList(
              title: 'Revenue by Technician',
              entries: state.revenueByTechnician
                  .take(4)
                  .map(
                    (entry) =>
                        '${entry['name']}: ₹${(entry['value'] as double).toStringAsFixed(0)}',
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            _MetricList(
              title: 'Top Replaced Parts',
              entries: state.topParts
                  .map((entry) => '${entry['name']}: ${entry['value']} jobs')
                  .toList(),
            ),
            const SizedBox(height: 16),
            _MetricList(
              title: 'Repeat Service Customers',
              entries: state.repeatCustomers
                  .map((entry) => '${entry['name']}: ${entry['value']} visits')
                  .toList(),
            ),
            const SizedBox(height: 16),
            _MetricList(
              title: 'Supplier Performance',
              entries: state.supplierPerformance
                  .map(
                    (entry) =>
                        '${entry['name']}: ${((entry['leadDays'] as double)).toStringAsFixed(1)} days avg lead • ${entry['orders']} orders',
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCriticalAlerts(BuildContext context, InsightsLoaded state) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final topRepeat = state.repeatCustomers.isNotEmpty
        ? state.repeatCustomers.first
        : null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 12.0),
            child: Text(
              'CRITICAL ALERTS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF94A3B8),
                letterSpacing: 1,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade100),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red.shade600,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topRepeat == null
                            ? 'Repeat Service Watch'
                            : 'Repeat Service Watch: ${topRepeat['name']}',
                        style: TextStyle(
                          color: Colors.red.shade900,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        topRepeat == null
                            ? 'No repeat-customer hotspots yet.'
                            : '${topRepeat['value']} service visits logged for this customer.',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.red.shade300, size: 18),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF007FFF).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF007FFF).withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF007FFF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.access_time_filled,
                    color: Color(0xFF007FFF),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SLA Breach Risk',
                        style: TextStyle(
                          color: isDark
                              ? theme.colorScheme.onSurface
                              : Colors.black87,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        state.slaBreaches == 0
                            ? 'No scheduled jobs are currently beyond the 24-hour threshold.'
                            : '${state.slaBreaches} services are pending for more than 24 hours.',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF94A3B8) : Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: isDark ? const Color(0xFF94A3B8) : Colors.grey,
                  size: 18,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricList extends StatelessWidget {
  final String title;
  final List<String> entries;

  const _MetricList({required this.title, required this.entries});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        if (entries.isEmpty)
          Text(
            'No data available yet.',
            style: Theme.of(context).textTheme.bodySmall,
          )
        else
          ...entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(entry),
            ),
          ),
      ],
    );
  }
}
