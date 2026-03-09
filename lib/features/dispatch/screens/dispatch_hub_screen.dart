import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/header_text.dart';
import '../../../widgets/label_text.dart';
import '../../../widgets/semi_bold_text_view.dart';
import '../../../widgets/sub_regular_text.dart';
import '../../technician/models/technician.dart';
import '../../technician/repositories/technician_repository.dart';
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        title: HeaderText(text: AppStrings.dispatchHubTitle, fontSize: 18),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          _buildCalendarHeader(),
          _buildTabs(),
          Expanded(
            child: BlocBuilder<DispatchBloc, DispatchState>(
              builder: (context, state) {
                if (state is DispatchLoading || state is DispatchInitial) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is DispatchError) {
                  return Center(child: Text(state.message));
                } else if (state is DispatchLoaded) {
                  return _buildRequestList(state.filteredRequests);
                }
                return const SizedBox();
              },
            ),
          ),
        ],
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

  Widget _buildCalendarHeader() {
    final days = [
      {'day': 'Mon', 'date': '02', 'active': false},
      {'day': 'Tue', 'date': '03', 'active': false},
      {'day': 'Wed', 'date': '04', 'active': false},
      {'day': 'Thu', 'date': '05', 'active': true},
      {'day': 'Fri', 'date': '06', 'active': false},
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'OCTOBER 2023',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                    letterSpacing: 1,
                  ),
                ),
                Row(
                  children: [
                    const Text(
                      AppStrings.fullCalendar,
                      style: TextStyle(
                        color: Color(0xFF007FFF),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.calendar_month,
                      color: Color(0xFF007FFF),
                      size: 14,
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
                ...days.map((d) {
                  final isActive = d['active'] as bool;
                  return Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF007FFF)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isActive
                            ? const Color(0xFF007FFF)
                            : const Color(0xFFF1F5F9),
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: const Color(0xFF007FFF).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      children: [
                        Text(
                          (d['day'] as String).toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isActive
                                ? Colors.white.withOpacity(0.8)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                        Text(
                          d['date'] as String,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isActive
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
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

  Widget _buildTabs() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: BlocBuilder<DispatchBloc, DispatchState>(
        builder: (context, state) {
          String activeTab = 'New';
          int newCount = 0;
          int assignedCount = 0;
          int inProgressCount = 0;

          if (state is DispatchLoaded) {
            activeTab = state.activeTab;
            newCount = state.allRequests.where((r) => r.status == 'new').length;
            assignedCount = state.allRequests
                .where((r) => r.status == 'assigned')
                .length;
            inProgressCount = state.allRequests
                .where((r) => r.status == 'in_progress')
                .length;
          }

          final tabs = [
            {'label': 'New', 'count': newCount},
            {'label': 'Assigned', 'count': assignedCount},
            {'label': 'In Progress', 'count': inProgressCount},
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
                            : const Color(0xFF475569),
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

  Widget _buildRequestList(List<ServiceRequest> requests) {
    if (requests.isEmpty) {
      return const Center(child: Text(AppStrings.noRequestsFound));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16).copyWith(bottom: 80),
      itemCount: requests.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final req = requests[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4),
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
                      color: const Color(0xFF007FFF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: const Color(0xFF007FFF).withOpacity(0.2),
                      ),
                    ),
                    child: Text(
                      req.status.toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF007FFF),
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
              const SizedBox(height: 4),
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
                  if (req.status == 'new')
                    SizedBox(
                      width: 100,
                      height: 36,
                      child: CustomButton(
                        text: AppStrings.assign,
                        onPressed: () => _showAssignBottomSheet(context, req),
                        height: 36,
                        borderRadius: 8,
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
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
          onAssign: (techName, notes) {
            final updatedRequest = request.copyWith(status: 'assigned');
            dispatchBloc.add(UpdateServiceRequest(updatedRequest));
          },
        );
      },
    );
  }
}

class _AssignTechnicianSheet extends StatefulWidget {
  final ServiceRequest request;
  final Function(String, String) onAssign;

  const _AssignTechnicianSheet({required this.request, required this.onAssign});

  @override
  State<_AssignTechnicianSheet> createState() => _AssignTechnicianSheetState();
}

class _AssignTechnicianSheetState extends State<_AssignTechnicianSheet> {
  String? _selectedTechnician;
  final TextEditingController _notesController = TextEditingController();
  final TechnicianRepository _technicianRepository = TechnicianRepository();

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
                    value: _selectedTechnician,
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
                            value: e.name,
                            child: SubRegularText(
                              text: '${e.name} (${e.status})',
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedTechnician = val;
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
