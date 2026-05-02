import 'package:equatable/equatable.dart';

class CommunicationLog extends Equatable {
  final String id;
  final String customerId;
  final String channel;
  final String note;
  final String createdAt;
  final String createdBy;

  const CommunicationLog({
    required this.id,
    required this.customerId,
    required this.channel,
    required this.note,
    required this.createdAt,
    required this.createdBy,
  });

  factory CommunicationLog.fromMap(Map<String, dynamic> map) {
    return CommunicationLog(
      id: map['id'] as String,
      customerId: map['customerId'] as String,
      channel: map['channel'] as String,
      note: map['note'] as String,
      createdAt: map['createdAt'] as String,
      createdBy: map['createdBy'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'channel': channel,
      'note': note,
      'createdAt': createdAt,
      'createdBy': createdBy,
    };
  }

  @override
  List<Object?> get props => [id, customerId, channel, note, createdAt, createdBy];
}
