import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Salted SHA-256 hashing for user passkeys.
///
/// Stored format: `sha256$<salt>$<hash>`. Values that don't match this
/// format are treated as legacy plaintext so existing accounts keep
/// working and get re-hashed on their next successful login.
class PasskeyHasher {
  static const String _prefix = 'sha256';
  static final Random _random = Random.secure();

  static String hash(String passkey, {String? salt}) {
    final resolvedSalt = salt ?? _generateSalt();
    final digest = sha256
        .convert(utf8.encode('$resolvedSalt:${passkey.trim()}'))
        .toString();
    return '$_prefix\$$resolvedSalt\$$digest';
  }

  static bool isHashed(String stored) {
    final parts = stored.split(r'$');
    return parts.length == 3 && parts[0] == _prefix;
  }

  static bool verify(String passkey, String stored) {
    if (!isHashed(stored)) {
      return stored == passkey.trim();
    }
    final parts = stored.split(r'$');
    return hash(passkey, salt: parts[1]) == stored;
  }

  static String _generateSalt() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }
}
