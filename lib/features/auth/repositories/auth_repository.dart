import 'package:roapp/core/database/database_helper.dart';
import 'package:roapp/core/utils/passkey_hasher.dart';
import 'package:roapp/features/auth/models/user.dart';
import 'package:uuid/uuid.dart';
import 'package:sqflite/sqflite.dart';

class AuthRepository {
  static const String defaultAdminEmail = 'admin@roservice.com';
  static const String defaultAdminPasskey = 'password123';
  static const String _currentUserSettingKey = 'current_user_id';

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
        'passkey': PasskeyHasher.hash(defaultAdminPasskey),
        'name': 'Ramesh Admin',
        'phone': '+91 9876543210',
        'role': 'Operations Admin',
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
      'passkey': PasskeyHasher.hash(passkey),
    };

    int result = await db.insert('users', userMap);
    return result > 0;
  }

  Future<User?> loginWithPasskey(String email, String passkey) async {
    final db = await dbHelper.database;
    final normalizedEmail = email.trim().toLowerCase();
    final maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [normalizedEmail],
      limit: 1,
    );

    if (maps.isEmpty) return null;

    final storedPasskey = maps.first['passkey'] as String? ?? '';
    if (!PasskeyHasher.verify(passkey, storedPasskey)) {
      return null;
    }

    final user = User.fromMap(maps.first);
    if (!PasskeyHasher.isHashed(storedPasskey)) {
      // Legacy plaintext row: upgrade it now that we know the passkey.
      await db.update(
        'users',
        {'passkey': PasskeyHasher.hash(passkey)},
        where: 'id = ?',
        whereArgs: [user.id],
      );
    }
    await persistCurrentUser(user.id);
    return user;
  }

  Future<User?> getUserById(String id) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  Future<User> updateUserProfile(User user) async {
    final db = await dbHelper.database;
    final normalizedEmail = user.email.trim().toLowerCase();
    final existing = await db.query(
      'users',
      columns: ['id'],
      where: 'email = ? AND id != ?',
      whereArgs: [normalizedEmail, user.id],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      throw Exception('That email is already used by another account.');
    }

    await db.update(
      'users',
      {
        'email': normalizedEmail,
        'name': user.name.trim(),
        'phone': user.phone.trim(),
        'role': user.role.trim(),
      },
      where: 'id = ?',
      whereArgs: [user.id],
    );

    final updated = await getUserById(user.id);
    return updated ?? user;
  }

  Future<void> updateUserPasskey({
    required String userId,
    required String currentPasskey,
    required String newPasskey,
  }) async {
    final db = await dbHelper.database;
    final trimmedCurrent = currentPasskey.trim();
    final trimmedNew = newPasskey.trim();

    if (trimmedNew.length < 6) {
      throw Exception('New password must be at least 6 characters long.');
    }

    final matches = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    final storedPasskey = matches.isEmpty
        ? ''
        : matches.first['passkey'] as String? ?? '';
    if (matches.isEmpty || !PasskeyHasher.verify(trimmedCurrent, storedPasskey)) {
      throw Exception('Current password is incorrect.');
    }

    await db.update(
      'users',
      {'passkey': PasskeyHasher.hash(trimmedNew)},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  /// Verifies [passkey] against the stored credential of [userId], or against
  /// the current signed-in user when [userId] is omitted.
  Future<bool> verifyPasskey(String passkey, {String? userId}) async {
    final db = await dbHelper.database;
    String? id = userId;
    if (id == null) {
      final persisted = await getPersistedUser();
      id = persisted?.id;
    }
    if (id == null) return false;

    final rows = await db.query(
      'users',
      columns: ['passkey'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return false;
    final stored = rows.first['passkey'] as String? ?? '';
    return PasskeyHasher.verify(passkey, stored);
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
      'passkey': PasskeyHasher.hash(defaultAdminPasskey),
      'name': 'Ramesh Admin',
      'phone': '+91 9876543210',
      'role': 'Operations Admin',
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> persistCurrentUser(String userId) async {
    final db = await dbHelper.database;
    await db.insert('app_settings', {
      'key': _currentUserSettingKey,
      'value': userId,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> clearPersistedSession() async {
    final db = await dbHelper.database;
    await db.delete(
      'app_settings',
      where: 'key = ?',
      whereArgs: [_currentUserSettingKey],
    );
  }

  Future<User?> getPersistedUser() async {
    final db = await dbHelper.database;
    final sessionRows = await db.query(
      'app_settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [_currentUserSettingKey],
      limit: 1,
    );

    if (sessionRows.isEmpty) {
      return null;
    }

    final userId = sessionRows.first['value'] as String?;
    if ((userId ?? '').trim().isEmpty) {
      return null;
    }

    return getUserById(userId!);
  }
}
