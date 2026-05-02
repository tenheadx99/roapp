import 'package:equatable/equatable.dart';

class Invoice extends Equatable {
  final String id;
  final String customerId;
  final String invoiceNumber;
  final String issueDate;
  final String dueDate;
  final double totalAmount;
  final double paidAmount;
  final String status;
  final String notes;

  const Invoice({
    required this.id,
    required this.customerId,
    required this.invoiceNumber,
    required this.issueDate,
    required this.dueDate,
    required this.totalAmount,
    required this.paidAmount,
    required this.status,
    required this.notes,
  });

  double get balanceDue => totalAmount - paidAmount;
  bool get isPaid => balanceDue <= 0.01;
  bool get isOverdue {
    if (isPaid) return false;
    final due = DateTime.tryParse(dueDate);
    return due != null && due.isBefore(DateTime.now());
  }

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'] as String,
      customerId: map['customerId'] as String,
      invoiceNumber: map['invoiceNumber'] as String,
      issueDate: map['issueDate'] as String,
      dueDate: map['dueDate'] as String,
      totalAmount: (map['totalAmount'] as num).toDouble(),
      paidAmount: (map['paidAmount'] as num).toDouble(),
      status: map['status'] as String,
      notes: map['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'invoiceNumber': invoiceNumber,
      'issueDate': issueDate,
      'dueDate': dueDate,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'status': status,
      'notes': notes,
    };
  }

  @override
  List<Object?> get props => [
    id,
    customerId,
    invoiceNumber,
    issueDate,
    dueDate,
    totalAmount,
    paidAmount,
    status,
    notes,
  ];
}
