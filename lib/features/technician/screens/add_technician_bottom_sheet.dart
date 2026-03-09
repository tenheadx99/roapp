import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_strings.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/header_text.dart';
import '../bloc/technician_bloc.dart';
import '../models/technician.dart';

class AddTechnicianBottomSheet extends StatefulWidget {
  final Technician? technicianToEdit;

  const AddTechnicianBottomSheet({super.key, this.technicianToEdit});

  @override
  State<AddTechnicianBottomSheet> createState() =>
      _AddTechnicianBottomSheetState();
}

class _AddTechnicianBottomSheetState extends State<AddTechnicianBottomSheet> {
  String _name = '';
  String _phone = '';
  String _region = '';
  String _status = 'Available';

  final List<String> _statuses = ['Available', 'On Job', 'Offline'];

  @override
  void initState() {
    super.initState();
    if (widget.technicianToEdit != null) {
      _name = widget.technicianToEdit!.name;
      _phone = widget.technicianToEdit!.phone;
      _region = widget.technicianToEdit!.region;

      // Map legacy/db status to valid dropdown status
      String status = widget.technicianToEdit!.status;
      if (status == 'online') {
        _status = 'Available';
      } else if (status == 'on-leave' || status == 'offline') {
        _status = 'Offline';
      } else if (status == 'busy') {
        _status = 'On Job';
      } else if (_statuses.contains(status)) {
        _status = status;
      } else {
        _status = _statuses.first; // Default fallback
      }
    }
  }

  void _submitForm() {
    if (_name.trim().isEmpty || _phone.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.namePhoneRequired)),
      );
      return;
    }

    final newTech = Technician(
      id: widget.technicianToEdit?.id ?? const Uuid().v4(),
      name: _name.trim(),
      phone: _phone.trim(),
      region: _region.trim().isNotEmpty ? _region.trim() : 'Unassigned',
      status: _status,
      hubs: widget.technicianToEdit?.hubs ?? [],
      tasksToday: widget.technicianToEdit?.tasksToday ?? 0,
      avatar:
          widget.technicianToEdit?.avatar ??
          'https://i.pravatar.cc/150?u=${const Uuid().v4()}',
    );

    if (widget.technicianToEdit != null) {
      context.read<TechnicianBloc>().add(UpdateTechnician(newTech));
    } else {
      context.read<TechnicianBloc>().add(AddTechnician(newTech));
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
              text: widget.technicianToEdit == null
                  ? AppStrings.addTechnician
                  : AppStrings.editTechnician,
              fontSize: 20,
            ),
            const SizedBox(height: 24),
            CustomTextField(
              initialValue: _name,
              onChanged: (val) => _name = val,
              hintText: AppStrings.fullName,
              prefixIcon: const Icon(Icons.person_outline),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              initialValue: _phone,
              onChanged: (val) => _phone = val,
              hintText: AppStrings.phoneNumberPlaceholder,
              prefixIcon: const Icon(Icons.phone_outlined),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              initialValue: _region,
              onChanged: (val) => _region = val,
              hintText: AppStrings.regionHint,
              prefixIcon: const Icon(Icons.map_outlined),
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
              items: _statuses.map((s) {
                return DropdownMenuItem(value: s, child: Text(s));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _status = val);
              },
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: AppStrings.saveTechnician,
              onPressed: _submitForm,
            ),
          ],
        ),
      ),
    );
  }
}
