import 'package:roapp/core/database/database_helper.dart';
import 'package:roapp/features/technician/models/technician.dart';
import 'package:uuid/uuid.dart';

class TechnicianRepository {
  final dbHelper = DatabaseHelper.instance;
  final uuid = const Uuid();

  Future<List<Technician>> getTechnicians() async {
    final db = await dbHelper.database;
    final maps = await db.query('technicians');
    return maps.map((e) => Technician.fromMap(e)).toList();
  }

  Future<Technician?> getTechnicianById(String id) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'technicians',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Technician.fromMap(maps.first);
    }
    return null;
  }

  Future<void> addTechnician(Technician technician) async {
    final db = await dbHelper.database;
    await db.insert('technicians', technician.toMap());
  }

  Future<void> updateTechnician(Technician technician) async {
    final db = await dbHelper.database;
    await db.update(
      'technicians',
      technician.toMap(),
      where: 'id = ?',
      whereArgs: [technician.id],
    );
  }

  Future<void> deleteTechnician(String id) async {
    final db = await dbHelper.database;
    await db.delete('technicians', where: 'id = ?', whereArgs: [id]);
  }
}
