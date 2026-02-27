import 'package:roapp/core/database/database_helper.dart';
import 'package:roapp/features/dispatch/models/service_request.dart';
import 'package:uuid/uuid.dart';

class DispatchRepository {
  final dbHelper = DatabaseHelper.instance;
  final uuid = const Uuid();

  Future<List<ServiceRequest>> getServiceRequests() async {
    final db = await dbHelper.database;
    final maps = await db.query('service_requests', orderBy: 'time ASC');
    return maps.map((e) => ServiceRequest.fromMap(e)).toList();
  }

  Future<ServiceRequest?> getServiceRequestById(String id) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'service_requests',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return ServiceRequest.fromMap(maps.first);
    }
    return null;
  }

  Future<void> addServiceRequest(ServiceRequest request) async {
    final db = await dbHelper.database;
    await db.insert('service_requests', request.toMap());
  }

  Future<void> updateServiceRequest(ServiceRequest request) async {
    final db = await dbHelper.database;
    await db.update(
      'service_requests',
      request.toMap(),
      where: 'id = ?',
      whereArgs: [request.id],
    );
  }

  Future<void> deleteServiceRequest(String id) async {
    final db = await dbHelper.database;
    await db.delete('service_requests', where: 'id = ?', whereArgs: [id]);
  }
}
