import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/header_text.dart';
import '../bloc/supplier_bloc.dart';
import '../models/supplier.dart';

class AddSupplierBottomSheet extends StatefulWidget {
  final Supplier? supplierToEdit;

  const AddSupplierBottomSheet({super.key, this.supplierToEdit});

  @override
  State<AddSupplierBottomSheet> createState() => _AddSupplierBottomSheetState();
}

class _AddSupplierBottomSheetState extends State<AddSupplierBottomSheet> {
  String _name = '';
  String _contactPerson = '';
  String _city = '';
  String _specialties = '';
  String _status = 'active';

  @override
  void initState() {
    super.initState();
    if (widget.supplierToEdit != null) {
      _name = widget.supplierToEdit!.name;
      _contactPerson = widget.supplierToEdit!.contactPerson;
      _city = widget.supplierToEdit!.city;
      _specialties = widget.supplierToEdit!.specialties.join(', ');
      _status = widget.supplierToEdit!.status;
    }
  }

  void _submitForm() {
    if (_name.trim().isEmpty || _city.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and City are required')),
      );
      return;
    }

    final newSupplier = Supplier(
      id: widget.supplierToEdit?.id ?? const Uuid().v4(),
      name: _name.trim(),
      contactPerson: _contactPerson.trim().isNotEmpty
          ? _contactPerson.trim()
          : 'N/A',
      city: _city.trim(),
      specialties: _specialties
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      activePOs: widget.supplierToEdit?.activePOs ?? 0,
      status: _status,
    );

    if (widget.supplierToEdit != null) {
      context.read<SupplierBloc>().add(UpdateSupplier(newSupplier));
    } else {
      context.read<SupplierBloc>().add(AddSupplier(newSupplier));
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
              text: widget.supplierToEdit == null
                  ? "Add Supplier"
                  : "Edit Supplier",
              fontSize: 20,
            ),
            const SizedBox(height: 24),
            CustomTextField(
              initialValue: _name,
              onChanged: (val) => _name = val,
              hintText: "Supplier Name",
              prefixIcon: const Icon(Icons.business),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              initialValue: _contactPerson,
              onChanged: (val) => _contactPerson = val,
              hintText: "Contact Person",
              prefixIcon: const Icon(Icons.person_outline),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              initialValue: _city,
              onChanged: (val) => _city = val,
              hintText: "City",
              prefixIcon: const Icon(Icons.location_city),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              initialValue: _specialties,
              onChanged: (val) => _specialties = val,
              hintText: "Specialties (Comma Separated)",
              prefixIcon: const Icon(Icons.category_outlined),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
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
              items: const [
                DropdownMenuItem(value: 'active', child: Text('Active')),
                DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _status = val);
              },
            ),
            const SizedBox(height: 32),
            CustomButton(text: "Save Supplier", onPressed: _submitForm),
          ],
        ),
      ),
    );
  }
}
