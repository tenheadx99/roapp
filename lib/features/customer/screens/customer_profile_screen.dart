import 'package:flutter/material.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/header_text.dart';
import '../../../widgets/semi_bold_text_view.dart';
import '../../../widgets/sub_regular_text.dart';
import '../models/customer.dart';
import '../models/service_history.dart';
import '../repositories/customer_repository.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../dispatch/bloc/dispatch_bloc.dart';
import '../../dispatch/repositories/dispatch_repository.dart';
import '../../dispatch/screens/add_service_request_bottom_sheet.dart';
import '../bloc/customer_bloc.dart';
import 'add_customer_bottom_sheet.dart';
import '../../operations/models/amc_contract.dart';
import '../../operations/models/communication_log.dart';
import '../../operations/models/invoice.dart';
import '../../operations/models/service_attachment.dart';
import '../../operations/repositories/operations_repository.dart';

class CustomerProfileScreen extends StatefulWidget {
  final Customer customer;

  const CustomerProfileScreen({super.key, required this.customer});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  int _selectedTabIndex = 0;

  Customer get customer {
    try {
      final state = context.read<CustomerBloc>().state;
      if (state is CustomerLoaded) {
        return state.allCustomers.firstWhere(
          (c) => c.id == widget.customer.id,
          orElse: () => widget.customer,
        );
      }
    } catch (_) {}
    return widget.customer;
  }

  @override
  Widget build(BuildContext context) {
    Widget content = BlocBuilder<CustomerBloc, CustomerState>(
      builder: (context, customerState) {
        final currentCustomer = customer;
        return Scaffold(
          backgroundColor: const Color(0xFFF5F7F8),
          appBar: AppBar(
            title: const Text(
              'Customer Profile',
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
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.black),
                onSelected: (value) {
                  if (value == 'edit') {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => BlocProvider.value(
                        value: context.read<CustomerBloc>(),
                        child: AddCustomerBottomSheet(
                          customerToEdit: currentCustomer,
                        ),
                      ),
                    );
                  } else if (value == 'delete') {
                    _showDeleteConfirmation(context);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20, color: Colors.black54),
                        SizedBox(width: 8),
                        Text('Edit Customer'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text(
                          'Delete Customer',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  children: [
                    _buildProfileCard(context),
                    const SizedBox(height: 16),
                    _buildTabBar(),
                    const SizedBox(height: 16),
                    _buildLifecyclePanel(),
                    _selectedTabIndex == 0
                        ? _buildHistoryList(context)
                        : _buildUpcomingList(context),
                  ],
                ),
              ),
              _buildBottomButton(context),
            ],
          ),
        );
      },
    );

    try {
      context.read<CustomerBloc>();
    } catch (_) {
      content = BlocProvider(
        create: (_) => CustomerBloc()..add(LoadCustomersRequested()),
        child: content,
      );
    }

