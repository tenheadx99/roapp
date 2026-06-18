import 'package:equatable/equatable.dart';

class Customer extends Equatable {
  final String id;
  final String name;
  final String phone;
  final String model;
  final String
  status; // 'Service Due' | 'Operational' | 'AMC Plan' | 'Pending Install'
  final String lastService;
  final String area;
  final String? installationDate;
  final String? upcomingServiceDate;
  final String? updatedAt;

  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.model,
    required this.status,
    required this.lastService,
    required this.area,
    this.installationDate,
    this.upcomingServiceDate,
    this.updatedAt,
  });

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String,
      model: map['model'] as String,
      status: map['status'] as String,
      lastService: map['lastService'] as String,
      area: map['area'] as String,
      installationDate: map['installationDate'] as String?,
      upcomingServiceDate: map['upcomingServiceDate'] as String?,
      updatedAt: map['updatedAt'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'model': model,
      'status': status,
      'lastService': lastService,
      'area': area,
      'installationDate': installationDate,
      'upcomingServiceDate': upcomingServiceDate,
      'updatedAt': updatedAt,
    };
  }

  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? model,
    String? status,
    String? lastService,
    String? area,
    String? installationDate,
    String? upcomingServiceDate,
    String? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      model: model ?? this.model,
      status: status ?? this.status,
      lastService: lastService ?? this.lastService,
      area: area ?? this.area,
      installationDate: installationDate ?? this.installationDate,
      upcomingServiceDate: upcomingServiceDate ?? this.upcomingServiceDate,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  int get numericId {
    // Generate a stable 5-digit integer from the string ID
    return (id.hashCode & 0x7FFFFFFF) % 90000 + 10000;
  }

  @override
  List<Object?> get props => [
    id,
    name,
    phone,
    model,
    status,
    lastService,
    area,
    installationDate,
    upcomingServiceDate,
    updatedAt,
  ];
}
