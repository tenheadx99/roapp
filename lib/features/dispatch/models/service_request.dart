import 'package:equatable/equatable.dart';

class ServiceRequest extends Equatable {
  final String id;
  final String customerName;
  final String address;
  final String type;
  final String model;
  final String time;
  final String status; // 'new' | 'assigned' | 'in_progress' | 'completed'
  final String? scheduledFor;
  final String? technicianName;
  final String? notes;

  const ServiceRequest({
    required this.id,
    required this.customerName,
    required this.address,
    required this.type,
    required this.model,
    required this.time,
    required this.status,
    this.scheduledFor,
    this.technicianName,
    this.notes,
  });

  factory ServiceRequest.fromMap(Map<String, dynamic> map) {
    return ServiceRequest(
      id: map['id'] as String,
      customerName: map['customerName'] as String,
      address: map['address'] as String,
      type: map['type'] as String,
      model: map['model'] as String,
      time: map['time'] as String,
      status: map['status'] as String,
      scheduledFor: map['scheduledFor'] as String?,
      technicianName: map['technicianName'] as String?,
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerName': customerName,
      'address': address,
      'type': type,
      'model': model,
      'time': time,
      'status': status,
      'scheduledFor': scheduledFor,
      'technicianName': technicianName,
      'notes': notes,
    };
  }

  @override
  List<Object?> get props => [
    id,
    customerName,
    address,
    type,
    model,
    time,
    status,
    scheduledFor,
    technicianName,
    notes,
  ];

  ServiceRequest copyWith({
    String? id,
    String? customerName,
    String? address,
    String? type,
    String? model,
    String? time,
    String? status,
    String? scheduledFor,
    String? technicianName,
    String? notes,
  }) {
    return ServiceRequest(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      address: address ?? this.address,
      type: type ?? this.type,
      model: model ?? this.model,
      time: time ?? this.time,
      status: status ?? this.status,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      technicianName: technicianName ?? this.technicianName,
      notes: notes ?? this.notes,
    );
  }

  String get statusLabel {
    switch (status) {
      case 'new':
        return 'NEW';
      case 'assigned':
        return 'ASSIGNED';
      case 'in_progress':
        return 'IN PROGRESS';
      case 'completed':
        return 'COMPLETED';
      default:
        return status.toUpperCase();
    }
  }
}
