import 'package:equatable/equatable.dart';

class AmcContract extends Equatable {
  final String id;
  final String customerId;
  final String contractName;
  final String startDate;
  final String endDate;
  final int visitsIncluded;
  final int visitsUsed;
  final double amount;
  final String status;
  final String renewalReminderDate;

  const AmcContract({
    required this.id,
    required this.customerId,
    required this.contractName,
    required this.startDate,
    required this.endDate,
    required this.visitsIncluded,
    required this.visitsUsed,
    required this.amount,
    required this.status,
    required this.renewalReminderDate,
  });

  int get visitsRemaining => visitsIncluded - visitsUsed;
  bool get isRenewalDue {
    final reminder = DateTime.tryParse(renewalReminderDate);
    return reminder != null && !reminder.isAfter(DateTime.now());
  }

  factory AmcContract.fromMap(Map<String, dynamic> map) {
    return AmcContract(
      id: map['id'] as String,
      customerId: map['customerId'] as String,
      contractName: map['contractName'] as String,
      startDate: map['startDate'] as String,
      endDate: map['endDate'] as String,
      visitsIncluded: map['visitsIncluded'] as int,
      visitsUsed: map['visitsUsed'] as int,
      amount: (map['amount'] as num).toDouble(),
      status: map['status'] as String,
      renewalReminderDate: map['renewalReminderDate'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'contractName': contractName,
      'startDate': startDate,
      'endDate': endDate,
      'visitsIncluded': visitsIncluded,
      'visitsUsed': visitsUsed,
      'amount': amount,
      'status': status,
      'renewalReminderDate': renewalReminderDate,
    };
  }

  @override
  List<Object?> get props => [
    id,
    customerId,
    contractName,
    startDate,
    endDate,
    visitsIncluded,
    visitsUsed,
    amount,
    status,
    renewalReminderDate,
  ];
}
