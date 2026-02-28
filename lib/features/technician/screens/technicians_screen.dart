import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../widgets/custom_text_field.dart';

import '../../../widgets/sub_regular_text.dart';
import '../bloc/technician_bloc.dart';
import '../models/technician.dart';

class TechniciansScreen extends StatelessWidget {
  const TechniciansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TechnicianBloc()..add(LoadTechnicians()),
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: const Color(0xFFF5F7F8),
            appBar: AppBar(
              title: const Text(
                'Technicians',
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
                          const Text(
                            '12 Active Team Members',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF007FFF),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF007FFF,
                                  ).withOpacity(0.2),
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
                        ],
                      ),
                      const SizedBox(height: 16),
                      BlocBuilder<TechnicianBloc, TechnicianState>(
                        builder: (context, state) {
                          return CustomTextField(
                            hintText: "Search name or region...",
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
                            if (state is TechnicianLoaded) {
                              activeFilter = state.activeFilter;
                            }
                            return Row(
                              children: [
                                _buildFilterChip(context, 'All', activeFilter),
                                const SizedBox(width: 8),
                                _buildFilterChip(
                                  context,
                                  'North District',
                                  activeFilter,
                                ),
                                const SizedBox(width: 8),
                                _buildFilterChip(
                                  context,
                                  'Downtown',
                                  activeFilter,
                                ),
                                const SizedBox(width: 8),
                                _buildFilterChip(
                                  context,
                                  'Industrial Park',
                                  activeFilter,
                                ),
                              ],
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
                            child: Text('No technicians found.'),
                          );
                        }
                        return ListView.separated(
                          padding: const EdgeInsets.all(
                            16,
                          ).copyWith(bottom: 24),
                          itemCount: techs.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            return _buildTechCard(techs[index]);
                          },
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
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildTechCard(Technician tech) {
    Color statusColor;
    if (tech.status == 'online') {
      statusColor = Colors.green.shade500;
    } else if (tech.status == 'on-leave') {
      statusColor = Colors.grey.shade400;
    } else {
      statusColor = Colors.red.shade500;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4),
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
                                if (tech.status == 'on-leave')
                                  const TextSpan(
                                    text: ' (On Leave)',
                                    style: TextStyle(
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
                              onPressed: () {},
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
                              onPressed: () {},
                              icon: const Icon(
                                Icons.chat_bubble_outline,
                                size: 18,
                                color: Color(0xFF007FFF),
                              ),
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    SubRegularText(text: tech.phone),
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
                            color: const Color(0xFF007FFF).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tech.region.toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF007FFF),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        ...tech.hubs.map(
                          (hub) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF007FFF).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              hub.toUpperCase(),
                              style: const TextStyle(
                                color: Color(0xFF007FFF),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
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
                  Text(
                    tech.tasksToday > 0
                        ? '${tech.tasksToday} Tasks Today'
                        : tech.status == 'on-leave'
                        ? 'Next available: Mon'
                        : 'No tasks today',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'View Schedule',
                      style: TextStyle(
                        color: Color(0xFF007FFF),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Edit Profile',
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
