import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_strings.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/header_text.dart';
import '../bloc/dispatch_bloc.dart';
import '../models/service_request.dart';

class AddServiceRequestBottomSheet extends StatefulWidget {
  final ServiceRequest? requestToEdit;
  final String? initialCustomerName;
  final String? initialAddress;
  final String? initialModel;

  const AddServiceRequestBottomSheet({
    super.key,
    this.requestToEdit,
    this.initialCustomerName,
    this.initialAddress,
    this.initialModel,
  });

  @override
  State<AddServiceRequestBottomSheet> createState() =>
      _AddServiceRequestBottomSheetState();
}

class _AddServiceRequestBottomSheetState
    extends State<AddServiceRequestBottomSheet> {
  String _customerName = '';
  String _address = '';
  String _type = 'RO Filter Change';
  String _model = '';
  String _status = 'new';
  String _notes = '';
  DateTime? _scheduledFor;

  final List<String> _types = [
    'RO Filter Change',
    'Motor Repair',
    'Routine Maintenance',
    'New Installation',
    'Other',
  ];

  final List<String> _statuses = [
    'new',
    'assigned',
    'in_progress',
    'completed',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.requestToEdit != null) {
      _customerName = widget.requestToEdit!.customerName;
      _address = widget.requestToEdit!.address;
      _model = widget.requestToEdit!.model;
      _notes = widget.requestToEdit!.notes ?? '';

      final type = widget.requestToEdit!.type;
      if (_types.contains(type)) {
        _type = type;
      }

      final status = widget.requestToEdit!.status;
      if (_statuses.contains(status)) {
        _status = status;
      }

      final scheduledFor = widget.requestToEdit!.scheduledFor;
      if ((scheduledFor ?? '').isNotEmpty) {
        _scheduledFor = DateTime.tryParse(scheduledFor!);
      }
    } else {
      _customerName = widget.initialCustomerName ?? '';
      _address = widget.initialAddress ?? '';
      _model = widget.initialModel ?? '';
    }
  }

  Future<void> _pickSchedule() async {
    final now = DateTime.now();
    final initialDate = _scheduledFor ?? now;
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );

    if (selectedDate == null || !mounted) return;

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledFor ?? now),
    );

    if (selectedTime == null) return;

    setState(() {
      _scheduledFor = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );
    });
  }

  String _formatScheduleLabel(DateTime date) {
    final hour24 = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour24 >= 12 ? 'PM' : 'AM';
    final hour12 = hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24);
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
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year} • $hour12:$minute $period';
  }

  void _submitForm() {
    if (_customerName.trim().isEmpty || _address.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.nameAddressRequired)),
      );
      return;
    }

    final newRequest = ServiceRequest(
      id: widget.requestToEdit?.id ?? const Uuid().v4(),
      customerName: _customerName.trim(),
      address: _address.trim(),
      type: _type,
      model: _model.trim().isNotEmpty ? _model.trim() : 'Unknown Data',
      time: _scheduledFor != null
          ? _formatScheduleLabel(_scheduledFor!)
          : (widget.requestToEdit?.time ?? 'ASAP'),
      status: _status,
      scheduledFor: _scheduledFor?.toIso8601String(),
      technicianName: widget.requestToEdit?.technicianName,
      notes: _notes.trim().isEmpty ? null : _notes.trim(),
    );

    if (widget.requestToEdit != null) {
      context.read<DispatchBloc>().add(UpdateServiceRequest(newRequest));
    } else {
      context.read<DispatchBloc>().add(AddServiceRequest(newRequest));
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 24,
        bottom: bottomPadding + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            HeaderText(
              text: widget.requestToEdit == null
                  ? AppStrings.newServiceRequest
                  : AppStrings.editRequest,
              fontSize: 20,
            ),
            const SizedBox(height: 24),
            CustomTextField(
              initialValue: _customerName,
              onChanged: (val) => _customerName = val,
              hintText: AppStrings.customerName,
              prefixIcon: const Icon(Icons.person_outline),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              initialValue: _address,
              onChanged: (val) => _address = val,
              hintText: AppStrings.address,
              prefixIcon: const Icon(Icons.location_on_outlined),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              initialValue: _model,
              onChanged: (val) => _model = val,
              hintText: AppStrings.unitModel,
              prefixIcon: const Icon(Icons.water_drop_outlined),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              initialValue: _scheduledFor != null
                  ? _formatScheduleLabel(_scheduledFor!)
                  : widget.requestToEdit?.time,
              onTap: _pickSchedule,
              hintText: AppStrings.selectDateTime,
              readOnly: true,
              prefixIcon: const Icon(Icons.calendar_month_outlined),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              initialValue: _notes,
              onChanged: (val) => _notes = val,
              hintText: AppStrings.serviceNotesHint,
              prefixIcon: const Icon(Icons.sticky_note_2_outlined),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: _type,
                    decoration: _dropdownDecoration(),
                    items: _types
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _type = val);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    value: _status,
                    decoration: _dropdownDecoration(),
                    items: _statuses.map((s) {
                      return DropdownMenuItem(
                        value: s,
                        child: Text(
                          s.replaceAll('_', ' ').toUpperCase(),
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _status = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            CustomButton(text: AppStrings.saveRequest, onPressed: _submitForm),
          ],
        ),
      ),
    );
  }

  InputDecoration _dropdownDecoration() {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF007FFF)),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }
}
