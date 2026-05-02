import 'package:roapp/core/database/database_helper.dart';
import 'package:roapp/features/auth/models/user.dart';
import 'package:uuid/uuid.dart';
import 'package:sqflite/sqflite.dart';

class AuthRepository {
  static const String defaultAdminEmail = 'admin@roservice.com';
  static const String defaultAdminPasskey = 'password123';

  final dbHelper = DatabaseHelper.instance;
  final uuid = const Uuid();

  Future<void> ensureDefaultUser() async {
    final db = await dbHelper.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM users'),
    );

    if ((count ?? 0) == 0) {
      await db.insert('users', {
        'id': 'default-admin',
        'email': defaultAdminEmail,
        'passkey': defaultAdminPasskey,
      });
    }
  }

  Future<bool> registerUser({
    required String email,
    required String passkey,
  }) async {
    final db = await dbHelper.database;
    final normalizedEmail = email.trim().toLowerCase();
    final existing = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [normalizedEmail],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      return false;
    }

    final Map<String, dynamic> userMap = {
      'id': uuid.v4(),
      'email': normalizedEmail,
      'passkey': passkey.trim(),
    };

    int result = await db.insert('users', userMap);
    return result > 0;
  }

  Future<User?> loginWithPasskey(String email, String passkey) async {
    final db = await dbHelper.database;
    final normalizedEmail = email.trim().toLowerCase();
    final maps = await db.query(
      'users',
      where: 'email = ? AND passkey = ?',
      whereArgs: [normalizedEmail, passkey.trim()],
    );

    if (maps.isNotEmpty) {
      return User(
        id: maps.first['id'] as String,
        email: maps.first['email'] as String,
      );
    }
    return null;
  }

  Future<bool> userExists() async {
    final db = await dbHelper.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM users'),
    );
    return (count ?? 0) > 0;
  }

  Future<void> resetDefaultAdminPasskey() async {
    final db = await dbHelper.database;
    await db.insert('users', {
      'id': 'default-admin',
      'email': defaultAdminEmail,
      'passkey': defaultAdminPasskey,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
