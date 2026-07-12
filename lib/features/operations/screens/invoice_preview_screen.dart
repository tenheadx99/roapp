import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:roapp/core/utils/currency_formatter.dart';
import 'package:roapp/core/database/database_helper.dart';
import 'package:roapp/core/services/invoice_pdf_service.dart';
import 'package:roapp/features/customer/models/customer.dart';
import 'package:roapp/features/customer/repositories/customer_repository.dart';
import 'package:roapp/features/dispatch/models/service_request.dart';
import 'package:roapp/features/settings/repositories/settings_repository.dart';
import 'package:roapp/features/settings/models/app_settings.dart';
import 'package:roapp/features/operations/repositories/operations_repository.dart';
import 'package:share_plus/share_plus.dart';

class InvoicePreviewScreen extends StatefulWidget {
  final ServiceRequest request;

  const InvoicePreviewScreen({super.key, required this.request});

  @override
  State<InvoicePreviewScreen> createState() => _InvoicePreviewScreenState();
}

class _InvoicePreviewScreenState extends State<InvoicePreviewScreen> {
  final CustomerRepository _customerRepository = CustomerRepository();
  final SettingsRepository _settingsRepository = SettingsRepository();
  final OperationsRepository _operationsRepository = OperationsRepository();
  final InvoicePdfService _invoicePdfService = InvoicePdfService();

  late Future<Map<String, dynamic>> _invoiceDataFuture;

  @override
  void initState() {
    super.initState();
    _invoiceDataFuture = _loadInvoiceData();
  }

  Future<Map<String, dynamic>> _loadInvoiceData() async {
    // 1. Resolve Customer
    Customer? customer;
    final customerId = (widget.request.customerId ?? '').trim();
    if (customerId.isNotEmpty) {
      customer = await _customerRepository.getCustomerById(customerId);
    }
    if (customer == null) {
      final customers = await _customerRepository.getCustomers();
      for (final c in customers) {
        if (c.name == widget.request.customerName) {
          customer = c;
          break;
        }
      }
    }

    // 2. Load App Settings
    final settings = await _settingsRepository.loadSettings();

    // 3. Query MRPs
    final db = await DatabaseHelper.instance.database;
    final itemIds = widget.request.inventoryItems
        .map((e) => e.inventoryItemId)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toList();

    final mrpMap = <String, double>{};
    if (itemIds.isNotEmpty) {
      final placeholders = List.filled(itemIds.length, '?').join(', ');
      final results = await db.rawQuery(
        'SELECT id, mrp FROM inventory WHERE id IN ($placeholders)',
        itemIds,
      );
      for (final row in results) {
        final id = row['id'] as String;
        mrpMap[id] = (row['mrp'] as num).toDouble();
      }
    }

    // Generate Invoice Number
    final completedAt = DateTime.tryParse(widget.request.completedAt ?? '') ??
        DateTime.tryParse(widget.request.scheduledFor ?? '') ??
        DateTime.now();
    final datePart = '${completedAt.year}${completedAt.month.toString().padLeft(2, '0')}${completedAt.day.toString().padLeft(2, '0')}';
    final suffix = widget.request.id.length >= 6
        ? widget.request.id.substring(widget.request.id.length - 6).toUpperCase()
        : widget.request.id.toUpperCase();
    final invoiceNumber = 'SVC-$datePart-$suffix';

    return {
      'customer': customer,
      'settings': settings,
      'mrpMap': mrpMap,
      'invoiceNumber': invoiceNumber,
      'completedAt': completedAt,
    };
  }

  Future<void> _shareInvoice() async {
    try {
      final path = await _operationsRepository.exportServiceInvoice(widget.request);
      await Share.shareXFiles(
        [XFile(path, mimeType: 'application/pdf')],
        subject: 'Service Invoice - ${widget.request.customerName}',
        text: 'Service invoice for ${widget.request.customerName}',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not share invoice: $e')),
      );
    }
  }

