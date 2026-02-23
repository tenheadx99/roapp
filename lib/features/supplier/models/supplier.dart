import 'package:equatable/equatable.dart';

class Supplier extends Equatable {
  final String id;
  final String name;
  final String contactPerson;
  final String city;
  final List<String> specialties;
  final int activePOs;
  final String status; // 'active' | 'inactive'

  const Supplier({
    required this.id,
    required this.name,
    required this.contactPerson,
    required this.city,
    required this.specialties,
    required this.activePOs,
    required this.status,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    contactPerson,
    city,
    specialties,
    activePOs,
    status,
  ];
}
