import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/custom_autocomplete_field.dart';
import '../../../widgets/header_text.dart';
import '../../supplier/repositories/supplier_repository.dart';
import '../bloc/inventory_bloc.dart';
import '../models/inventory_item.dart';

class AddInventoryItemBottomSheet extends StatefulWidget {
  final InventoryItem? itemToEdit;

  const AddInventoryItemBottomSheet({super.key, this.itemToEdit});

  @override
  State<AddInventoryItemBottomSheet> createState() =>
      _AddInventoryItemBottomSheetState();
}

class _AddInventoryItemBottomSheetState
    extends State<AddInventoryItemBottomSheet> {
  String _name = '';
  String _sku = '';
  String _supplier = '';
  String _price = '';
  String _stock = '';
  String _lowStockThreshold = '';
  String _selectedCategory = 'Filters';
  List<String> _existingSuppliers = [];
  bool _isEditing = true;

  final List<String> _categories = [
    'Filters',
    'Membranes',
    'Pumps',
    'UV Lamps',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.itemToEdit != null) {
      _name = widget.itemToEdit!.name;
      _sku = widget.itemToEdit!.sku;
      _supplier = widget.itemToEdit!.supplier;
      _price = widget.itemToEdit!.price.toString();
      _stock = widget.itemToEdit!.stock.toString();
      _lowStockThreshold = widget.itemToEdit!.lowStockThreshold.toString();
      _selectedCategory = widget.itemToEdit!.category;
      _isEditing = false;
    }
    _loadSuppliers();
  }

  Future<void> _loadSuppliers() async {
    try {
      final suppliers = await SupplierRepository().getSuppliers();
      if (mounted) {
        setState(() {
          _existingSuppliers = suppliers.map((s) => s.name).toList();
        });
      }
    } catch (e) {
      // Ignore errors silently for now, generic text field behavior takes over.
    }
  }

  void _submitForm() {
    if (_name.trim().isEmpty || _sku.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and SKU are required')),
      );
      return;
    }

    final priceValue = double.tryParse(_price.trim()) ?? 0.0;
    final stockValue = int.tryParse(_stock.trim()) ?? 0;
    final thresholdValue = int.tryParse(_lowStockThreshold.trim()) ?? 0;

    final newItem = InventoryItem(
      id: widget.itemToEdit?.id ?? const Uuid().v4(),
      name: _name.trim(),
      sku: _sku.trim(),
      supplier: _supplier.trim().isNotEmpty
          ? _supplier.trim()
          : 'Unknown Supplier',
      price: priceValue,
      stock: stockValue,
      lowStockThreshold: thresholdValue,
      category: _selectedCategory,
    );

    if (widget.itemToEdit != null) {
      context.read<InventoryBloc>().add(UpdateInventoryItem(newItem));
    } else {
      context.read<InventoryBloc>().add(AddInventoryItem(newItem));
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: HeaderText(
                    text: widget.itemToEdit == null
                        ? "Add Inventory Item"
                        : (_isEditing
                              ? "Edit Inventory Item"
                              : "Inventory Item Details"),
                    fontSize: 20,
                  ),
                ),
                if (widget.itemToEdit != null && !_isEditing)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _isEditing = true;
                      });
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF007FFF),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            CustomTextField(
              initialValue: _name,
              onChanged: (val) => _name = val,
              hintText: "Item Name",
              readOnly: !_isEditing,
              prefixIcon: const Icon(Icons.inventory_2_outlined),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              initialValue: _sku,
              onChanged: (val) => _sku = val,
              hintText: "SKU (e.g. RO-MEM-75)",
              readOnly: !_isEditing,
              prefixIcon: const Icon(Icons.qr_code_2),
            ),
            const SizedBox(height: 16),
            CustomAutocompleteField(
              initialValue: _supplier,
              options: _existingSuppliers,
              onChanged: (val) => _supplier = val,
              hintText: "Supplier Name",
              readOnly: !_isEditing,
              prefixIcon: const Icon(Icons.business_outlined),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    initialValue: _stock,
                    onChanged: (val) => _stock = val,
                    hintText: "Current Stock",
                    readOnly: !_isEditing,
                    prefixIcon: const Icon(Icons.numbers),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomTextField(
                    initialValue: _lowStockThreshold,
                    onChanged: (val) => _lowStockThreshold = val,
                    hintText: "Low Threshold",
                    readOnly: !_isEditing,
                    prefixIcon: const Icon(Icons.warning_amber_rounded),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    initialValue: _price,
                    onChanged: (val) => _price = val,
                    hintText: "Price",
                    readOnly: !_isEditing,
                    prefixIcon: const Icon(Icons.attach_money),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
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
                    items: _categories.map((cat) {
                      return DropdownMenuItem(value: cat, child: Text(cat));
                    }).toList(),
                    onChanged: _isEditing
                        ? (val) {
                            if (val != null)
                              setState(() => _selectedCategory = val);
                          }
                        : null,
                    disabledHint: Text(
                      _selectedCategory,
                      style: const TextStyle(color: Color(0xFF64748B)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            if (_isEditing)
              CustomButton(text: "Save Item", onPressed: _submitForm),
          ],
        ),
      ),
    );
  }
}
