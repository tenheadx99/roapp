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
import '../../inventory/repositories/inventory_repository.dart';

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

  final TextEditingController _invoiceSearchController =
      TextEditingController();
  final TextEditingController _amcSearchController = TextEditingController();
  String _invoiceQuery = '';
  String _amcQuery = '';
  String _invoiceFilter = 'All';
  String _amcFilter = 'All';
  String _poFilter = 'All';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _invoiceSearchController.dispose();
    _amcSearchController.dispose();
    super.dispose();
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
                            final placeholders = List.filled(
                              itemIds.length,
                              '?',
                            ).join(', ');
                            final results = await db.rawQuery(
                              'SELECT id, supplierPrice FROM inventory WHERE id IN ($placeholders)',
                              itemIds,
                            );
                            final priceMap = {
                              for (final row in results)
                                row['id'] as String:
                                    (row['supplierPrice'] as num?)
                                        ?.toDouble() ??
                                    0.0,
                            };
                            for (final item in req.inventoryItems) {
                              final pCost =
                                  priceMap[item.inventoryItemId] ?? 0.0;
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
                          supplierPriceController.text = computedSupplierPrice
                              .toStringAsFixed(0);
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
                      final supplierPrice =
                          double.tryParse(
                            supplierPriceController.text.trim(),
                          ) ??
                          0.0;
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
    final inventory = await InventoryRepository().getInventory();
    if (!mounted) return;

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

    final items = List<PurchaseOrderItem>.from(
      existing?.items ?? const <PurchaseOrderItem>[],
    );
    final quantityControllers = items
        .map((item) => TextEditingController(text: item.quantity.toString()))
        .toList();
    final costControllers = items
        .map((item) => TextEditingController(text: _amountText(item.unitCost)))
        .toList();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void syncAmountFromItems() {
              if (items.isEmpty) return;
              final total = items.fold<double>(
                0,
                (sum, item) => sum + item.lineTotal,
              );
              amountController.text = _amountText(total);
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
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
                            readOnly: items.isNotEmpty,
                            decoration: InputDecoration(
                              labelText: 'PO Amount',
                              helperText: items.isNotEmpty
                                  ? 'Auto-calculated from line items'
                                  : null,
                              border: const OutlineInputBorder(),
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Line Items',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: inventory.isEmpty
                              ? null
                              : () {
                                  final first = inventory.first;
                                  setSheetState(() {
                                    items.add(
                                      PurchaseOrderItem(
                                        inventoryItemId: first.id,
                                        name: first.name,
                                        quantity: 1,
                                        unitCost: first.supplierPrice,
                                      ),
                                    );
                                    quantityControllers.add(
                                      TextEditingController(text: '1'),
                                    );
                                    costControllers.add(
                                      TextEditingController(
                                        text: _amountText(first.supplierPrice),
                                      ),
                                    );
                                    syncAmountFromItems();
                                  });
                                },
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add Item'),
                        ),
                      ],
                    ),
                    if (inventory.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Add inventory items first to build a line-item PO.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    for (var i = 0; i < items.length; i++) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: DropdownButtonFormField<String>(
                              value:
                                  inventory.any(
                                    (inv) => inv.id == items[i].inventoryItemId,
                                  )
                                  ? items[i].inventoryItemId
                                  : null,
                              isExpanded: true,
                              hint: Text(
                                items[i].name.isEmpty ? 'Item' : items[i].name,
                                overflow: TextOverflow.ellipsis,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Item',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                              items: inventory
                                  .map(
                                    (inv) => DropdownMenuItem(
                                      value: inv.id,
                                      child: Text(
                                        inv.name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value == null) return;
                                final picked = inventory.firstWhere(
                                  (inv) => inv.id == value,
                                );
                                setSheetState(() {
                                  items[i] = items[i].copyWith(
                                    inventoryItemId: picked.id,
                                    name: picked.name,
                                    unitCost: picked.supplierPrice,
                                  );
                                  costControllers[i].text = _amountText(
                                    picked.supplierPrice,
                                  );
                                  syncAmountFromItems();
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: quantityControllers[i],
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Qty',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) {
                                final quantity = int.tryParse(value.trim());
                                setSheetState(() {
                                  items[i] = items[i].copyWith(
                                    quantity: quantity ?? 0,
                                  );
                                  syncAmountFromItems();
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: costControllers[i],
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Unit Cost',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) {
                                final cost = double.tryParse(value.trim());
                                setSheetState(() {
                                  items[i] = items[i].copyWith(
                                    unitCost: cost ?? 0,
                                  );
                                  syncAmountFromItems();
                                });
                              },
                            ),
                          ),
                          IconButton(
                            tooltip: 'Remove item',
                            onPressed: () {
                              setSheetState(() {
                                items.removeAt(i);
                                quantityControllers.removeAt(i);
                                costControllers.removeAt(i);
                                syncAmountFromItems();
                              });
                            },
                            icon: const Icon(Icons.close, size: 20),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
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
                        if (items.any((item) => item.quantity <= 0)) {
                          _showMessage(
                            'Enter a valid quantity for every line item.',
                          );
                          return;
                        }
                        final total = items.isEmpty
                            ? amount
                            : items.fold<double>(
                                0,
                                (sum, item) => sum + item.lineTotal,
                              );
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
                            totalAmount: total,
                            leadDays: lead,
                            notes: notesController.text.trim(),
                            items: List<PurchaseOrderItem>.from(items),
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

  String _amountText(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);

  List<Invoice> get _filteredInvoices {
    final query = _invoiceQuery.trim().toLowerCase();
    return _invoices.where((invoice) {
      final matchesFilter = switch (_invoiceFilter) {
        'Due' => !invoice.isOverdue && invoice.balanceDue > 0.01,
        'Overdue' => invoice.isOverdue,
        'Paid' => invoice.balanceDue <= 0.01,
        _ => true,
      };
      if (!matchesFilter) return false;
      if (query.isEmpty) return true;
      return invoice.invoiceNumber.toLowerCase().contains(query) ||
          _customerName(invoice.customerId).toLowerCase().contains(query);
    }).toList();
  }

  List<AmcContract> get _filteredContracts {
    final query = _amcQuery.trim().toLowerCase();
    return _contracts.where((contract) {
      final matchesFilter = switch (_amcFilter) {
        'Active' => contract.status.toLowerCase() == 'active',
        'Renewal Due' => contract.isRenewalDue,
        'Expired' => contract.status.toLowerCase() == 'expired',
        _ => true,
      };
      if (!matchesFilter) return false;
      if (query.isEmpty) return true;
      return contract.contractName.toLowerCase().contains(query) ||
          _customerName(contract.customerId).toLowerCase().contains(query);
    }).toList();
  }

  List<PurchaseOrder> get _filteredPurchaseOrders {
    final status = switch (_poFilter) {
      'Ordered' => 'ordered',
      'In Transit' => 'in_transit',
      'Received' => 'received',
      _ => null,
    };
    if (status == null) return _purchaseOrders;
    return _purchaseOrders.where((order) => order.status == status).toList();
  }

  Future<void> _showRecordPaymentDialog(Invoice invoice) async {
    final amountController = TextEditingController(
      text: _amountText(invoice.balanceDue),
    );
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Record Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${invoice.invoiceNumber} • Balance ${formatRupee(invoice.balanceDue)}',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text.trim());
                if (amount == null || amount <= 0) {
                  _showMessage('Enter a valid payment amount.');
                  return;
                }
                Navigator.pop(dialogContext);
                final updated = await _operationsRepository
                    .recordInvoicePayment(invoice.id, amount);
                if (!mounted) return;
                _showMessage(
                  updated == null
                      ? 'Could not record the payment.'
                      : 'Payment recorded — invoice is now ${updated.status.toUpperCase()}.',
                );
                await _reload();
              },
              child: const Text('Record'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _renewContract(AmcContract contract) async {
    final renewed = await _operationsRepository.renewContract(contract);
    if (!mounted) return;
    final newEnd = DateTime.tryParse(renewed.endDate);
    _showMessage(
      'Renewed — new contract runs to '
      '${newEnd != null ? _formatDate(newEnd) : renewed.endDate}.',
    );
    await _reload();
  }

  Future<void> _markPurchaseOrderReceived(PurchaseOrder order) async {
    final transitioned = await _operationsRepository.markPurchaseOrderReceived(
      order.id,
    );
    if (!mounted) return;
    if (!transitioned) {
      _showMessage('Purchase order is already received.');
      await _reload();
      return;
    }
    final linkedItems = order.items
        .where(
          (item) =>
              item.inventoryItemId != null && item.inventoryItemId!.isNotEmpty,
        )
        .length;
    _showMessage(
      linkedItems > 0
          ? 'Stock updated for $linkedItems item(s).'
          : 'Marked received.',
    );
    await _reload();
  }

  void _handleStatTap(BuildContext context, String key) {
    final tabController = DefaultTabController.of(context);
    switch (key) {
      case 'outstanding':
        setState(() {
          _invoiceFilter = 'Due';
          _invoiceQuery = '';
          _invoiceSearchController.clear();
        });
        tabController.animateTo(1);
      case 'overdue':
        setState(() {
          _invoiceFilter = 'Overdue';
          _invoiceQuery = '';
          _invoiceSearchController.clear();
        });
        tabController.animateTo(1);
      case 'renewals':
        setState(() {
          _amcFilter = 'Renewal Due';
          _amcQuery = '';
          _amcSearchController.clear();
        });
        tabController.animateTo(2);
      case 'openPos':
        setState(() => _poFilter = 'Ordered');
        tabController.animateTo(3);
      case 'today':
        tabController.animateTo(4);
      case 'proofs':
        tabController.animateTo(5);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DefaultTabController(
      length: 6,
      child: Scaffold(
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
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Invoices'),
              Tab(text: 'AMC'),
              Tab(text: 'Purchase Orders'),
              Tab(text: 'Schedules'),
              Tab(text: 'Logs & Proof'),
            ],
          ),
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
            PopupMenuItem(
              value: 'attachment',
              child: Text('New Service Proof'),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildOverviewTab(),
                  _buildInvoicesTab(),
                  _buildAmcTab(),
                  _buildPurchaseOrdersTab(),
                  _buildSchedulesTab(),
                  _buildLogsAndProofTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Builder(
      builder: (tabContext) {
        return RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            children: [
              _OverviewGrid(
                overview: _overview,
                onStatTap: (key) => _handleStatTap(tabContext, key),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInvoicesTab() {
    final filtered = _filteredInvoices;
    return _buildListTab(
      header: _buildTabHeader(
        searchController: _invoiceSearchController,
        searchHint: 'Search invoice # or customer',
        onSearchChanged: (value) => setState(() => _invoiceQuery = value),
        filters: const ['All', 'Due', 'Overdue', 'Paid'],
        selectedFilter: _invoiceFilter,
        onFilterSelected: (filter) => setState(() => _invoiceFilter = filter),
        actionLabel: 'Add Invoice',
        onAction: _showInvoiceSheet,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) =>
          _buildInvoiceRow(context, filtered[index]),
      emptyState: _EmptySection(
        message: _invoices.isEmpty ? 'No invoices added yet.' : 'No matches.',
      ),
    );
  }

  Widget _buildAmcTab() {
    final filtered = _filteredContracts;
    return _buildListTab(
      header: _buildTabHeader(
        searchController: _amcSearchController,
        searchHint: 'Search contract or customer',
        onSearchChanged: (value) => setState(() => _amcQuery = value),
        filters: const ['All', 'Active', 'Renewal Due', 'Expired'],
        selectedFilter: _amcFilter,
        onFilterSelected: (filter) => setState(() => _amcFilter = filter),
        actionLabel: 'Add Contract',
        onAction: _showContractSheet,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) => _buildContractRow(filtered[index]),
      emptyState: _EmptySection(
        message: _contracts.isEmpty
            ? 'No AMC contracts available.'
            : 'No matches.',
      ),
    );
  }

  Widget _buildPurchaseOrdersTab() {
    final filtered = _filteredPurchaseOrders;
    return _buildListTab(
      header: _buildTabHeader(
        filters: const ['All', 'Ordered', 'In Transit', 'Received'],
        selectedFilter: _poFilter,
        onFilterSelected: (filter) => setState(() => _poFilter = filter),
        actionLabel: 'Add PO',
        onAction: _showPurchaseOrderSheet,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) => _buildPurchaseOrderRow(filtered[index]),
      emptyState: _EmptySection(
        message: _purchaseOrders.isEmpty
            ? 'No purchase orders created yet.'
            : 'No matches.',
      ),
    );
  }

  Widget _buildSchedulesTab() {
    return _buildListTab(
      header: _buildTabHeader(
        actionLabel: 'Add Schedule',
        onAction: _showScheduleSheet,
      ),
      itemCount: _schedules.length,
      itemBuilder: (context, index) => _buildScheduleRow(_schedules[index]),
      emptyState: const _EmptySection(
        message: 'No technician schedules planned yet.',
      ),
    );
  }

  Widget _buildLogsAndProofTab() {
    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
        children: [
          _SectionCard(
            title: 'Customer Timeline',
            subtitle: 'Calls, WhatsApp follow-ups, and service notes.',
            actionLabel: 'Add Entry',
            onAction: _showCommunicationSheet,
            child: _logs.isEmpty
                ? const _EmptySection(message: 'No communication timeline yet.')
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
                              _formatDateTime(DateTime.tryParse(log.createdAt)),
                              textAlign: TextAlign.end,
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Service Proof',
            subtitle:
                'Installation photos, warranty slips, and signed completion evidence.',
            actionLabel: 'Add Proof',
            onAction: _showAttachmentSheet,
            child: _attachments.isEmpty
                ? const _EmptySection(message: 'No service proof attached yet.')
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
        ],
      ),
    );
  }

  Widget _buildListTab({
    required Widget header,
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
    required Widget emptyState,
  }) {
    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
        itemCount: itemCount == 0 ? 2 : itemCount + 1,
        itemBuilder: (context, index) {
          if (index == 0) return header;
          if (itemCount == 0) return emptyState;
          return itemBuilder(context, index - 1);
        },
      ),
    );
  }

  Widget _buildTabHeader({
    TextEditingController? searchController,
    String? searchHint,
    ValueChanged<String>? onSearchChanged,
    List<String>? filters,
    String? selectedFilter,
    ValueChanged<String>? onFilterSelected,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: searchController == null
                  ? const SizedBox.shrink()
                  : TextField(
                      controller: searchController,
                      onChanged: onSearchChanged,
                      decoration: InputDecoration(
                        hintText: searchHint,
                        prefixIcon: const Icon(Icons.search, size: 20),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add, size: 18),
              label: Text(actionLabel),
            ),
          ],
        ),
        if (filters != null) ...[
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: filters
                  .map(
                    (filter) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(filter),
                        selected: selectedFilter == filter,
                        onSelected: (_) => onFilterSelected?.call(filter),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildInvoiceRow(BuildContext context, Invoice invoice) {
    final theme = Theme.of(context);
    final isOverdue = invoice.isOverdue;
    final isUnpaid = invoice.balanceDue > 0.01;
    final isDark = theme.brightness == Brightness.dark;

    Color itemBgColor = theme.cardColor;
    Color borderColor = theme.dividerColor;
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

    final statusBadge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOverdue
            ? (isDark
                  ? const Color(0xFFEF4444).withValues(alpha: 0.2)
                  : const Color(0xFFFEE2E2))
            : (isUnpaid
                  ? (isDark
                        ? const Color(0xFFF59E0B).withValues(alpha: 0.2)
                        : const Color(0xFFFEF3C7))
                  : (isDark
                        ? const Color(0xFF10B981).withValues(alpha: 0.2)
                        : const Color(0xFFD1FAE5))),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        invoice.status.toUpperCase(),
        style: TextStyle(
          color: isOverdue
              ? (isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626))
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
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: itemBgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
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
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    statusBadge,
                    if (isUnpaid)
                      PopupMenuButton<String>(
                        tooltip: 'Invoice actions',
                        padding: EdgeInsets.zero,
                        onSelected: (value) {
                          if (value == 'payment') {
                            _showRecordPaymentDialog(invoice);
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'payment',
                            child: Text('Record Payment'),
                          ),
                        ],
                      ),
                  ],
                ),
                onTap: () => _showInvoiceSheet(existing: invoice),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContractRow(AmcContract contract) {
    final canRenew =
        contract.isRenewalDue || contract.status.toLowerCase() == 'expired';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              '${contract.contractName} • ${_customerName(contract.customerId)}',
            ),
            subtitle: Text(
              '${contract.visitsRemaining} visits left • Renewal ${_formatDate(DateTime.tryParse(contract.renewalReminderDate) ?? DateTime.now())}',
            ),
            trailing: Text(contract.status.toUpperCase()),
            onTap: () => _showContractSheet(existing: contract),
          ),
          if (canRenew)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _renewContract(contract),
                icon: const Icon(Icons.autorenew, size: 18),
                label: const Text('Renew'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPurchaseOrderRow(PurchaseOrder order) {
    final isReceived = order.status == 'received';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              '${order.poNumber} • ${_supplierName(order.supplierId)}',
            ),
            subtitle: Text(
              'Expected ${_formatDate(DateTime.tryParse(order.expectedDate) ?? DateTime.now())} • Lead ${order.leadDays} days',
            ),
            trailing: Text(order.status.toUpperCase()),
            onTap: () => _showPurchaseOrderSheet(existing: order),
          ),
          if (!isReceived)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _markPurchaseOrderReceived(order),
                icon: const Icon(Icons.inventory_2_outlined, size: 18),
                label: const Text('Mark Received'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScheduleRow(TechnicianSchedule schedule) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          '${_technicianName(schedule.technicianId)} • ${schedule.routeArea}',
        ),
        subtitle: Text(
          '${_formatDate(DateTime.tryParse(schedule.scheduleDate) ?? DateTime.now())} • ${schedule.plannedStops}',
        ),
        trailing: Text(schedule.leaveStatus.replaceAll('_', ' ').toUpperCase()),
        onTap: () => _showScheduleSheet(existing: schedule),
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
  final void Function(String key)? onStatTap;

  const _OverviewGrid({required this.overview, this.onStatTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        'outstanding',
        'Outstanding',
        formatRupee((overview['outstandingBalance'] ?? 0) as num),
      ),
      ('overdue', 'Overdue', '${overview['overdueInvoices'] ?? 0}'),
      ('renewals', 'Renewals', '${overview['expiringContracts'] ?? 0}'),
      ('openPos', 'Open POs', '${overview['openPurchaseOrders'] ?? 0}'),
      ('today', 'Today', '${overview['plannedToday'] ?? 0}'),
      ('proofs', 'Proofs', '${overview['attachments'] ?? 0}'),
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
            (item) => Material(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: onStatTap == null ? null : () => onStatTap!(item.$1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.$2.toUpperCase(),
                        style: Theme.of(
                          context,
                        ).textTheme.labelMedium?.copyWith(letterSpacing: 1.1),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.$3,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
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
