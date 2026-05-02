import 'package:equatable/equatable.dart';

class ServiceAttachment extends Equatable {
  final String id;
  final String customerId;
  final String? serviceRequestId;
  final String type;
  final String title;
  final String filePath;
  final String createdAt;

  const ServiceAttachment({
    required this.id,
    required this.customerId,
    required this.serviceRequestId,
    required this.type,
    required this.title,
    required this.filePath,
    required this.createdAt,
  });

  factory ServiceAttachment.fromMap(Map<String, dynamic> map) {
    return ServiceAttachment(
      id: map['id'] as String,
      customerId: map['customerId'] as String,
      serviceRequestId: map['serviceRequestId'] as String?,
      type: map['type'] as String,
      title: map['title'] as String,
      filePath: map['filePath'] as String,
      createdAt: map['createdAt'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'serviceRequestId': serviceRequestId,
      'type': type,
      'title': title,
      'filePath': filePath,
      'createdAt': createdAt,
    };
  }

  @override
  List<Object?> get props => [
    id,
    customerId,
    serviceRequestId,
    type,
    title,
    filePath,
    createdAt,
  ];
}
