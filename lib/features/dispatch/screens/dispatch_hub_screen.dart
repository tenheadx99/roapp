import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/header_text.dart';
import '../../../widgets/label_text.dart';
import '../../../widgets/semi_bold_text_view.dart';
import '../../../widgets/sub_regular_text.dart';
import '../../technician/models/technician.dart';
import '../../technician/repositories/technician_repository.dart';
import '../../operations/repositories/operations_repository.dart';
import '../../operations/screens/invoice_preview_screen.dart';
import '../bloc/dispatch_bloc.dart';
import '../models/service_request.dart';
import 'add_service_request_bottom_sheet.dart';

class DispatchHubScreen extends StatelessWidget {
  const DispatchHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DispatchBloc()..add(LoadDispatchRequests()),
      child: const _DispatchHubView(),
    );
  }
}

class _DispatchHubView extends StatefulWidget {
  const _DispatchHubView();

  @override
  State<_DispatchHubView> createState() => _DispatchHubViewState();
}

class _DispatchHubViewState extends State<_DispatchHubView> {
  final OperationsRepository _operationsRepository = OperationsRepository();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground =
        theme.appBarTheme.foregroundColor ?? theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: HeaderText(
          text: AppStrings.dispatchHubTitle,
          fontSize: 18,
          color: foreground,
        ),
        backgroundColor:
            theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface,
        foregroundColor: foreground,
        elevation: 0,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: foreground),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
      ),
      body: BlocBuilder<DispatchBloc, DispatchState>(
        builder: (context, state) {
          final loadedState = state is DispatchLoaded ? state : null;
          return Column(
            children: [
              _buildCalendarHeader(context, loadedState),
              _buildTabs(),
              Expanded(
                child: switch (state) {
                  DispatchLoading() || DispatchInitial() => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  DispatchError() => Center(child: Text(state.message)),
                  DispatchLoaded() => _buildRequestList(
                    state.filteredRequests,
                    state.activeTab,
                    state.selectedDate,
                  ),
                  _ => const SizedBox(),
                },
              ),
            ],
          );
        },
      ),
      floatingActionButton: Builder(
        builder: (context) {
          final bloc = context.read<DispatchBloc>();
          return FloatingActionButton(
            heroTag: 'add_service_request',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => BlocProvider.value(
                  value: bloc,
                  child: const AddServiceRequestBottomSheet(),
                ),
              );
            },
            backgroundColor: const Color(0xFF007FFF),
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          );
        },
      ),
    );
  }

  Widget _buildCalendarHeader(BuildContext context, DispatchLoaded? state) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final selectedDate = state?.selectedDate;
    final anchorDate = selectedDate ?? DateTime.now();
    final startDate = DateTime(
      anchorDate.year,
      anchorDate.month,
      anchorDate.day,
    );
    final days = List.generate(
      7,
      (index) => startDate.add(Duration(days: index)),
    );

    return Container(
      color: isDark ? theme.cardColor : Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatMonthLabel(anchorDate),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFF64748B),
                    letterSpacing: 1,
                  ),
                ),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => _pickDate(context, selectedDate),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF007FFF),
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.calendar_month, size: 14),
                      label: const Text(
                        AppStrings.fullCalendar,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const SizedBox(width: 16),
                _DateChip(
                  labelTop: 'ALL',
                  labelBottom: 'Dates',
                  isActive: selectedDate == null,
                  onTap: () {
                    context.read<DispatchBloc>().add(
                      const SelectDispatchDate(null),
                    );
                  },
                ),
                const SizedBox(width: 12),
                ...days.map((date) {
                  final isActive =
                      selectedDate != null &&
                      date.year == selectedDate.year &&
                      date.month == selectedDate.month &&
                      date.day == selectedDate.day;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _DateChip(
                      labelTop: _weekdayLabel(date),
                      labelBottom: date.day.toString().padLeft(2, '0'),
                      isActive: isActive,
                      onTap: () {
                        context.read<DispatchBloc>().add(
                          SelectDispatchDate(date),
                        );
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate(BuildContext context, DateTime? selectedDate) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365)),
    );

    if (picked == null || !context.mounted) return;
    context.read<DispatchBloc>().add(SelectDispatchDate(picked));
  }

  String _formatMonthLabel(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.year}'.toUpperCase();
  }

  String _weekdayLabel(DateTime date) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[date.weekday - 1].toUpperCase();
  }

  Widget _buildTabs() {
    return Container(
      color: Theme.of(context).brightness == Brightness.dark
          ? Theme.of(context).cardColor
          : Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: BlocBuilder<DispatchBloc, DispatchState>(
        builder: (context, state) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          String activeTab = 'New';
          int newCount = 0;
          int assignedCount = 0;
          int inProgressCount = 0;
          int completedCount = 0;

          if (state is DispatchLoaded) {
            final selectedDate = state.selectedDate;
            activeTab = state.activeTab;
            newCount = _countForStatus(state.allRequests, 'new', selectedDate);
            assignedCount = _countForStatus(
              state.allRequests,
              'assigned',
              selectedDate,
            );
            inProgressCount = _countForStatus(
              state.allRequests,
              'in_progress',
              selectedDate,
            );
            completedCount = _countForStatus(
              state.allRequests,
              'completed',
              selectedDate,
            );
          }

          final tabs = [
            {'label': 'New', 'count': newCount},
            {'label': 'Assigned', 'count': assignedCount},
            {'label': 'In Progress', 'count': inProgressCount},
            {'label': 'Completed', 'count': completedCount},
          ];

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: tabs.map((tab) {
                final label = tab['label'] as String;
                final count = tab['count'] as int;
                final isActive = label == activeTab;
                return GestureDetector(
                  onTap: () {
                    context.read<DispatchBloc>().add(
                      FilterDispatchRequests(label),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF007FFF)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$label ($count)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isActive
                            ? Colors.white
                            : (isDark
                                  ? const Color(0xFFCBD5E1)
                                  : const Color(0xFF475569)),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  int _countForStatus(
    List<ServiceRequest> requests,
    String status,
    DateTime? selectedDate,
  ) {
    return requests.where((request) {
      if (request.status != status) return false;
      if (selectedDate == null) return true;
      final scheduled = DateTime.tryParse(request.scheduledFor ?? '');
      if (scheduled == null) return false;
      return scheduled.year == selectedDate.year &&
          scheduled.month == selectedDate.month &&
          scheduled.day == selectedDate.day;
    }).length;
  }

  Widget _buildRequestList(
    List<ServiceRequest> requests,
    String activeTab,
    DateTime? selectedDate,
  ) {
    if (requests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.event_busy_outlined,
                size: 44,
                color: Color(0xFF94A3B8),
              ),
              const SizedBox(height: 12),
              Text(
                selectedDate == null
                    ? 'No $activeTab requests right now.'
                    : 'No $activeTab requests on ${_friendlyDate(selectedDate)}.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 6),
              const SubRegularText(
                text:
                    'Try another date, clear the filter, or add a new service request.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async =>
          context.read<DispatchBloc>().add(LoadDispatchRequests()),
      child: ListView.separated(
      padding: const EdgeInsets.all(16).copyWith(bottom: 80),
      itemCount: requests.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final req = requests[index];
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1F2937)
                  : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _statusChipBg(req.status),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: _statusChipBorder(req.status)),
                    ),
                    child: Text(
                      req.statusLabel,
                      style: TextStyle(
                        color: _statusChipText(req.status),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 12,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        req.time,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SemiBoldTextView(text: req.customerName, fontSize: 18),
              const SizedBox(height: 6),
              if (req.scheduledFor != null) ...[
                Row(
                  children: [
                    const Icon(
                      Icons.event_outlined,
                      size: 14,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _friendlyDate(
                          DateTime.tryParse(req.scheduledFor!) ??
                              DateTime.now(),
                        ),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF475569),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ],
              if (req.inventoryItems.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: req.inventoryItems
                      .take(3)
                      .map(
                        (item) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${item.name} x${item.quantity}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 14,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 4),
                  Expanded(child: SubRegularText(text: req.address)),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Color(0xFFF1F5F9), height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          req.type.contains('Filter')
                              ? Icons.water_drop
                              : Icons.build,
                          color: const Color(0xFF007FFF),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            req.type,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            req.model,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (req.inventoryItems.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            formatRupee(req.totalAmount, decimalDigits: 2),
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      if (req.status == 'new')
                        SizedBox(
                          width: 100,
                          height: 36,
                          child: CustomButton(
                            text: AppStrings.assign,
                            onPressed: () =>
                                _showAssignBottomSheet(context, req),
                            height: 36,
                            borderRadius: 8,
                          ),
                        ),
                      if (req.status != 'new' && req.status != 'completed')
                        SizedBox(
                          width: 120,
                          height: 36,
                          child: CustomButton(
                            text: req.status == 'assigned'
                                ? 'Start Job'
                                : 'Complete',
                            onPressed: () => _advanceRequest(context, req),
                            height: 36,
                            borderRadius: 8,
                          ),
                        ),
                      TextButton(
                        onPressed: () => _showEditBottomSheet(context, req),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF007FFF),
                          padding: const EdgeInsets.only(top: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Edit'),
                      ),
                      if (req.status == 'completed') ...[
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => InvoicePreviewScreen(request: req),
                            ),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF6366F1),
                            padding: const EdgeInsets.only(top: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Preview Invoice'),
                        ),
                        TextButton(
                          onPressed: () => _downloadInvoice(context, req),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF0F766E),
                            padding: const EdgeInsets.only(top: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Download Invoice'),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              if ((req.technicianName ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 14,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Assigned to ${req.technicianName}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF475569),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if ((req.notes ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  req.notes!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    height: 1.35,
                  ),
                ),
              ],
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    final bloc = context.read<DispatchBloc>();
                    bloc.add(DeleteServiceRequest(req.id));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${req.customerName} request deleted.'),
                        action: SnackBarAction(
                          label: 'Undo',
                          onPressed: () {
                            bloc.add(AddServiceRequest(req));
                          },
                        ),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Delete'),
                ),
              ),
            ],
          ),
        );
      },
      ),
    );
  }

  void _showEditBottomSheet(BuildContext context, ServiceRequest request) {
    final dispatchBloc = context.read<DispatchBloc>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: dispatchBloc,
        child: AddServiceRequestBottomSheet(requestToEdit: request),
      ),
    );
  }

  void _showAssignBottomSheet(BuildContext context, ServiceRequest request) {
    final dispatchBloc = context.read<DispatchBloc>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _AssignTechnicianSheet(
          request: request,
          onAssign: (technician, notes) {
            final updatedRequest = request.copyWith(
              status: 'assigned',
              technicianId: technician.id,
              technicianName: technician.name,
              notes: notes.trim().isEmpty ? request.notes : notes.trim(),
            );
            dispatchBloc.add(UpdateServiceRequest(updatedRequest));
          },
        );
      },
    );
  }

  void _advanceRequest(BuildContext context, ServiceRequest request) {
    final nextStatus = request.status == 'assigned'
        ? 'in_progress'
        : 'completed';
    final bloc = context.read<DispatchBloc>();
    bloc.add(UpdateServiceRequest(request.copyWith(status: nextStatus)));

    if (nextStatus == 'completed') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Service completed — moved to the Completed tab.'),
          action: SnackBarAction(
            label: 'VIEW',
            onPressed: () => bloc.add(const FilterDispatchRequests('Completed')),
          ),
        ),
      );
    }
  }

  Future<void> _downloadInvoice(
    BuildContext context,
    ServiceRequest request,
  ) async {
    try {
      final path = await _operationsRepository.exportServiceInvoice(request);
      await Share.shareXFiles(
        [XFile(path)],
        subject: 'Service Invoice - ${request.customerName}',
        text: 'Service invoice for ${request.customerName}',
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invoice saved and ready to share: $path')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not generate invoice: $e')));
    }
  }

  Color _statusChipBg(String status) {
    switch (status) {
      case 'completed':
        return Colors.green.shade50;
      case 'in_progress':
        return Colors.orange.shade50;
      case 'assigned':
        return Colors.blue.shade50;
      default:
        return const Color(0xFFDBEAFE);
    }
  }

  Color _statusChipBorder(String status) {
    switch (status) {
      case 'completed':
        return Colors.green.shade200;
      case 'in_progress':
        return Colors.orange.shade200;
      case 'assigned':
        return Colors.blue.shade200;
      default:
        return const Color(0xFF93C5FD);
    }
  }

  Color _statusChipText(String status) {
    switch (status) {
      case 'completed':
        return Colors.green.shade700;
      case 'in_progress':
        return Colors.orange.shade700;
      case 'assigned':
        return Colors.blue.shade700;
      default:
        return const Color(0xFF1D4ED8);
    }
  }

  String _friendlyDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }
}