    return BlocProvider(
      create: (context) => DispatchBloc(),
      child: content,
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    final blocState = context.read<CustomerBloc>().state;
    final bool hasActiveAmc = customer.status == 'AMC Plan' ||
        (blocState is CustomerLoaded &&
            blocState.activeAmcCustomerIds.contains(customer.id));

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
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
                  child: Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFF007FFF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF007FFF).withOpacity(0.2),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            'https://lh3.googleusercontent.com/aida-public/AB6AXuCglsoH-BBzaT6911tk8ROEVRlYpiMrCzyr4RFDALkb9kJJBf-v9kSToxHMD3bskCqKLcM-Axm8b252AvnvKeKBodeB6bC40wucIQjqI3PLX8ByE-MWqOeXbYkjdlW942egsWmQpwN-0oUnABS4QyVbGxJbX_P_Sq5Lcxi05kd0wu75txRIbEByMRKHroe0W6SSM8okvcgA9tzJja7L8ggQ4NtSoxBPbZCDG5qAn0TyPm0Ajq4SX0781u90Ww2hizfMMwWJr1sGtbC1',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.person,
                                  color: Color(0xFF007FFF),
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            HeaderText(
                              text: customer.name,
                              fontSize: 20,
                            ),
                            SubRegularText(
                              text: 'Customer ID: #${customer.numericId}',
                            ),
                            const SizedBox(height: 8),
                            if (hasActiveAmc)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF007FFF).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'ACTIVE AMC',
                                  style: TextStyle(
                                    color: Color(0xFF007FFF),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: customer.status == 'Service Due'
                                      ? Colors.red.shade100
                                      : (customer.status == 'Operational'
                                          ? Colors.green.shade100
                                          : Colors.amber.shade100),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  customer.status.toUpperCase(),
                                  style: TextStyle(
                                    color: customer.status == 'Service Due'
                                        ? Colors.red.shade700
                                        : (customer.status == 'Operational'
                                            ? Colors.green.shade700
                                            : Colors.amber.shade700),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'UNIT MODEL',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        SemiBoldTextView(
                          text: customer.model,
                          fontSize: 14,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'INSTALLED ON',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        SemiBoldTextView(
                          text: customer.installationDate ?? 'N/A',
                          fontSize: 14,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Call',
                    onPressed: () async {
                      final url = Uri.parse('tel:${customer.phone}');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      }
                    },
                    icon: const Icon(
                      Icons.phone,
                      size: 18,
                      color: Colors.white,
                    ),
                    height: 48,
                    borderRadius: 8,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomButton(
                    text: 'Locate',
                    onPressed: () async {
                      final url = Uri.parse(
                        'geo:0,0?q=${Uri.encodeComponent(customer.area)}',
                      );
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      } else {
                        final webUrl = Uri.parse(
                          'https://maps.google.com/?q=${Uri.encodeComponent(customer.area)}',
                        );
                        if (await canLaunchUrl(webUrl)) {
                          await launchUrl(webUrl);
                        }
                      }
                    },
                    icon: const Icon(
                      Icons.location_on,
                      size: 18,
                      color: Color(0xFF334155),
                    ),
                    color: const Color(0xFFF1F5F9),
                    textColor: const Color(0xFF334155),
                    height: 48,
                    borderRadius: 8,
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () async {
                    String phoneNum = customer.phone.replaceAll(
                      RegExp(r'[^\d+]'),
                      '',
                    );
                    if (!phoneNum.startsWith('+')) {
                      phoneNum = '+91$phoneNum'; // default formatting
                    }
                    final appUrl = Uri.parse('whatsapp://send?phone=$phoneNum');
                    final webUrl = Uri.parse('https://wa.me/$phoneNum');

                    try {
                      if (await canLaunchUrl(appUrl)) {
                        await launchUrl(
                          appUrl,
                          mode: LaunchMode.externalApplication,
                        );
                      } else {
                        await launchUrl(
                          webUrl,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    } catch (e) {
                      debugPrint('Could not launch WhatsApp: $e');
                    }
                  },
                  child: Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: FaIcon(
                        FontAwesomeIcons.whatsapp,
                        color: Color(0xFF25D366),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedTabIndex = 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: _selectedTabIndex == 0
                        ? Colors.white
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: _selectedTabIndex == 0
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                            ),
                          ]
                        : [],
                  ),
                  child: Center(
                    child: Text(
                      'Previous Services',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _selectedTabIndex == 0
                            ? Colors.black
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedTabIndex = 1),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: _selectedTabIndex == 1
                        ? Colors.white
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: _selectedTabIndex == 1
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                            ),
                          ]
                        : [],
                  ),
                  child: Center(
                    child: Text(
                      'Upcoming',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _selectedTabIndex == 1
                            ? Colors.black
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(BuildContext context) {
    return FutureBuilder<List<ServiceHistory>>(
      future: CustomerRepository().getServiceHistory(customer.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final history = snapshot.data ?? [];

        return Padding(
          padding: const EdgeInsets.all(16.0).copyWith(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'PREVIOUS SERVICES',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              if (history.isNotEmpty) ...[
                Row(
                  children: [
                    Expanded(
                      child: _LifecycleStat(
                        label: 'Total Services',
                        value: '${history.length}',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _LifecycleStat(
                        label: 'Last Visit',
                        value: history.first.date.split('•').first.trim(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              if (history.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No service history found.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: history.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final item = history[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SemiBoldTextView(
                                      text: item.type,
                                      fontSize: 14,
                                    ),
                                    SubRegularText(text: item.date),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF007FFF,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'COMPLETED',
                                    style: TextStyle(
                                      color: Color(0xFF007FFF),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.vertical(
                                bottom: Radius.circular(16),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'PARTS REPLACED',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: item.partsReplaced.split(',').map((
                                    part,
                                  ) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(
                                          color: Colors.grey.shade200,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        part.trim(),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'WORK DONE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  item.notes.trim().isEmpty
                                      ? 'No technician notes recorded.'
                                      : item.notes,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    height: 1.4,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Divider(height: 1),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 12,
                                          backgroundColor: Colors.grey.shade200,
                                          backgroundImage: const NetworkImage(
                                            'https://lh3.googleusercontent.com/aida-public/AB6AXuD4Sx1YCi58f2ilhJyNTxSaQFbgKcz_LvEdOFfhLLcWGGQpuwK2i1UO1Pf1R-91BdyKuR6oUASBI6C64cOVRUb0aua0pPcSYXFWMb2Y05px20SWNIIMlDyNq_1GySh9p1s_nv5NTPt1O2vZS_r74EIxHzIfyUuYuUr3J_Lrd6Us7MB_rIizokhySFMCrfJaGIRxtCGRm9U_grwST1htLPLIU19JqM7qTz_eUHiBgsjKemZWkOUWswtT3M1XOEWpgZ-3t9xH3-M_abF1',
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Tech: ${item.technicianName}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF475569),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      formatRupee(item.cost, decimalDigits: 2),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF007FFF),
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
          ),
        );
      },
    );
  }

  Widget _buildLifecyclePanel() {
    final operationsRepo = OperationsRepository();
    return FutureBuilder<_CustomerLifecycleData>(
      future: _loadCustomerLifecycle(operationsRepo),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: LinearProgressIndicator(minHeight: 2),
          );
        }
        final data = snapshot.data ?? const _CustomerLifecycleData();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SemiBoldTextView(text: 'Customer Timeline', fontSize: 16),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _LifecycleStat(
                        label: 'Balance Due',
                        value: '₹${data.balanceDue.toStringAsFixed(0)}',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _LifecycleStat(
                        label: 'AMC Left',
                        value: '${data.remainingVisits}',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _LifecycleStat(
                        label: 'Proofs',
                        value: '${data.attachments.length}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'RECENT COMMUNICATION',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                if (data.logs.isEmpty)
                  const Text(
                    'No call, WhatsApp, or service-note timeline yet.',
                    style: TextStyle(color: Colors.grey),
                  )
                else
                  ...data.logs
                      .take(3)
                      .map(
                        (log) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF007FFF),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${log.channel} • ${log.createdBy}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      log.note,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                if (data.attachments.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'SERVICE PROOF',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: data.attachments
                        .take(3)
                        .map(
                          (attachment) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              attachment.title,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<_CustomerLifecycleData> _loadCustomerLifecycle(
    OperationsRepository operationsRepo,
  ) async {
    final invoices = await operationsRepo.getInvoices(
      customerId: customer.id,
    );
    final contracts = await operationsRepo.getContracts(
      customerId: customer.id,
    );
    final logs = await operationsRepo.getCommunicationLogs(
      customerId: customer.id,
    );
    final attachments = await operationsRepo.getAttachments(
      customerId: customer.id,
    );
    return _CustomerLifecycleData(
      invoices: invoices,
      contracts: contracts,
      logs: logs,
      attachments: attachments,
    );
  }

  Widget _buildBottomButton(BuildContext scaffoldContext) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              const Color(0xFFF5F7F8),
              const Color(0xFFF5F7F8).withOpacity(0.95),
              const Color(0xFFF5F7F8).withOpacity(0),
            ],
          ),
        ),
        child: CustomButton(
          text: 'Create Service',
          icon: const Icon(
            Icons.calendar_today_outlined,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () async {
            await showModalBottomSheet(
              context: scaffoldContext,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => BlocProvider.value(
                value: scaffoldContext.read<DispatchBloc>(),
                child: AddServiceRequestBottomSheet(
                  initialCustomerId: customer.id,
                  initialCustomerName: customer.name,
                  initialAddress: customer.area,
                  initialModel: customer.model,
                ),
              ),
            );
            if (mounted) {
              await Future.delayed(const Duration(milliseconds: 300));
              if (mounted) setState(() {});
            }
          },
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Customer'),
        content: const Text(
          'Are you sure you want to delete this customer? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<CustomerBloc>().add(
                DeleteCustomer(customer.id),
              );
              Navigator.of(ctx).pop();
              Navigator.of(context).pop(); // Go back to list
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingList(BuildContext context) {
    return FutureBuilder(
      future: DispatchRepository().getServiceRequestsByCustomer(
        customerId: customer.id,
        customerName: customer.name,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final requests = (snapshot.data ?? [])
            .where((req) => req.status != 'completed')
            .toList();

        return Padding(
          padding: const EdgeInsets.all(16.0).copyWith(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'UPCOMING SCHEDULES',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              if (requests.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No upcoming schedules found.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: requests.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final req = requests[index];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF007FFF).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.event,
                              color: Color(0xFF007FFF),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  req.type,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  req.scheduledFor == null
                                      ? req.time
                                      : 'Scheduled for: ${req.time}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                                if (req.inventoryItems.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    '${req.inventoryLineCount} part(s) • ${formatRupee(req.totalAmount, decimalDigits: 2)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF007FFF),
                                    ),
                                  ),
                                ],
                                if ((req.technicianName ?? '')
                                    .trim()
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    'Assigned to ${req.technicianName}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              req.status.toUpperCase(),
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class _LifecycleStat extends StatelessWidget {
  final String label;
  final String value;

  const _LifecycleStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF94A3B8),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _CustomerLifecycleData {
  final List<Invoice> invoices;
  final List<AmcContract> contracts;
  final List<CommunicationLog> logs;
  final List<ServiceAttachment> attachments;

  const _CustomerLifecycleData({
    this.invoices = const [],
    this.contracts = const [],
    this.logs = const [],
    this.attachments = const [],
  });

  double get balanceDue =>
      invoices.fold<double>(0, (sum, invoice) => sum + invoice.balanceDue);

  int get remainingVisits =>
      contracts.fold<int>(0, (sum, contract) => sum + contract.visitsRemaining);
}
