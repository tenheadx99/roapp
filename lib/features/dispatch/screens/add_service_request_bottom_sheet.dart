import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/header_text.dart';
import '../../inventory/models/inventory_item.dart';
import '../../inventory/repositories/inventory_repository.dart';
import '../../technician/models/technician.dart';
import '../../technician/repositories/technician_repository.dart';
import '../bloc/dispatch_bloc.dart';
import '../models/service_request.dart';
import '../models/service_request_inventory_item.dart';

class AddServiceRequestBottomSheet extends StatefulWidget {
  final ServiceRequest? requestToEdit;
  final String? initialCustomerId;
  final String? initialCustomerName;
  final String? initialAddress;
  final String? initialModel;

  const AddServiceRequestBottomSheet({
    super.key,
    this.requestToEdit,
    this.initialCustomerId,
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
  String? _customerId;
  String _customerName = '';
  String _address = '';
  String _type = 'RO Filter Change';
  String _model = '';
  String _notes = '';
  DateTime? _scheduledFor;
  String _assignmentMode = 'later';
  String? _selectedTechnicianId;
  String? _selectedTechnicianName;

  List<InventoryItem> _inventoryOptions = const [];
  List<Technician> _technicians = const [];
  List<ServiceRequestInventoryItem> _inventoryItems = const [];
  bool _isLoadingSupportData = true;

  final List<String> _types = [
    'RO Filter Change',
    'Motor Repair',
    'Routine Maintenance',
    'New Installation',
    'AMC Service',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _hydrateInitialValues();
    _loadSupportData();
  }

  void _hydrateInitialValues() {
    if (widget.requestToEdit != null) {
      final request = widget.requestToEdit!;
      _customerId = request.customerId;
      _customerName = request.customerName;
      _address = request.address;
      _model = request.model;
      _notes = request.notes ?? '';
      _inventoryItems = List<ServiceRequestInventoryItem>.from(
        request.inventoryItems,
      );

      if (_types.contains(request.type)) {
        _type = request.type;
      }

      if ((request.scheduledFor ?? '').isNotEmpty) {
        _scheduledFor = DateTime.tryParse(request.scheduledFor!);
      }

      if (request.hasAssignedTechnician) {
        _assignmentMode = 'now';
        _selectedTechnicianId = request.technicianId;
        _selectedTechnicianName = request.technicianName;
      }
      return;
    }

    _customerId = widget.initialCustomerId;
    _customerName = widget.initialCustomerName ?? '';
    _address = widget.initialAddress ?? '';
    _model = widget.initialModel ?? '';
  }

  Future<void> _loadSupportData() async {
    final inventoryRepository = InventoryRepository();
    final technicianRepository = TechnicianRepository();
    final inventory = await inventoryRepository.getInventory();
    final technicians = await technicianRepository.getTechnicians();

    if (!mounted) return;

    setState(() {
      _inventoryOptions = inventory;
      _technicians = technicians;
      _isLoadingSupportData = false;
      final matched = technicians
          .where(
            (tech) =>
                tech.id == _selectedTechnicianId ||
                tech.name == _selectedTechnicianName,
          )
          .cast<Technician?>()
          .firstOrNull;
      _selectedTechnicianId = matched?.id ?? _selectedTechnicianId;
      _selectedTechnicianName = matched?.name ?? _selectedTechnicianName;
    });
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

  Future<void> _showInventoryItemDialog({
    ServiceRequestInventoryItem? existingItem,
    int? editIndex,
  }) async {
    String? selectedInventoryId = existingItem?.inventoryItemId;
    final nameController = TextEditingController(
      text: existingItem?.name ?? '',
    );
    final quantityController = TextEditingController(
      text: (existingItem?.quantity ?? 1).toString(),
    );
    final priceController = TextEditingController(
      text: (existingItem?.unitPrice ?? 0).toStringAsFixed(2),
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final selectedInventory = _inventoryOptions
                .where((item) => item.id == selectedInventoryId)
                .cast<InventoryItem?>()
                .firstOrNull;

            return AlertDialog(
              title: Text(
                existingItem == null ? 'Add Inventory Item' : 'Edit Item',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedInventoryId,
                      decoration: _dropdownDecoration(
                        labelText: 'Pick from inventory',
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: '',
                          child: Text('Custom item'),
                        ),
                        ..._inventoryOptions.map(
                          (item) => DropdownMenuItem<String>(
                            value: item.id,
                            child: Text(
                              '${item.name} • ${item.stock} in stock',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          selectedInventoryId = (value ?? '').trim().isEmpty
                              ? null
                              : value;
                          final chosen = _inventoryOptions
                              .where((item) => item.id == selectedInventoryId)
                              .cast<InventoryItem?>()
                              .firstOrNull;
                          if (chosen != null) {
                            nameController.text = chosen.name;
                            priceController.text = chosen.price.toStringAsFixed(
                              2,
                            );
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: nameController,
                      hintText: 'Item name',
                      prefixIcon: const Icon(Icons.inventory_2_outlined),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: quantityController,
                            hintText: 'Qty',
                            prefixIcon: const Icon(Icons.numbers_outlined),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            controller: priceController,
                            hintText: 'Unit price',
                            prefixIcon: const Icon(Icons.currency_rupee),
                          ),
                        ),
                      ],
                    ),
                    if (selectedInventory != null) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Suggested price: ${formatRupee(selectedInventory.price, decimalDigits: 2)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    final itemName = nameController.text.trim();
                    final quantity =
                        int.tryParse(quantityController.text.trim()) ?? 0;
                    final unitPrice =
                        double.tryParse(priceController.text.trim()) ?? -1;

                    if (itemName.isEmpty || quantity <= 0 || unitPrice < 0) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Enter a valid item name, quantity, and price.',
                          ),
                        ),
                      );
                      return;
                    }

                    final lineItem = ServiceRequestInventoryItem(
                      inventoryItemId: selectedInventoryId,
                      name: itemName,
                      quantity: quantity,
                      unitPrice: unitPrice,
                    );

                    setState(() {
                      final nextItems = List<ServiceRequestInventoryItem>.from(
                        _inventoryItems,
                      );
                      if (editIndex != null) {
                        nextItems[editIndex] = lineItem;
                      } else {
                        nextItems.add(lineItem);
                      }
                      _inventoryItems = nextItems;
                    });

                    Navigator.of(dialogContext).pop();
                  },
                  child: Text(existingItem == null ? 'Add Item' : 'Save Item'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    quantityController.dispose();
    priceController.dispose();
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

  double get _serviceTotal =>
      _inventoryItems.fold(0, (sum, item) => sum + item.lineTotal);

  void _submitForm() {
    if (_customerName.trim().isEmpty || _address.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.nameAddressRequired)),
      );
      return;
    }

    if (_assignmentMode == 'now' &&
        (_selectedTechnicianId ?? '').trim().isEmpty &&
        (_selectedTechnicianName ?? '').trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a technician or choose assign later.'),
        ),
      );
      return;
    }

