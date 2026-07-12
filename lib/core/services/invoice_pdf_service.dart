import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:roapp/core/utils/currency_formatter.dart';
import 'package:roapp/features/customer/models/customer.dart';
import 'package:roapp/features/dispatch/models/service_request.dart';

/// Builds professional A4 service invoice PDFs using the `pdf` package.
///
/// Note: the built-in Helvetica font does not support the rupee symbol (₹),
/// so amounts are rendered with a `Rs.` prefix instead.
class InvoicePdfService {
  static const PdfColor _accent = PdfColor.fromInt(0xFF007FFF);
  static const PdfColor _ink = PdfColor.fromInt(0xFF0F172A);
  static const PdfColor _slate = PdfColor.fromInt(0xFF475569);
  static const PdfColor _muted = PdfColor.fromInt(0xFF64748B);
  static const PdfColor _faint = PdfColor.fromInt(0xFF94A3B8);
  static const PdfColor _border = PdfColor.fromInt(0xFFE2E8F0);
  static const PdfColor _surface = PdfColor.fromInt(0xFFF8FAFC);
  static const PdfColor _tableHeader = PdfColor.fromInt(0xFFF1F5F9);
  static const PdfColor _paidBg = PdfColor.fromInt(0xFFDCFCE7);
  static const PdfColor _paidFg = PdfColor.fromInt(0xFF15803D);

