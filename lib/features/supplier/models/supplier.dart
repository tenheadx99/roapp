import 'package:equatable/equatable.dart';

class Supplier extends Equatable {
  final String id;
  final String name;
  final String contactPerson;
  final String city;
  final List<String> specialties;
  final int activePOs;
  final String status; // 'active' | 'inactive'
  final String phone;
  final String email;

  const Supplier({
    required this.id,
    required this.name,
    required this.contactPerson,
    required this.city,
    required this.specialties,
    required this.activePOs,
    required this.status,
    this.phone = '',
    this.email = '',
  });

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'] as String,
      name: map['name'] as String,
      contactPerson: map['contactPerson'] as String,
      city: map['city'] as String,
      specialties: (map['specialties'] as String).split(','),
      activePOs: map['activePOs'] as int,
      status: map['status'] as String,
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'contactPerson': contactPerson,
      'city': city,
      'specialties': specialties.join(','),
      'activePOs': activePOs,
      'status': status,
      'phone': phone,
      'email': email,
    };
  }

  Supplier copyWith({
    String? id,
    String? name,
    String? contactPerson,
    String? city,
    List<String>? specialties,
    int? activePOs,
    String? status,
    String? phone,
    String? email,
  }) {
    return Supplier(
      id: id ?? this.id,
      name: name ?? this.name,
      contactPerson: contactPerson ?? this.contactPerson,
      city: city ?? this.city,
      specialties: specialties ?? this.specialties,
      activePOs: activePOs ?? this.activePOs,
      status: status ?? this.status,
      phone: phone ?? this.phone,
      email: email ?? this.email,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    contactPerson,
    city,
    specialties,
    activePOs,
    status,
    phone,
    email,
  ];
}
