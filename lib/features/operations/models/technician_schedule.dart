import 'package:equatable/equatable.dart';

class TechnicianSchedule extends Equatable {
  final String id;
  final String technicianId;
  final String scheduleDate;
  final String routeArea;
  final String plannedStops;
  final String checklist;
  final String leaveStatus;

  const TechnicianSchedule({
    required this.id,
    required this.technicianId,
    required this.scheduleDate,
    required this.routeArea,
    required this.plannedStops,
    required this.checklist,
    required this.leaveStatus,
  });

  factory TechnicianSchedule.fromMap(Map<String, dynamic> map) {
    return TechnicianSchedule(
      id: map['id'] as String,
      technicianId: map['technicianId'] as String,
      scheduleDate: map['scheduleDate'] as String,
      routeArea: map['routeArea'] as String,
      plannedStops: map['plannedStops'] as String,
      checklist: map['checklist'] as String,
      leaveStatus: map['leaveStatus'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'technicianId': technicianId,
      'scheduleDate': scheduleDate,
      'routeArea': routeArea,
      'plannedStops': plannedStops,
      'checklist': checklist,
      'leaveStatus': leaveStatus,
    };
  }

  @override
  List<Object?> get props => [
    id,
    technicianId,
    scheduleDate,
    routeArea,
    plannedStops,
    checklist,
    leaveStatus,
  ];
}
