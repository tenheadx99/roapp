import 'package:flutter/material.dart';
import '../../../widgets/semi_bold_text_view.dart';
import '../../../widgets/sub_regular_text.dart';

class ScheduledServicesScreen extends StatelessWidget {
  final List<dynamic> scheduledServices;

  const ScheduledServicesScreen({
    super.key,
    required this.scheduledServices,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        title: const Text(
          'Scheduled Services',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: scheduledServices.isEmpty
          ? const Center(child: Text('No scheduled services found.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: scheduledServices.length,
              itemBuilder: (context, index) {
                final service = scheduledServices[index];
                return _buildServiceCard(service);
              },
            ),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.build_circle_outlined, color: Colors.blue.shade600),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SemiBoldTextView(
                  text: service['title'] ?? 'Service',
                  fontSize: 14,
                ),
                const SizedBox(height: 4),
                SubRegularText(
                  text: 'Customer: ${service['customerName']}',
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      service['time'] ?? '',
                      style: const TextStyle(
                        color: Color(0xFF007FFF),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (service['status'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: service['status'] == 'Pending'
                              ? Colors.orange.shade50
                              : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          service['status'],
                          style: TextStyle(
                            fontSize: 10,
                            color: service['status'] == 'Pending'
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
  }
}
