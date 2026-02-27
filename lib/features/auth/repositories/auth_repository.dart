import 'package:roapp/core/database/database_helper.dart';
import 'package:roapp/features/auth/models/user.dart';
import 'package:uuid/uuid.dart';
import 'package:sqflite/sqflite.dart';

class AuthRepository {
  final dbHelper = DatabaseHelper.instance;
  final uuid = const Uuid();

  Future<bool> registerUser({
    required String email,
    required String passkey,
  }) async {
    final db = await dbHelper.database;
    final Map<String, dynamic> userMap = {
      'id': uuid.v4(),
      'email': email,
      'passkey': passkey,
    };

    int result = await db.insert('users', userMap);
    return result > 0;
  }

  Future<User?> loginWithPasskey(String email, String passkey) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'users',
      where: 'email = ? AND passkey = ?',
      whereArgs: [email, passkey],
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
}
