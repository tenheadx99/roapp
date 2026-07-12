import 'package:flutter/material.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/utils/currency_formatter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../../customer/models/customer.dart';
import '../../customer/repositories/customer_repository.dart';
import '../../operations/models/amc_contract.dart';
import '../../operations/models/communication_log.dart';
import '../../operations/models/invoice.dart';
import '../../operations/models/purchase_order.dart';
import '../../operations/models/service_attachment.dart';
import '../../operations/models/technician_schedule.dart';
import '../../operations/repositories/operations_repository.dart';
import '../../supplier/models/supplier.dart';
import '../../supplier/repositories/supplier_repository.dart';
import '../../technician/models/technician.dart';
import '../../technician/repositories/technician_repository.dart';
import '../../dispatch/models/service_request.dart';

class OperationsCenterScreen extends StatefulWidget {
  const OperationsCenterScreen({super.key});

  @override
  State<OperationsCenterScreen> createState() => _OperationsCenterScreenState();
}

class _OperationsCenterScreenState extends State<OperationsCenterScreen> {
  final OperationsRepository _operationsRepository = OperationsRepository();
  final CustomerRepository _customerRepository = CustomerRepository();
  final SupplierRepository _supplierRepository = SupplierRepository();
  final TechnicianRepository _technicianRepository = TechnicianRepository();
  final Uuid _uuid = const Uuid();

