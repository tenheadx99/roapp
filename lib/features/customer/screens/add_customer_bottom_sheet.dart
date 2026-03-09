import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/header_text.dart';
import '../bloc/customer_bloc.dart';
import '../models/customer.dart';

class AddCustomerBottomSheet extends StatefulWidget {
  final Customer? customerToEdit;

  const AddCustomerBottomSheet({super.key, this.customerToEdit});

  @override
  State<AddCustomerBottomSheet> createState() => _AddCustomerBottomSheetState();
}

class _AddCustomerBottomSheetState extends State<AddCustomerBottomSheet> {
  String _name = '';
  String _phone = '';
  String _model = '';
  String _area = '';
  String _selectedStatus = 'Operational';

  final List<String> _statusOptions = [
    'Operational',
    'Service Due',
    'AMC Plan',
    'Pending Install',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.customerToEdit != null) {
      _name = widget.customerToEdit!.name;
      _phone = widget.customerToEdit!.phone;
      _model = widget.customerToEdit!.model;
      _area = widget.customerToEdit!.area;

      final status = widget.customerToEdit!.status;
      if (_statusOptions.contains(status)) {
        _selectedStatus = status;
      } else {
        _selectedStatus = _statusOptions.first;
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _submitForm() {
    if (_name.trim().isEmpty || _phone.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and Phone are required')),
      );
      return;
    }

    final newCustomer = Customer(
      id: widget.customerToEdit?.id ?? const Uuid().v4(),
      name: _name.trim(),
      phone: _phone.trim(),
      model: _model.trim().isNotEmpty ? _model.trim() : 'Unknown Model',
      area: _area.trim().isNotEmpty ? _area.trim() : 'Unknown Area',
      status: _selectedStatus,
      lastService:
          widget.customerToEdit?.lastService ??
          'N/A', // Keep existing or set N/A
    );

    if (widget.customerToEdit != null) {
      context.read<CustomerBloc>().add(UpdateCustomer(newCustomer));
    } else {
      context.read<CustomerBloc>().add(AddCustomer(newCustomer));
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // Determine bottom padding for keyboard
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
              text: widget.customerToEdit == null
                  ? "Add Customer"
                  : "Edit Customer",
              fontSize: 20,
            ),
            const SizedBox(height: 24),
            CustomTextField(
              initialValue: _name,
              onChanged: (val) => _name = val,
              hintText: "Customer Name",
              prefixIcon: const Icon(Icons.person_outline),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              initialValue: _phone,
              onChanged: (val) => _phone = val,
              hintText: "Phone Number",
              prefixIcon: const Icon(Icons.phone_outlined),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              initialValue: _model,
              onChanged: (val) => _model = val,
              hintText: "Unit Model (e.g. Kent Grand+)",
              prefixIcon: const Icon(Icons.water_drop_outlined),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              initialValue: _area,
              onChanged: (val) => _area = val,
              hintText: "Area/Address",
              prefixIcon: const Icon(Icons.location_on_outlined),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedStatus,
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
                prefixIcon: const Icon(
                  Icons.info_outline,
                  color: Color(0xFF94A3B8),
                ),
              ),
              items: _statusOptions.map((status) {
                return DropdownMenuItem(value: status, child: Text(status));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedStatus = val);
              },
            ),
            const SizedBox(height: 32),
            CustomButton(text: "Save Customer", onPressed: _submitForm),
          ],
        ),
      ),
    );
  }
}
