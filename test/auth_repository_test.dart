import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:roapp/core/database/database_helper.dart';
import 'package:roapp/features/auth/repositories/auth_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('AuthRepository Tests', () {
    final authRepo = AuthRepository();

    test('Register and Login flow works', () async {
      final email = 'test@example.com';
      final passkey = 'some-passkey-data';

      // Ensure no user exists and database is fresh for this test
      // Actually, we can just delete from users table
      final db = await DatabaseHelper.instance.database;
      await db.delete('users');

      // Test userExists is false
      expect(await authRepo.userExists(), false);

      // Register
      final registered = await authRepo.registerUser(email: email, passkey: passkey);
      expect(registered, true);

      // Test userExists is true
      expect(await authRepo.userExists(), true);

      // Login success
      final user = await authRepo.loginWithPasskey(email, passkey);
      expect(user, isNotNull);
      expect(user!.email, email);

      // Login failure (wrong passkey)
      final wrongUser = await authRepo.loginWithPasskey(email, 'wrong-passkey');
      expect(wrongUser, isNull);
    });
  });
}
