import 'package:equatable/equatable.dart';

class Technician extends Equatable {
  final String id;
  final String name;
  final String phone;
  final String region;
  final List<String> hubs;
  final int tasksToday;
  final String status; // 'online' | 'offline' | 'on-leave'
  final String? avatar;

  const Technician({
    required this.id,
    required this.name,
    required this.phone,
    required this.region,
    required this.hubs,
    required this.tasksToday,
    required this.status,
    this.avatar,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    phone,
    region,
    hubs,
    tasksToday,
    status,
    avatar,
  ];
}
