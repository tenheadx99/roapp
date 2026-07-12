import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_strings.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/regular_text_view.dart';
import '../../../widgets/semi_bold_text_view.dart';
import '../../../widgets/sub_regular_text.dart';
import '../bloc/technician_bloc.dart';
import '../models/technician.dart';
import './add_technician_bottom_sheet.dart';

class TechniciansScreen extends StatelessWidget {
  const TechniciansScreen({super.key});

  void _showAddTechnicianSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => BlocProvider.value(
        value: context.read<TechnicianBloc>(),
        child: const AddTechnicianBottomSheet(),
      ),
    );
  }

  void _showEditTechnicianSheet(BuildContext context, Technician tech) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => BlocProvider.value(
        value: context.read<TechnicianBloc>(),
        child: AddTechnicianBottomSheet(technicianToEdit: tech),
      ),
    );
  }

  void _showScheduleSheet(BuildContext context, Technician tech) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Schedule: ${tech.name}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const ListTile(
              leading: Icon(Icons.access_time),
              title: Text('10:00 AM - 12:00 PM'),
              subtitle: Text('Filter Replacement - Ravi Kumar'),
            ),
            const ListTile(
              leading: Icon(Icons.access_time),
              title: Text('02:00 PM - 04:00 PM'),
              subtitle: Text('Repair Service - Anita Singh'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _launchPhone(String phone) async {
    final Uri url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _launchWhatsApp(String phone) async {
    // Basic formatting: remove spaces and non-digits
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final Uri url = Uri.parse('https://wa.me/$cleanPhone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TechnicianBloc()..add(LoadTechnicians()),
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: const Text(
                AppStrings.technicians,
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
            ),
            body: Column(
              children: [
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          BlocBuilder<TechnicianBloc, TechnicianState>(
                            builder: (context, state) {
                              int count = 0;
                              if (state is TechnicianLoaded) {
                                count = state.allTechnicians.length;
                              }
                              return SemiBoldTextView(
                                text: '$count ${AppStrings.activeTeamMembers}',
                                color: const Color(0xFF64748B),
                                fontSize: 14,
                              );
                            },
                          ),
                          GestureDetector(
                            onTap: () => _showAddTechnicianSheet(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF007FFF),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF007FFF,
                                    ).withValues(alpha: 0.2),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.person_add_alt_1,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      BlocBuilder<TechnicianBloc, TechnicianState>(
                        builder: (context, state) {
                          return CustomTextField(
                            hintText: AppStrings.searchTechHint,
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Color(0xFF94A3B8),
                            ),
                            onChanged: (val) {
                              context.read<TechnicianBloc>().add(
                                SearchTechnicians(val),
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: BlocBuilder<TechnicianBloc, TechnicianState>(
                          builder: (context, state) {
                            String activeFilter = 'All';
                            List<String> dynamicFilters = ['All'];

                            if (state is TechnicianLoaded) {
                              activeFilter = state.activeFilter;
                              final regions = state.allTechnicians
                                  .map((t) => t.region)
                                  .toSet()
                                  .toList();
                              regions.sort();
                              dynamicFilters.addAll(regions);
                            }

                            return Row(
                              children: dynamicFilters
                                  .map(
                                    (label) => Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: _buildFilterChip(
                                        context,
                                        label,
                                        activeFilter,
                                      ),
                                    ),
                                  )
                                  .toList(),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: BlocBuilder<TechnicianBloc, TechnicianState>(
                    builder: (context, state) {
                      if (state is TechnicianLoading ||
                          state is TechnicianInitial) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (state is TechnicianError) {
                        return Center(child: Text(state.message));
                      } else if (state is TechnicianLoaded) {
                        final techs = state.filteredTechnicians;
                        if (techs.isEmpty) {
                          return const Center(
                            child: Text(AppStrings.noTechniciansFound),
                          );
                        }
                        return RefreshIndicator(
                          onRefresh: () async => context
                              .read<TechnicianBloc>()
                              .add(LoadTechnicians()),
                          child: ListView.separated(
                            padding: const EdgeInsets.all(
                              16,
                            ).copyWith(bottom: 24),
                            itemCount: techs.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              return _buildTechCard(context, techs[index]);
                            },
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    String label,
    String activeFilter,
  ) {
    final isSelected = label == activeFilter;
    return GestureDetector(
      onTap: () {
        context.read<TechnicianBloc>().add(FilterTechnicians(label));
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
        child: SemiBoldTextView(
          text: label,
          fontSize: 12,
          color: isSelected ? Colors.white : const Color(0xFF475569),
        ),
      ),
    );
  }

  Widget _buildTechCard(BuildContext context, Technician tech) {
    Color statusColor;
    if (tech.status == 'online' || tech.status == 'Available') {
      statusColor = Colors.green.shade500;
    } else if (tech.status == 'on-leave' || tech.status == 'Offline') {
      statusColor = Colors.grey.shade400;
    } else {
      statusColor = Colors.orange.shade500; // On Job
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  if (tech.avatar != null && tech.avatar!.isNotEmpty)
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: NetworkImage(tech.avatar!),
                    )
                  else
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.grey.shade200,
                      child: Text(
                        tech.name
                            .split(' ')
                            .map((e) => e.isNotEmpty ? e[0] : '')
                            .join(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: tech.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                                if (tech.status == 'on-leave' ||
                                    tech.status == 'Offline')
                                  TextSpan(
                                    text: ' (${tech.status})',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => _launchPhone(tech.phone),
                              icon: const Icon(
                                Icons.phone_outlined,
                                size: 18,
                                color: Color(0xFF007FFF),
                              ),
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              onPressed: () => _launchWhatsApp(tech.phone),
                              icon: const Icon(
                                FontAwesomeIcons.whatsapp,
                                size: 18,
                                color: Colors.green,
                              ),
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => _launchPhone(tech.phone),
                      child: SubRegularText(text: tech.phone),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF007FFF,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: SemiBoldTextView(
                            text: tech.region.toUpperCase(),
                            fontSize: 10,
                            color: const Color(0xFF007FFF),
                          ),
                        ),
                        ...tech.hubs
                            .where((h) => h.trim().isNotEmpty)
                            .map(
                              (hub) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF007FFF,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: SemiBoldTextView(
                                  text: hub.toUpperCase(),
                                  fontSize: 10,
                                  color: const Color(0xFF007FFF),
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
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.calendar_month,
                    size: 14,
                    color: Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 4),
                  RegularTextView(
                    text: tech.tasksToday > 0
                        ? '${tech.tasksToday} ${AppStrings.tasksToday}'
                        : (tech.status == 'on-leave' ||
                              tech.status == 'Offline')
                        ? AppStrings.nextAvailable
                        : AppStrings.noTasksToday,
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ],
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () => _showScheduleSheet(context, tech),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      AppStrings.viewSchedule,
                      style: TextStyle(
                        color: Color(0xFF007FFF),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => _showEditTechnicianSheet(context, tech),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      AppStrings.editProfile,
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
