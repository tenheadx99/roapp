import 'package:equatable/equatable.dart';

class ServiceRequest extends Equatable {
  final String id;
  final String customerName;
  final String address;
  final String type;
  final String model;
  final String time;
  final String status; // 'new' | 'assigned' | 'in-progress'

  const ServiceRequest({
    required this.id,
    required this.customerName,
    required this.address,
    required this.type,
    required this.model,
    required this.time,
    required this.status,
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
  ];

  ServiceRequest copyWith({
    String? id,
    String? customerName,
    String? address,
    String? type,
    String? model,
    String? time,
    String? status,
  }) {
    return ServiceRequest(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      address: address ?? this.address,
      type: type ?? this.type,
      model: model ?? this.model,
      time: time ?? this.time,
      status: status ?? this.status,
    );
  }
}