class _DateChip extends StatelessWidget {
  final String labelTop;
  final String labelBottom;
  final bool isActive;
  final VoidCallback onTap;

  const _DateChip({
    required this.labelTop,
    required this.labelBottom,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isActive ? const Color(0xFF007FFF) : const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive
                  ? const Color(0xFF007FFF)
                  : const Color(0xFFF1F5F9),
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: const Color(0xFF007FFF).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Text(
                labelTop,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isActive
                      ? Colors.white.withValues(alpha: 0.8)
                      : const Color(0xFF94A3B8),
                ),
              ),
              Text(
                labelBottom,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssignTechnicianSheet extends StatefulWidget {
  final ServiceRequest request;
  final Function(Technician, String) onAssign;

  const _AssignTechnicianSheet({required this.request, required this.onAssign});

  @override
  State<_AssignTechnicianSheet> createState() => _AssignTechnicianSheetState();
}

class _AssignTechnicianSheetState extends State<_AssignTechnicianSheet> {
  Technician? _selectedTechnician;
  final TextEditingController _notesController = TextEditingController();
  final TechnicianRepository _technicianRepository = TechnicianRepository();

  @override
  void initState() {
    super.initState();
    _notesController.text = widget.request.notes ?? '';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 40,
            offset: Offset(0, -10),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 6,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SemiBoldTextView(text: AppStrings.assignTechnician, fontSize: 18),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF1F5F9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const LabelText(text: AppStrings.selectStaff),
          FutureBuilder<List<Technician>>(
            future: _technicianRepository.getTechnicians(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final techs = snapshot.data ?? [];
              if (techs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SubRegularText(text: "No technicians available."),
                );
              }

              _selectedTechnician ??= techs
                  .where(
                    (tech) =>
                        tech.id == widget.request.technicianId ||
                        tech.name == widget.request.technicianName,
                  )
                  .cast<Technician?>()
                  .firstOrNull;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedTechnician?.id,
                    hint: const SubRegularText(
                      text: AppStrings.chooseTechnician,
                    ),
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Color(0xFF94A3B8),
                    ),
                    items: techs
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.id,
                            child: SubRegularText(
                              text: '${e.name} (${e.status})',
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedTechnician = techs
                            .where((tech) => tech.id == val)
                            .cast<Technician?>()
                            .firstOrNull;
                      });
                    },
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          const LabelText(text: AppStrings.serviceNotes),
          CustomTextField(
            hintText: AppStrings.serviceNotesHint,
            onChanged: (val) {
              _notesController.text = val;
            },
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: AppStrings.confirmAssignment,
            onPressed: () {
              if (_selectedTechnician != null) {
                widget.onAssign(_selectedTechnician!, _notesController.text);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select a technician')),
                );
              }
            },
            icon: const Icon(Icons.send, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }
}

extension<T> on Iterable<T?> {
  T? get firstOrNull {
    for (final value in this) {
      if (value != null) {
        return value;
      }
    }
    return null;
  }
}