  Future<Uint8List> buildServiceInvoicePdf({
    required ServiceRequest request,
    Customer? customer,
    required String invoiceNumber,
    required DateTime completedAt,
    required String businessName,
    required String businessPhone,
    required String businessAddress,
    Map<String, double> mrpMap = const {},
  }) async {
    final customerName = customer?.name ?? request.customerName;
    final customerPhone = customer?.phone ?? 'N/A';
    final customerAddress = customer?.area ?? request.address;
    final model = customer?.model ?? request.model;
    final technician = (request.technicianName ?? '').trim().isEmpty
        ? 'Unassigned'
        : request.technicianName!.trim();
    final notes = (request.notes ?? '').trim().isEmpty
        ? 'Service completed successfully.'
        : request.notes!.trim();
    final totalAmount = request.totalAmount;
    // Exported invoices are generated for completed services, which are
    // recorded as fully paid (see OperationsRepository.exportServiceInvoice).
    final amountPaid = totalAmount;
    final balanceDue = totalAmount - amountPaid;

    final doc = pw.Document(
      title: invoiceNumber,
      author: businessName,
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 42),
        footer: (context) => _buildPageFooter(context, businessName),
        build: (context) => [
          _buildHeader(
            invoiceNumber: invoiceNumber,
            completedAt: completedAt,
            businessName: businessName,
            businessPhone: businessPhone,
            businessAddress: businessAddress,
          ),
          pw.SizedBox(height: 20),
          _buildPartiesRow(
            customerName: customerName,
            customerPhone: customerPhone,
            customerAddress: customerAddress,
            serviceType: request.type,
            model: model,
            technician: technician,
            completedTime: request.time,
          ),
          pw.SizedBox(height: 24),
          _buildSectionLabel('SPARE PARTS & LABOUR'),
          pw.SizedBox(height: 8),
          _buildItemsTable(request, mrpMap),
          pw.SizedBox(height: 20),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(child: _buildNotesCard(notes)),
              pw.SizedBox(width: 16),
              pw.SizedBox(
                width: 210,
                child: _buildSummaryCard(
                  subtotal: totalAmount,
                  total: totalAmount,
                  amountPaid: amountPaid,
                  balanceDue: balanceDue,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return doc.save();
  }

  String _money(num value) =>
      'Rs. ${formatRupee(value, decimalDigits: 2, includeSymbol: false)}';

  String _formatDate(DateTime value) {
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
    return '${value.day.toString().padLeft(2, '0')} ${labels[value.month - 1]} ${value.year}';
  }

  pw.Widget _buildHeader({
    required String invoiceNumber,
    required DateTime completedAt,
    required String businessName,
    required String businessPhone,
    required String businessAddress,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 18),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: _border, width: 1.5),
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Service Invoice',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: _accent,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  invoiceNumber,
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: _muted,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: pw.BoxDecoration(
                    color: _paidBg,
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                  child: pw.Text(
                    'PAID',
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: _paidFg,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                businessName,
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: _ink,
                ),
              ),
              if (businessPhone.trim().isNotEmpty) ...[
                pw.SizedBox(height: 3),
                pw.Text(
                  'Phone: ${businessPhone.trim()}',
                  style: const pw.TextStyle(fontSize: 10, color: _slate),
                ),
              ],
              if (businessAddress.trim().isNotEmpty) ...[
                pw.SizedBox(height: 3),
                pw.ConstrainedBox(
                  constraints: const pw.BoxConstraints(maxWidth: 220),
                  child: pw.Text(
                    businessAddress.trim(),
                    style: const pw.TextStyle(fontSize: 9, color: _slate),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
              ],
              pw.SizedBox(height: 6),
              pw.Text(
                'Issued: ${_formatDate(completedAt)}',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: _faint,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSectionLabel(String label) {
    return pw.Text(
      label,
      style: pw.TextStyle(
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
        color: _muted,
        letterSpacing: 1.2,
      ),
    );
  }

  pw.Widget _buildPartiesRow({
    required String customerName,
    required String customerPhone,
    required String customerAddress,
    required String serviceType,
    required String model,
    required String technician,
    required String completedTime,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: _buildDetailsCard(
            title: 'BILLED TO',
            lines: [
              _DetailLine(customerName, emphasized: true),
              _DetailLine('Phone: $customerPhone'),
              _DetailLine('Address: $customerAddress'),
            ],
          ),
        ),
        pw.SizedBox(width: 16),
        pw.Expanded(
          child: _buildDetailsCard(
            title: 'SERVICE DETAILS',
            lines: [
              _DetailLine(serviceType, emphasized: true),
              _DetailLine('Model: $model'),
              _DetailLine('Technician: $technician'),
              _DetailLine('Completed: $completedTime'),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildDetailsCard({
    required String title,
    required List<_DetailLine> lines,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: _surface,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: _border),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildSectionLabel(title),
          pw.SizedBox(height: 8),
          for (final line in lines)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 3),
              child: pw.Text(
                line.text,
                style: line.emphasized
                    ? pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: _ink,
                      )
                    : const pw.TextStyle(fontSize: 10, color: _slate),
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _buildItemsTable(
    ServiceRequest request,
    Map<String, double> mrpMap,
  ) {
    final headerStyle = pw.TextStyle(
      fontSize: 9,
      fontWeight: pw.FontWeight.bold,
      color: _slate,
      letterSpacing: 0.5,
    );
    const cellStyle = pw.TextStyle(fontSize: 10, color: _slate);
    final boldCellStyle = pw.TextStyle(
      fontSize: 10,
      fontWeight: pw.FontWeight.bold,
      color: _ink,
    );

    pw.Widget cell(
      String text, {
      pw.TextStyle? style,
      pw.TextAlign align = pw.TextAlign.left,
    }) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: pw.Text(text, style: style ?? cellStyle, textAlign: align),
      );
    }

    final rows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: _tableHeader),
        children: [
          cell('ITEM / SPARE PART', style: headerStyle),
          cell('QTY', style: headerStyle, align: pw.TextAlign.center),
          cell('MRP', style: headerStyle, align: pw.TextAlign.right),
          cell('PRICE', style: headerStyle, align: pw.TextAlign.right),
          cell('TOTAL', style: headerStyle, align: pw.TextAlign.right),
        ],
      ),
    ];

    if (request.inventoryItems.isEmpty) {
      rows.add(
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(14),
              child: pw.Text(
                'No inventory items were added to this service.',
                style: pw.TextStyle(
                  fontSize: 10,
                  color: _muted,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ),
            pw.SizedBox(),
            pw.SizedBox(),
            pw.SizedBox(),
            pw.SizedBox(),
          ],
        ),
      );
    } else {
      for (final item in request.inventoryItems) {
        final mrp = mrpMap[item.inventoryItemId] ?? item.unitPrice;
        rows.add(
          pw.TableRow(
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: _border)),
            ),
            children: [
              cell(item.name, style: boldCellStyle),
              cell('${item.quantity}', align: pw.TextAlign.center),
              cell(_money(mrp), align: pw.TextAlign.right),
              cell(_money(item.unitPrice), align: pw.TextAlign.right),
              cell(
                _money(item.lineTotal),
                style: boldCellStyle,
                align: pw.TextAlign.right,
              ),
            ],
          ),
        );
      }
    }

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _border),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Table(
        columnWidths: const {
          0: pw.FlexColumnWidth(3),
          1: pw.FlexColumnWidth(0.9),
          2: pw.FlexColumnWidth(1.4),
          3: pw.FlexColumnWidth(1.4),
          4: pw.FlexColumnWidth(1.5),
        },
        children: rows,
      ),
    );
  }

  pw.Widget _buildNotesCard(String notes) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: _surface,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: _border),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('SERVICE NOTES'),
          pw.SizedBox(height: 6),
          pw.Text(
            notes,
            style: const pw.TextStyle(fontSize: 10, color: _slate, lineSpacing: 2),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummaryCard({
    required double subtotal,
    required double total,
    required double amountPaid,
    required double balanceDue,
  }) {
    pw.Widget row(String label, String value, {bool isTotal = false}) {
      return pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: isTotal ? 12 : 10,
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: isTotal ? PdfColors.white : _faint,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: isTotal ? 13 : 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
        ],
      );
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: _ink,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        children: [
          row('Subtotal', _money(subtotal)),
          pw.SizedBox(height: 6),
          row('Tax (GST 0%)', _money(0)),
          pw.SizedBox(height: 8),
          pw.Divider(color: PdfColors.white, thickness: 0.5, height: 1),
          pw.SizedBox(height: 8),
          row('Total', _money(total), isTotal: true),
          pw.SizedBox(height: 6),
          row('Amount Paid', _money(amountPaid)),
          pw.SizedBox(height: 6),
          row('Balance Due', _money(balanceDue)),
        ],
      ),
    );
  }

  pw.Widget _buildPageFooter(pw.Context context, String businessName) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _border, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Thank you for choosing $businessName!',
            style: const pw.TextStyle(fontSize: 9, color: _faint),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: _faint),
          ),
        ],
      ),
    );
  }
}

class _DetailLine {
  final String text;
  final bool emphasized;

  const _DetailLine(this.text, {this.emphasized = false});
}