  Future<void> _printInvoice() async {
    try {
      final data = await _invoiceDataFuture;
      final Customer? customer = data['customer'];
      final AppSettings settings = data['settings'];
      final Map<String, double> mrpMap = data['mrpMap'];
      final String invoiceNumber = data['invoiceNumber'];
      final DateTime completedAt = data['completedAt'];

      final pdfBytes = await _invoicePdfService.buildServiceInvoicePdf(
        request: widget.request,
        customer: customer,
        invoiceNumber: invoiceNumber,
        completedAt: completedAt,
        businessName: settings.businessName,
        businessPhone: settings.businessPhone,
        businessAddress: settings.businessAddress,
        mrpMap: mrpMap,
      );

      await Printing.layoutPdf(
        name: '$invoiceNumber.pdf',
        onLayout: (format) async => pdfBytes,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not print invoice: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Invoice Preview',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Print / PDF Preview',
            onPressed: _printInvoice,
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Invoice',
            onPressed: _shareInvoice,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _invoiceDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error loading preview: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
            );
          }

          final data = snapshot.data!;
          final Customer? customer = data['customer'];
          final AppSettings settings = data['settings'];
          final Map<String, double> mrpMap = data['mrpMap'];
          final String invoiceNumber = data['invoiceNumber'];
          final DateTime completedAt = data['completedAt'];

          final customerName = customer?.name ?? widget.request.customerName;
          final customerPhone = customer?.phone ?? 'N/A';
          final customerAddress = customer?.area ?? widget.request.address;
          final model = customer?.model ?? widget.request.model;
          final technician = (widget.request.technicianName ?? '').trim().isEmpty
              ? 'Unassigned'
              : widget.request.technicianName!.trim();

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Premium Styled Card Container
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Service Invoice',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF007FFF),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  invoiceNumber,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: const Text(
                                    'PAID',
                                    style: TextStyle(
                                      color: Color(0xFF15803D),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 10,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  settings.businessName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                  textAlign: TextAlign.end,
                                ),
                                if (settings.businessPhone.trim().isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    '📞 ${settings.businessPhone}',
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                                    textAlign: TextAlign.end,
                                  ),
                                ],
                                if (settings.businessAddress.trim().isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    '📍 ${settings.businessAddress}',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                                    textAlign: TextAlign.end,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                const SizedBox(height: 6),
                                Text(
                                  'Date: ${completedAt.day.toString().padLeft(2, '0')}/${completedAt.month.toString().padLeft(2, '0')}/${completedAt.year}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF94A3B8),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Divider(color: Color(0xFFF1F5F9), height: 1),
                      const SizedBox(height: 20),

                      // Billed To & Service Details Grid
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'BILLED TO',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF64748B),
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  customerName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Phone: $customerPhone',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Address: $customerAddress',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'SERVICE DETAILS',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF64748B),
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  widget.request.type,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Model: $model',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Staff: $technician',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Items Table Label
                      const Text(
                        'SPARE PARTS & LABOUR',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Spare Parts Items Cards/List (Optimized for Mobile)
                      if (widget.request.inventoryItems.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Center(
                            child: Text(
                              'No spare parts or items added to this service.',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontStyle: FontStyle.italic,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        )
                      else
                        ...widget.request.inventoryItems.map((item) {
                          final mrp = mrpMap[item.inventoryItemId] ?? item.unitPrice;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF131D31) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  item.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildMetaColumn('QTY', '${item.quantity}'),
                                    _buildMetaColumn('MRP', formatRupee(mrp, decimalDigits: 2)),
                                    _buildMetaColumn('PRICE', formatRupee(item.unitPrice, decimalDigits: 2)),
                                    _buildMetaColumn('TOTAL', formatRupee(item.lineTotal, decimalDigits: 2), alignEnd: true, bold: true),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      const SizedBox(height: 20),

                      // Notes & Summary Grid
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Notes Card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF131D31) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'SERVICE NOTES',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF64748B),
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  (widget.request.notes ?? '').trim().isEmpty
                                      ? 'Service completed successfully.'
                                      : widget.request.notes!.trim(),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF475569),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Summary Card
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                _buildSummaryRow('Subtotal', formatRupee(widget.request.totalAmount, decimalDigits: 2)),
                                const SizedBox(height: 8),
                                _buildSummaryRow('Tax (GST 0%)', formatRupee(0, decimalDigits: 2)),
                                const SizedBox(height: 12),
                                const Divider(color: Colors.white24, height: 1),
                                const SizedBox(height: 12),
                                _buildSummaryRow('Total', formatRupee(widget.request.totalAmount, decimalDigits: 2), isTotal: true),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Thank you message
                      Center(
                        child: Text(
                          'Thank you for choosing ${settings.businessName}!',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF94A3B8),
                          ),
                          textAlign: CenterTextAlignment,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetaColumn(String label, String value, {bool alignEnd = false, bool bold = false}) {
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: Color(0xFF64748B),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            color: bold ? const Color(0xFF007FFF) : const Color(0xFF334155),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 13,
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
            color: isTotal ? Colors.white : const Color(0xFF94A3B8),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 13,
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  // Support for text alignment constant mapping across environments
  static const TextAlign CenterTextAlignment = TextAlign.center;
}