  bool _isLoading = true;
  List<Customer> _customers = const [];
  List<Supplier> _suppliers = const [];
  List<Technician> _technicians = const [];
  List<Invoice> _invoices = const [];
  List<AmcContract> _contracts = const [];
  List<CommunicationLog> _logs = const [];
  List<PurchaseOrder> _purchaseOrders = const [];
  List<TechnicianSchedule> _schedules = const [];
  List<ServiceAttachment> _attachments = const [];
  Map<String, dynamic> _overview = const {};

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _isLoading = true);
    final customers = await _customerRepository.getCustomers();
    final suppliers = await _supplierRepository.getSuppliers();
    final technicians = await _technicianRepository.getTechnicians();
    final invoices = await _operationsRepository.getInvoices();
    final sortedInvoices = List<Invoice>.from(invoices);
    sortedInvoices.sort((a, b) {
      if (a.isOverdue && !b.isOverdue) return -1;
      if (!a.isOverdue && b.isOverdue) return 1;

      final aUnpaid = a.balanceDue > 0.01;
      final bUnpaid = b.balanceDue > 0.01;
      if (aUnpaid && !bUnpaid) return -1;
      if (!aUnpaid && bUnpaid) return 1;

      final aDue = DateTime.tryParse(a.dueDate) ?? DateTime.now();
      final bDue = DateTime.tryParse(b.dueDate) ?? DateTime.now();
      return aDue.compareTo(bDue);
    });
    final contracts = await _operationsRepository.getContracts();
    final logs = await _operationsRepository.getCommunicationLogs();
    final orders = await _operationsRepository.getPurchaseOrders();
    final schedules = await _operationsRepository.getTechnicianSchedules();
    final attachments = await _operationsRepository.getAttachments();
    final overview = await _operationsRepository.getOperationsOverview();

    if (!mounted) return;
    setState(() {
      _customers = customers;
      _suppliers = suppliers;
      _technicians = technicians;
      _invoices = sortedInvoices;
      _contracts = contracts;
      _logs = logs;
      _purchaseOrders = orders;
      _schedules = schedules;
      _attachments = attachments;
      _overview = overview;
      _isLoading = false;
    });
  }

  String _customerName(String id) {
    for (final customer in _customers) {
      if (customer.id == id) {
        return customer.name;
      }
    }
    return 'Unknown customer';
  }

  String _supplierName(String id) {
    for (final supplier in _suppliers) {
      if (supplier.id == id) {
        return supplier.name;
      }
    }
    return 'Unknown supplier';
  }

  String _technicianName(String id) {
    for (final technician in _technicians) {
      if (technician.id == id) {
        return technician.name;
      }
    }
    return 'Unknown technician';
  }

  Future<void> _shareReport() async {
    final report = await _operationsRepository.buildOperationsReport();
    await Share.share(report, subject: 'RO Manager Operations Report');
  }

  Future<void> _showInvoiceSheet({Invoice? existing}) async {
    if (_customers.isEmpty) {
      _showMessage('Create a customer first to add an invoice.');
      return;
    }

    final completedRequests = existing == null
        ? await _operationsRepository
              .getCompletedServiceRequestsWithoutInvoice()
        : const <ServiceRequest>[];

    final totalController = TextEditingController(
      text: existing?.totalAmount.toStringAsFixed(0) ?? '',
    );
    final paidController = TextEditingController(
      text: existing?.paidAmount.toStringAsFixed(0) ?? '0',
    );
    final supplierPriceController = TextEditingController(
      text: existing?.supplierPrice.toStringAsFixed(0) ?? '',
    );
    final notesController = TextEditingController(text: existing?.notes ?? '');
    String selectedCustomerId = existing?.customerId ?? _customers.first.id;
    DateTime issueDate =
        DateTime.tryParse(existing?.issueDate ?? '') ?? DateTime.now();
    DateTime dueDate =
        DateTime.tryParse(existing?.dueDate ?? '') ??
        DateTime.now().add(const Duration(days: 7));
    String? selectedRequestId;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    existing == null ? 'Create Invoice' : 'Update Invoice',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (existing == null && completedRequests.isNotEmpty) ...[
                    DropdownButtonFormField<ServiceRequest?>(
                      value: null,
                      decoration: InputDecoration(
                        labelText: 'Import Completed Service (Optional)',
                        helperText:
                            'Select to auto-populate customer, total, and notes',
                        border: const OutlineInputBorder(),
                        prefixIcon: Icon(
                          Icons.build_circle_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<ServiceRequest?>(
                          value: null,
                          child: Text('-- Select to Auto-populate --'),
                        ),
                        ...completedRequests.map(
                          (req) => DropdownMenuItem<ServiceRequest?>(
                            value: req,
                            child: Text(
                              '${req.customerName} - ${req.type} (${req.time})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (req) async {
                        if (req == null) return;

                        double computedSupplierPrice = 0.0;
                        try {
                          final db = await DatabaseHelper.instance.database;
                          final itemIds = req.inventoryItems
                              .map((e) => e.inventoryItemId)
                              .whereType<String>()
                              .where((id) => id.isNotEmpty)
                              .toList();
                          if (itemIds.isNotEmpty) {
                            final placeholders = List.filled(itemIds.length, '?').join(', ');
                            final results = await db.rawQuery(
                              'SELECT id, supplierPrice FROM inventory WHERE id IN ($placeholders)',
                              itemIds,
                            );
                            final priceMap = {
                              for (final row in results)
                                row['id'] as String: (row['supplierPrice'] as num?)?.toDouble() ?? 0.0
                            };
                            for (final item in req.inventoryItems) {
                              final pCost = priceMap[item.inventoryItemId] ?? 0.0;
                              computedSupplierPrice += pCost * item.quantity;
                            }
                          }
                        } catch (e) {
                          // ignore
                        }

                        setSheetState(() {
                          final matchingCustomer = _customers.firstWhere(
                            (c) =>
                                c.id == req.customerId ||
                                c.name == req.customerName,
                            orElse: () => _customers.first,
                          );
                          selectedCustomerId = matchingCustomer.id;
                          totalController.text = req.totalAmount
                              .toStringAsFixed(0);
                          supplierPriceController.text = computedSupplierPrice.toStringAsFixed(0);
                          paidController.text = req.totalAmount.toStringAsFixed(
                            0,
                          );
                          notesController.text = req.notes?.isNotEmpty == true
                              ? req.notes!.trim()
                              : 'Auto-generated invoice from completed service request: ${req.type}.';
                          final reqDate =
                              DateTime.tryParse(req.completedAt ?? '') ??
                              DateTime.now();
                          issueDate = reqDate;
                          dueDate = reqDate;
                          selectedRequestId = req.id;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  DropdownButtonFormField<String>(
                    value: selectedCustomerId,
                    decoration: const InputDecoration(
                      labelText: 'Customer',
                      border: OutlineInputBorder(),
                    ),
                    items: _customers
                        .map(
                          (customer) => DropdownMenuItem(
                            value: customer.id,
                            child: Text(customer.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setSheetState(() => selectedCustomerId = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: totalController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Total Amount',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: supplierPriceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Supplier Price',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: paidController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Paid Amount',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2035),
                              initialDate: issueDate,
                            );
                            if (picked == null) return;
                            setSheetState(() => issueDate = picked);
                          },
                          icon: const Icon(Icons.calendar_today_outlined),
                          label: Text('Issue ${_formatDate(issueDate)}'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2035),
                              initialDate: dueDate,
                            );
                            if (picked == null) return;
                            setSheetState(() => dueDate = picked);
                          },
                          icon: const Icon(Icons.event_busy_outlined),
                          label: Text('Due ${_formatDate(dueDate)}'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () async {
                      final total = double.tryParse(
                        totalController.text.trim(),
                      );
                      final paid = double.tryParse(paidController.text.trim());
                      final supplierPrice = double.tryParse(
                        supplierPriceController.text.trim(),
                      ) ?? 0.0;
                      if (total == null || total <= 0) {
                        _showMessage('Enter a valid invoice amount.');
                        return;
                      }
                      if (paid == null || paid < 0) {
                        _showMessage('Enter a valid paid amount.');
                        return;
                      }

                      final invoiceId = selectedRequestId != null
                          ? 'inv-$selectedRequestId'
                          : (existing?.id ?? _uuid.v4());

                      String invoiceNumber = existing?.invoiceNumber ?? '';
                      if (invoiceNumber.isEmpty) {
                        if (selectedRequestId != null) {
                          final datePart =
                              '${issueDate.year}${issueDate.month.toString().padLeft(2, '0')}${issueDate.day.toString().padLeft(2, '0')}';
                          final suffix = selectedRequestId!.length >= 6
                              ? selectedRequestId!
                                    .substring(selectedRequestId!.length - 6)
                                    .toUpperCase()
                              : selectedRequestId!.toUpperCase();
                          invoiceNumber = 'SVC-$datePart-$suffix';
                        } else {
                          invoiceNumber =
                              'INV-${DateTime.now().millisecondsSinceEpoch}';
                        }
                      }

                      final invoice = Invoice(
                        id: invoiceId,
                        customerId: selectedCustomerId,
                        invoiceNumber: invoiceNumber,
                        issueDate: issueDate.toIso8601String(),
                        dueDate: dueDate.toIso8601String(),
                        totalAmount: total,
                        paidAmount: paid,
                        supplierPrice: supplierPrice,
                        status: paid >= total
                            ? 'paid'
                            : (dueDate.isBefore(DateTime.now())
                                  ? 'overdue'
                                  : 'due'),
                        notes: notesController.text.trim(),
                      );
                      await _operationsRepository.upsertInvoice(invoice);
                      if (!mounted) return;
                      Navigator.pop(context);
                      _showMessage(
                        existing == null
                            ? 'Invoice created.'
                            : 'Invoice updated.',
                      );
                      await _reload();
                    },
                    child: Text(
                      existing == null ? 'Save Invoice' : 'Update Invoice',
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showContractSheet({AmcContract? existing}) async {
    if (_customers.isEmpty) {
      _showMessage('Create a customer first to add a contract.');
      return;
    }
    final nameController = TextEditingController(
      text: existing?.contractName ?? 'Annual Maintenance Contract',
    );
    final visitsController = TextEditingController(
      text: existing?.visitsIncluded.toString() ?? '4',
    );
    final usedController = TextEditingController(
      text: existing?.visitsUsed.toString() ?? '0',
    );
    final amountController = TextEditingController(
      text: existing?.amount.toStringAsFixed(0) ?? '',
    );
    String selectedCustomerId = existing?.customerId ?? _customers.first.id;
    DateTime startDate =
        DateTime.tryParse(existing?.startDate ?? '') ?? DateTime.now();
    DateTime endDate =
        DateTime.tryParse(existing?.endDate ?? '') ??
        DateTime.now().add(const Duration(days: 365));
    DateTime reminderDate =
        DateTime.tryParse(existing?.renewalReminderDate ?? '') ??
        endDate.subtract(const Duration(days: 30));

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    existing == null
                        ? 'Create AMC Contract'
                        : 'Update AMC Contract',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCustomerId,
                    decoration: const InputDecoration(
                      labelText: 'Customer',
                      border: OutlineInputBorder(),
                    ),
                    items: _customers
                        .map(
                          (customer) => DropdownMenuItem(
                            value: customer.id,
                            child: Text(customer.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setSheetState(() => selectedCustomerId = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Contract Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: visitsController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Visits Included',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: usedController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Visits Used',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Contract Amount',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      OutlinedButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                            initialDate: startDate,
                          );
                          if (picked != null) {
                            setSheetState(() => startDate = picked);
                          }
                        },
                        child: Text('Start ${_formatDate(startDate)}'),
                      ),
                      OutlinedButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                            initialDate: endDate,
                          );
                          if (picked != null) {
                            setSheetState(() => endDate = picked);
                          }
                        },
                        child: Text('End ${_formatDate(endDate)}'),
                      ),
                      OutlinedButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                            initialDate: reminderDate,
                          );
                          if (picked != null) {
                            setSheetState(() => reminderDate = picked);
                          }
                        },
                        child: Text('Reminder ${_formatDate(reminderDate)}'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () async {
                      final visits = int.tryParse(visitsController.text.trim());
                      final used = int.tryParse(usedController.text.trim());
                      final amount = double.tryParse(
                        amountController.text.trim(),
                      );
                      if (nameController.text.trim().isEmpty ||
                          visits == null ||
                          used == null ||
                          amount == null) {
                        _showMessage('Fill in the contract details properly.');
                        return;
                      }
                      final now = DateTime.now();
                      final today = DateTime(now.year, now.month, now.day);
                      final endDay = DateTime(
                        endDate.year,
                        endDate.month,
                        endDate.day,
                      );
                      final contract = AmcContract(
                        id: existing?.id ?? _uuid.v4(),
                        customerId: selectedCustomerId,
                        contractName: nameController.text.trim(),
                        startDate: startDate.toIso8601String(),
                        endDate: endDate.toIso8601String(),
                        visitsIncluded: visits,
                        visitsUsed: used,
                        amount: amount,
                        status: endDay.isBefore(today) ? 'expired' : 'active',
                        renewalReminderDate: reminderDate.toIso8601String(),
                      );
                      await _operationsRepository.upsertContract(contract);
                      if (!mounted) return;
                      Navigator.pop(context);
                      _showMessage(
                        existing == null
                            ? 'AMC contract created.'
                            : 'AMC contract updated.',
                      );
                      await _reload();
                    },
                    child: Text(
                      existing == null ? 'Save Contract' : 'Update Contract',
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showCommunicationSheet() async {
    if (_customers.isEmpty) {
      _showMessage('Create a customer first to log communication.');
      return;
    }
    final noteController = TextEditingController();
    final createdByController = TextEditingController(text: 'Operations Desk');
    String selectedCustomerId = _customers.first.id;
    String selectedChannel = 'Call';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedCustomerId,
                    decoration: const InputDecoration(
                      labelText: 'Customer',
                      border: OutlineInputBorder(),
                    ),
                    items: _customers
                        .map(
                          (customer) => DropdownMenuItem(
                            value: customer.id,
                            child: Text(customer.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setSheetState(() => selectedCustomerId = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedChannel,
                    decoration: const InputDecoration(
                      labelText: 'Channel',
                      border: OutlineInputBorder(),
                    ),
                    items: const ['Call', 'WhatsApp', 'Service Note']
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setSheetState(() => selectedChannel = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: createdByController,
                    decoration: const InputDecoration(
                      labelText: 'Created By',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: noteController,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Message / Notes',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () async {
                      if (noteController.text.trim().isEmpty) {
                        _showMessage(
                          'Write a note before saving the timeline item.',
                        );
                        return;
                      }
                      await _operationsRepository.addCommunicationLog(
                        CommunicationLog(
                          id: _uuid.v4(),
                          customerId: selectedCustomerId,
                          channel: selectedChannel,
                          note: noteController.text.trim(),
                          createdAt: DateTime.now().toIso8601String(),
                          createdBy: createdByController.text.trim().isEmpty
                              ? 'Operations Desk'
                              : createdByController.text.trim(),
                        ),
                      );
                      if (!mounted) return;
                      Navigator.pop(context);
                      _showMessage('Communication log added.');
                      await _reload();
                    },
                    child: const Text('Save Timeline Entry'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showPurchaseOrderSheet({PurchaseOrder? existing}) async {
    if (_suppliers.isEmpty) {
      _showMessage('Create a supplier first to add a purchase order.');
      return;
    }
    final amountController = TextEditingController(
      text: existing?.totalAmount.toStringAsFixed(0) ?? '',
    );
    final leadController = TextEditingController(
      text: existing?.leadDays.toString() ?? '7',
    );
    final notesController = TextEditingController(text: existing?.notes ?? '');
    String selectedSupplierId = existing?.supplierId ?? _suppliers.first.id;
    DateTime expectedDate =
        DateTime.tryParse(existing?.expectedDate ?? '') ??
        DateTime.now().add(const Duration(days: 7));
    String status = existing?.status ?? 'ordered';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedSupplierId,
                    decoration: const InputDecoration(
                      labelText: 'Supplier',
                      border: OutlineInputBorder(),
                    ),
                    items: _suppliers
                        .map(
                          (supplier) => DropdownMenuItem(
                            value: supplier.id,
                            child: Text(supplier.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setSheetState(() => selectedSupplierId = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: amountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'PO Amount',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: leadController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Lead Days',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: const ['ordered', 'in_transit', 'received']
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(
                              value.replaceAll('_', ' ').toUpperCase(),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setSheetState(() => status = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                        initialDate: expectedDate,
                      );
                      if (picked != null) {
                        setSheetState(() => expectedDate = picked);
                      }
                    },
                    icon: const Icon(Icons.local_shipping_outlined),
                    label: Text('Expected ${_formatDate(expectedDate)}'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notes / Items',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () async {
                      final amount = double.tryParse(
                        amountController.text.trim(),
                      );
                      final lead = int.tryParse(leadController.text.trim());
                      if (amount == null || amount <= 0 || lead == null) {
                        _showMessage('Enter a valid amount and lead time.');
                        return;
                      }
                      await _operationsRepository.upsertPurchaseOrder(
                        PurchaseOrder(
                          id: existing?.id ?? _uuid.v4(),
                          supplierId: selectedSupplierId,
                          poNumber:
                              existing?.poNumber ??
                              'PO-${DateTime.now().millisecondsSinceEpoch}',
                          createdAt:
                              existing?.createdAt ??
                              DateTime.now().toIso8601String(),
                          expectedDate: expectedDate.toIso8601String(),
                          receivedDate: status == 'received'
                              ? DateTime.now().toIso8601String()
                              : null,
                          status: status,
                          totalAmount: amount,
                          leadDays: lead,
                          notes: notesController.text.trim(),
                        ),
                      );
                      if (!mounted) return;
                      Navigator.pop(context);
                      _showMessage(
                        existing == null
                            ? 'Purchase order saved.'
                            : 'Purchase order updated.',
                      );
                      await _reload();
                    },
                    child: Text(
                      existing == null
                          ? 'Save Purchase Order'
                          : 'Update Purchase Order',
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showScheduleSheet({TechnicianSchedule? existing}) async {
    if (_technicians.isEmpty) {
      _showMessage('Create a technician first to add a schedule.');
      return;
    }
    final routeController = TextEditingController(
      text: existing?.routeArea ?? '',
    );
    final stopsController = TextEditingController(
      text: existing?.plannedStops ?? '',
    );
    final checklistController = TextEditingController(
      text: existing?.checklist ?? '',
    );
    String selectedTechnicianId =
        existing?.technicianId ?? _technicians.first.id;
    String leaveStatus = existing?.leaveStatus ?? 'working';
    DateTime scheduleDate =
        DateTime.tryParse(existing?.scheduleDate ?? '') ?? DateTime.now();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedTechnicianId,
                    decoration: const InputDecoration(
                      labelText: 'Technician',
                      border: OutlineInputBorder(),
                    ),
                    items: _technicians
                        .map(
                          (technician) => DropdownMenuItem(
                            value: technician.id,
                            child: Text(technician.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setSheetState(() => selectedTechnicianId = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                        initialDate: scheduleDate,
                      );
                      if (picked != null) {
                        setSheetState(() => scheduleDate = picked);
                      }
                    },
                    icon: const Icon(Icons.event_note_outlined),
                    label: Text('Date ${_formatDate(scheduleDate)}'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: leaveStatus,
                    decoration: const InputDecoration(
                      labelText: 'Leave Status',
                      border: OutlineInputBorder(),
                    ),
                    items: const ['working', 'on_leave', 'half_day']
                        .map(
                          (status) => DropdownMenuItem(
                            value: status,
                            child: Text(
                              status.replaceAll('_', ' ').toUpperCase(),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setSheetState(() => leaveStatus = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: routeController,
                    decoration: const InputDecoration(
                      labelText: 'Route / Area',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: stopsController,
                    decoration: const InputDecoration(
                      labelText: 'Planned Stops',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: checklistController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Daily Checklist',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () async {
                      if (routeController.text.trim().isEmpty ||
                          stopsController.text.trim().isEmpty) {
                        _showMessage(
                          'Add route and planned stops for the schedule.',
                        );
                        return;
                      }
                      await _operationsRepository.upsertTechnicianSchedule(
                        TechnicianSchedule(
                          id: existing?.id ?? _uuid.v4(),
                          technicianId: selectedTechnicianId,
                          scheduleDate: scheduleDate.toIso8601String(),
                          routeArea: routeController.text.trim(),
                          plannedStops: stopsController.text.trim(),
                          checklist: checklistController.text.trim(),
                          leaveStatus: leaveStatus,
                        ),
                      );
                      if (!mounted) return;
                      Navigator.pop(context);
                      _showMessage(
                        existing == null
                            ? 'Schedule saved.'
                            : 'Schedule updated.',
                      );
                      await _reload();
                    },
                    child: Text(
                      existing == null ? 'Save Schedule' : 'Update Schedule',
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showAttachmentSheet() async {
    if (_customers.isEmpty) {
      _showMessage('Create a customer first to add proof.');
      return;
    }
    final titleController = TextEditingController();
    final pathController = TextEditingController();
    String selectedCustomerId = _customers.first.id;
    String type = 'installation_photo';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedCustomerId,
                    decoration: const InputDecoration(
                      labelText: 'Customer',
                      border: OutlineInputBorder(),
                    ),
                    items: _customers
                        .map(
                          (customer) => DropdownMenuItem(
                            value: customer.id,
                            child: Text(customer.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setSheetState(() => selectedCustomerId = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: const InputDecoration(
                      labelText: 'Proof Type',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        const [
                              'installation_photo',
                              'warranty_slip',
                              'signed_completion',
                            ]
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(
                                  value.replaceAll('_', ' ').toUpperCase(),
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setSheetState(() => type = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: pathController,
                    decoration: const InputDecoration(
                      labelText: 'File Path / Reference',
                      hintText: '/path/to/file.jpg or storage reference',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () async {
                      if (titleController.text.trim().isEmpty ||
                          pathController.text.trim().isEmpty) {
                        _showMessage(
                          'Add a title and file reference for the proof.',
                        );
                        return;
                      }
                      await _operationsRepository.upsertAttachment(
                        ServiceAttachment(
                          id: _uuid.v4(),
                          customerId: selectedCustomerId,
                          serviceRequestId: null,
                          type: type,
                          title: titleController.text.trim(),
                          filePath: pathController.text.trim(),
                          createdAt: DateTime.now().toIso8601String(),
                        ),
                      );
                      if (!mounted) return;
                      Navigator.pop(context);
                      _showMessage('Service proof added.');
                      await _reload();
                    },
                    child: const Text('Save Proof'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Operations Center'),
        actions: [
          IconButton(
            tooltip: 'Share Report',
            onPressed: _shareReport,
            icon: const Icon(Icons.file_upload_outlined),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: PopupMenuButton<String>(
        icon: const Icon(Icons.add),
        onSelected: (value) {
          switch (value) {
            case 'invoice':
              _showInvoiceSheet();
              break;
            case 'contract':
              _showContractSheet();
              break;
            case 'communication':
              _showCommunicationSheet();
              break;
            case 'po':
              _showPurchaseOrderSheet();
              break;
            case 'schedule':
              _showScheduleSheet();
              break;
            case 'attachment':
              _showAttachmentSheet();
              break;
          }
        },
        itemBuilder: (context) => const [
          PopupMenuItem(value: 'invoice', child: Text('New Invoice')),
          PopupMenuItem(value: 'contract', child: Text('New AMC Contract')),
          PopupMenuItem(
            value: 'communication',
            child: Text('New Timeline Entry'),
          ),
          PopupMenuItem(value: 'po', child: Text('New Purchase Order')),
          PopupMenuItem(
            value: 'schedule',
            child: Text('New Technician Schedule'),
          ),
          PopupMenuItem(value: 'attachment', child: Text('New Service Proof')),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _reload,
              child: Builder(
                builder: (context) {
                  // Sections are deferred closures so ListView.builder only
                  // builds the cards that are actually on screen.
                  final sections = <Widget Function()>[
                  () => _OverviewGrid(overview: _overview),
                  () => const SizedBox(height: 16),
                  () => _SectionCard(
                    title: 'Invoices & Dues',
                    subtitle: 'Track billing, payments, and overdue balances.',
                    actionLabel: 'Add Invoice',
                    onAction: _showInvoiceSheet,
                    child: _invoices.isEmpty
                        ? const _EmptySection(message: 'No invoices added yet.')
                        : Column(
                            children: _invoices.map((invoice) {
                              final isOverdue = invoice.isOverdue;
                              final isUnpaid = invoice.balanceDue > 0.01;
                              final isDark = Theme.of(context).brightness == Brightness.dark;

                              Color itemBgColor = Colors.transparent;
                              Color borderColor = Colors.transparent;
                              Color accentColor = Colors.transparent;

                              if (isOverdue) {
                                itemBgColor = isDark
                                    ? const Color(0xFF7F1D1D).withValues(alpha: 0.15)
                                    : const Color(0xFFFEF2F2);
                                borderColor = isDark
                                    ? const Color(0xFFEF4444).withValues(alpha: 0.3)
                                    : const Color(0xFFFCA5A5);
                                accentColor = const Color(0xFFEF4444);
                              } else if (isUnpaid) {
                                itemBgColor = isDark
                                    ? const Color(0xFF78350F).withValues(alpha: 0.15)
                                    : const Color(0xFFFFFBEB);
                                borderColor = isDark
                                    ? const Color(0xFFF59E0B).withValues(alpha: 0.3)
                                    : const Color(0xFFFDE68A);
                                accentColor = const Color(0xFFF59E0B);
                              }

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: itemBgColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: borderColor != Colors.transparent
                                      ? Border.all(color: borderColor)
                                      : Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      if (accentColor != Colors.transparent)
                                        Container(
                                          width: 4,
                                          decoration: BoxDecoration(
                                            color: accentColor,
                                            borderRadius: const BorderRadius.only(
                                              topLeft: Radius.circular(12),
                                              bottomLeft: Radius.circular(12),
                                            ),
                                          ),
                                        ),
                                      Expanded(
                                        child: ListTile(
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                          title: Text(
                                            '${invoice.invoiceNumber} • ${_customerName(invoice.customerId)}',
                                            style: TextStyle(
                                              fontWeight: isOverdue || isUnpaid
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                          subtitle: Text(
                                            'Due ${_formatDate(DateTime.tryParse(invoice.dueDate) ?? DateTime.now())} • Balance ${formatRupee(invoice.balanceDue)}',
                                            style: TextStyle(
                                              color: isOverdue
                                                  ? (isDark
                                                      ? const Color(0xFFFCA5A5)
                                                      : const Color(0xFF991B1B))
                                                  : (isUnpaid
                                                      ? (isDark
                                                          ? const Color(0xFFFDE68A)
                                                          : const Color(0xFF92400E))
                                                      : null),
                                              fontWeight: isOverdue || isUnpaid
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                          trailing: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isOverdue
                                                  ? (isDark
                                                      ? const Color(0xFFEF4444)
                                                          .withValues(alpha: 0.2)
                                                      : const Color(0xFFFEE2E2))
                                                  : (isUnpaid
                                                      ? (isDark
                                                          ? const Color(0xFFF59E0B)
                                                              .withValues(alpha: 0.2)
                                                          : const Color(0xFFFEF3C7))
                                                      : (isDark
                                                          ? const Color(0xFF10B981)
                                                              .withValues(alpha: 0.2)
                                                          : const Color(0xFFD1FAE5))),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              invoice.status.toUpperCase(),
                                              style: TextStyle(
                                                color: isOverdue
                                                    ? (isDark
                                                        ? const Color(0xFFFCA5A5)
                                                        : const Color(0xFFDC2626))
                                                    : (isUnpaid
                                                        ? (isDark
                                                            ? const Color(0xFFFDE68A)
                                                            : const Color(0xFFD97706))
                                                        : (isDark
                                                            ? const Color(0xFF34D399)
                                                            : const Color(0xFF059669))),
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                          onTap: () =>
                                              _showInvoiceSheet(existing: invoice),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                  () => const SizedBox(height: 12),
                  () => _SectionCard(
                    title: 'AMC Contracts',
                    subtitle: 'Renewals, visit quotas, and plan value.',
                    actionLabel: 'Add Contract',
                    onAction: _showContractSheet,
                    child: _contracts.isEmpty
                        ? const _EmptySection(
                            message: 'No AMC contracts available.',
                          )
                        : Column(
                            children: _contracts
                                .map(
                                  (contract) => ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                      '${contract.contractName} • ${_customerName(contract.customerId)}',
                                    ),
                                    subtitle: Text(
                                      '${contract.visitsRemaining} visits left • Renewal ${_formatDate(DateTime.tryParse(contract.renewalReminderDate) ?? DateTime.now())}',
                                    ),
                                    trailing: Text(
                                      contract.status.toUpperCase(),
                                    ),
                                    onTap: () =>
                                        _showContractSheet(existing: contract),
                                  ),
                                )
                                .toList(),
                          ),
                  ),
                  () => const SizedBox(height: 12),
                  () => _SectionCard(
                    title: 'Customer Timeline',
                    subtitle: 'Calls, WhatsApp follow-ups, and service notes.',
                    actionLabel: 'Add Entry',
                    onAction: _showCommunicationSheet,
                    child: _logs.isEmpty
                        ? const _EmptySection(
                            message: 'No communication timeline yet.',
                          )
                        : Column(
                            children: _logs
                                .take(8)
                                .map(
                                  (log) => ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                      child: Text(
                                        log.channel.isEmpty
                                            ? '?'
                                            : log.channel.substring(0, 1),
                                      ),
                                    ),
                                    title: Text(
                                      '${_customerName(log.customerId)} • ${log.channel}',
                                    ),
                                    subtitle: Text(log.note),
                                    trailing: Text(
                                      _formatDateTime(
                                        DateTime.tryParse(log.createdAt),
                                      ),
                                      textAlign: TextAlign.end,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                  ),
                  () => const SizedBox(height: 12),
                  () => _SectionCard(
                    title: 'Procurement',
                    subtitle:
                        'Supplier lead times, open purchase orders, and receiving status.',
                    actionLabel: 'Add PO',
                    onAction: _showPurchaseOrderSheet,
                    child: _purchaseOrders.isEmpty
                        ? const _EmptySection(
                            message: 'No purchase orders created yet.',
                          )
                        : Column(
                            children: _purchaseOrders
                                .map(
                                  (order) => ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                      '${order.poNumber} • ${_supplierName(order.supplierId)}',
                                    ),
                                    subtitle: Text(
                                      'Expected ${_formatDate(DateTime.tryParse(order.expectedDate) ?? DateTime.now())} • Lead ${order.leadDays} days',
                                    ),
                                    trailing: Text(order.status.toUpperCase()),
                                    onTap: () => _showPurchaseOrderSheet(
                                      existing: order,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                  ),
                  () => const SizedBox(height: 12),
                  () => _SectionCard(
                    title: 'Technician Schedules',
                    subtitle:
                        'Routes, leave status, planned stops, and daily checklist.',
                    actionLabel: 'Add Schedule',
                    onAction: _showScheduleSheet,
                    child: _schedules.isEmpty
                        ? const _EmptySection(
                            message: 'No technician schedules planned yet.',
                          )
                        : Column(
                            children: _schedules
                                .map(
                                  (schedule) => ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                      '${_technicianName(schedule.technicianId)} • ${schedule.routeArea}',
                                    ),
                                    subtitle: Text(
                                      '${_formatDate(DateTime.tryParse(schedule.scheduleDate) ?? DateTime.now())} • ${schedule.plannedStops}',
                                    ),
                                    trailing: Text(
                                      schedule.leaveStatus
                                          .replaceAll('_', ' ')
                                          .toUpperCase(),
                                    ),
                                    onTap: () =>
                                        _showScheduleSheet(existing: schedule),
                                  ),
                                )
                                .toList(),
                          ),
                  ),
                  () => const SizedBox(height: 12),
                  () => _SectionCard(
                    title: 'Service Proof',
                    subtitle:
                        'Installation photos, warranty slips, and signed completion evidence.',
                    actionLabel: 'Add Proof',
                    onAction: _showAttachmentSheet,
                    child: _attachments.isEmpty
                        ? const _EmptySection(
                            message: 'No service proof attached yet.',
                          )
                        : Column(
                            children: _attachments
                                .map(
                                  (attachment) => ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                      '${attachment.title} • ${_customerName(attachment.customerId)}',
                                    ),
                                    subtitle: Text(attachment.filePath),
                                    trailing: Text(
                                      attachment.type
                                          .replaceAll('_', ' ')
                                          .toUpperCase(),
                                      textAlign: TextAlign.end,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                  ),
                  () => const SizedBox(height: 88),
                  ];
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: sections.length,
                    itemBuilder: (context, index) => sections[index](),
                  );
                },
              ),
            ),
    );
  }

  String _formatDate(DateTime value) {
    final month = _monthLabel(value.month);
    return '${value.day} $month ${value.year}';
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) return '';
    final hour = value.hour > 12
        ? value.hour - 12
        : (value.hour == 0 ? 12 : value.hour);
    final minute = value.minute.toString().padLeft(2, '0');
    final suffix = value.hour >= 12 ? 'PM' : 'AM';
    return '${_formatDate(value)}\n$hour:$minute $suffix';
  }

  String _monthLabel(int month) {
    const labels = [
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
    return labels[month - 1];
  }
}

class _OverviewGrid extends StatelessWidget {
  final Map<String, dynamic> overview;

  const _OverviewGrid({required this.overview});

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        'Outstanding',
        formatRupee((overview['outstandingBalance'] ?? 0) as num),
      ),
      ('Overdue', '${overview['overdueInvoices'] ?? 0}'),
      ('Renewals', '${overview['expiringContracts'] ?? 0}'),
      ('Open POs', '${overview['openPurchaseOrders'] ?? 0}'),
      ('Today', '${overview['plannedToday'] ?? 0}'),
      ('Proofs', '${overview['attachments'] ?? 0}'),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.9,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: items
          .map(
            (item) => Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.$1.toUpperCase(),
                    style: Theme.of(
                      context,
                    ).textTheme.labelMedium?.copyWith(letterSpacing: 1.1),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.$2,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              TextButton(onPressed: onAction, child: Text(actionLabel)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  final String message;

  const _EmptySection({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(child: Text(message)),
    );
  }
}