    final existingStatus = widget.requestToEdit?.status;
    final isWorkflowLocked =
        existingStatus == 'in_progress' || existingStatus == 'completed';
    final nextStatus = isWorkflowLocked
        ? existingStatus!
        : (_assignmentMode == 'now' ? 'assigned' : 'new');

    final newRequest = ServiceRequest(
      id: widget.requestToEdit?.id ?? const Uuid().v4(),
      customerId: _customerId,
      customerName: _customerName.trim(),
      address: _address.trim(),
      type: _type,
      model: _model.trim().isNotEmpty ? _model.trim() : 'Unknown Model',
      time: _scheduledFor != null
          ? _formatScheduleLabel(_scheduledFor!)
          : (widget.requestToEdit?.time ?? 'Schedule later'),
      status: nextStatus,
      scheduledFor: _scheduledFor?.toIso8601String(),
      technicianId: _assignmentMode == 'now' ? _selectedTechnicianId : null,
      technicianName: _assignmentMode == 'now' ? _selectedTechnicianName : null,
      notes: _notes.trim().isEmpty ? null : _notes.trim(),
      inventoryItems: _inventoryItems,
      totalAmount: _serviceTotal,
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
    final isEditing = widget.requestToEdit != null;

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
              text: isEditing ? 'Edit Service' : 'Create Service',
              fontSize: 20,
            ),
            const SizedBox(height: 8),
            Text(
              'Create the customer first, then add service details, schedule, technician, and parts here.',
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 24),
            CustomTextField(
              initialValue: _customerName,
              onChanged: (val) => _customerName = val,
              hintText: AppStrings.customerName,
              prefixIcon: const Icon(Icons.person_outline),
              readOnly: (_customerId ?? '').trim().isNotEmpty,
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
            DropdownButtonFormField<String>(
              value: _type,
              decoration: _dropdownDecoration(labelText: 'Service type'),
              items: _types
                  .map(
                    (type) => DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _type = value);
                }
              },
            ),
            const SizedBox(height: 20),
            _buildSectionCard(
              title: 'Schedule',
              subtitle: _scheduledFor == null
                  ? 'Choose a date and time now, or leave it to plan later.'
                  : _formatScheduleLabel(_scheduledFor!),
              child: Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: _scheduledFor == null
                          ? 'Set Schedule'
                          : 'Change Schedule',
                      onPressed: _pickSchedule,
                      height: 44,
                      borderRadius: 10,
                    ),
                  ),
                  if (_scheduledFor != null) ...[
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () => setState(() => _scheduledFor = null),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(100, 44),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      child: const Text('Clear'),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'Assignment',
              subtitle: _assignmentMode == 'now'
                  ? 'Assign this service immediately.'
                  : 'Keep it unassigned for now and plan later.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ChoiceChip(
                        label: const Text('Assign Later'),
                        selected: _assignmentMode == 'later',
                        onSelected: (_) {
                          setState(() {
                            _assignmentMode = 'later';
                            _selectedTechnicianId = null;
                            _selectedTechnicianName = null;
                          });
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Assign Now'),
                        selected: _assignmentMode == 'now',
                        onSelected: (_) {
                          setState(() => _assignmentMode = 'now');
                        },
                      ),
                    ],
                  ),
                  if (_assignmentMode == 'now') ...[
                    const SizedBox(height: 14),
                    if (_isLoadingSupportData)
                      const LinearProgressIndicator(minHeight: 2)
                    else
                      DropdownButtonFormField<String>(
                        value: _selectedTechnicianId,
                        decoration: _dropdownDecoration(
                          labelText: 'Technician',
                        ),
                        items: _technicians
                            .map(
                              (tech) => DropdownMenuItem<String>(
                                value: tech.id,
                                child: Text('${tech.name} (${tech.status})'),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          final selectedTech = _technicians
                              .where((tech) => tech.id == value)
                              .cast<Technician?>()
                              .firstOrNull;
                          setState(() {
                            _selectedTechnicianId = value;
                            _selectedTechnicianName = selectedTech?.name;
                          });
                        },
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'Inventory & Pricing',
              subtitle:
                  'Add the parts planned for this service and adjust prices if needed.',
              action: TextButton.icon(
                onPressed: () => _showInventoryItemDialog(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Item'),
              ),
              child: Column(
                children: [
                  if (_inventoryItems.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'No parts added yet. You can add filters, membranes, pumps, or custom line items.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    )
                  else
                    ..._inventoryItems.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return Container(
                        margin: EdgeInsets.only(
                          bottom: index == _inventoryItems.length - 1 ? 0 : 12,
                        ),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${item.quantity} x ${formatRupee(item.unitPrice, decimalDigits: 2)}',
                                        style: const TextStyle(
                                          color: Color(0xFF64748B),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  formatRupee(item.lineTotal, decimalDigits: 2),
                                  style: const TextStyle(
                                    color: Color(0xFF007FFF),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => _showInventoryItemDialog(
                                    existingItem: item,
                                    editIndex: index,
                                  ),
                                  child: const Text('Edit'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      final nextItems =
                                          List<
                                            ServiceRequestInventoryItem
                                          >.from(_inventoryItems);
                                      nextItems.removeAt(index);
                                      _inventoryItems = nextItems;
                                    });
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  child: const Text('Remove'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Service Total',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF334155),
                        ),
                      ),
                      Text(
                        formatRupee(_serviceTotal, decimalDigits: 2),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              initialValue: _notes,
              onChanged: (val) => _notes = val,
              hintText: AppStrings.serviceNotesHint,
              prefixIcon: const Icon(Icons.sticky_note_2_outlined),
            ),
            const SizedBox(height: 28),
            CustomButton(
              text: isEditing ? 'Save Service' : 'Create Service',
              onPressed: _submitForm,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required Widget child,
    Widget? action,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              if (action != null) action,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  InputDecoration _dropdownDecoration({String? labelText}) {
    return InputDecoration(
      labelText: labelText,
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

extension<T> on Iterable<T?> {
  T? get firstOrNull {
    for (final value in this) {
      if (value != null) {
        return value;
      }
    }
    return null;
  }
}
