import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
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
  String _time = '';
  String _status = 'new';

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
      _type = widget.requestToEdit!.type;
      _model = widget.requestToEdit!.model;
      _time = widget.requestToEdit!.time;
      _status = widget.requestToEdit!.status;
    } else {
      _customerName = widget.initialCustomerName ?? '';
      _address = widget.initialAddress ?? '';
      _model = widget.initialModel ?? '';
    }
  }

  void _submitForm() {
    if (_customerName.trim().isEmpty || _address.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer Name and Address are required')),
      );
      return;
    }

    final newRequest = ServiceRequest(
      id: widget.requestToEdit?.id ?? const Uuid().v4(),
      customerName: _customerName.trim(),
      address: _address.trim(),
      type: _type,
      model: _model.trim().isNotEmpty ? _model.trim() : 'Unknown Data',
      time: _time.trim().isNotEmpty ? _time.trim() : 'ASAP',
      status: _status,
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
                  ? "New Service Request"
                  : "Edit Request",
              fontSize: 20,
            ),
            const SizedBox(height: 24),
            CustomTextField(
              initialValue: _customerName,
              onChanged: (val) => _customerName = val,
              hintText: "Customer Name",
              prefixIcon: const Icon(Icons.person_outline),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              initialValue: _address,
              onChanged: (val) => _address = val,
              hintText: "Address",
              prefixIcon: const Icon(Icons.location_on_outlined),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              initialValue: _model,
              onChanged: (val) => _model = val,
              hintText: "Unit Model",
              prefixIcon: const Icon(Icons.water_drop_outlined),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: _type,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
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
                    ),
                    items: _types.map((t) {
                      return DropdownMenuItem(value: t, child: Text(t));
                    }).toList(),
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
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
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
                    ),
                    items: _statuses.map((s) {
                      return DropdownMenuItem(
                        value: s,
                        child: Text(
                          s.toUpperCase(),
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
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null && mounted) {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time != null && mounted) {
                    setState(() {
                      _time =
                          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${time.format(context)}";
                    });
                  }
                }
              },
              child: IgnorePointer(
                child: TextFormField(
                  controller: TextEditingController(text: _time),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    hintText: "Select Date & Time",
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.calendar_month),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF007FFF),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            CustomButton(text: "Save Request", onPressed: _submitForm),
          ],
        ),
      ),
    );
  }
}
