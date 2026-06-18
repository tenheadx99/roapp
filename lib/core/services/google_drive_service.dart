import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/db_exporter.dart';

/// Backs up / restores the app database to a visible "RO App Backups" folder in
/// the user's Google Drive. Uses a single OAuth2 loopback flow (via
/// `googleapis_auth`) so it works on Android and Windows/Linux desktop with one
/// "Desktop app" OAuth client.
class GoogleDriveService {
  GoogleDriveService._();
  static final GoogleDriveService instance = GoogleDriveService._();

  /// Supply at build time:
  /// --dart-define=GDRIVE_CLIENT_ID=... --dart-define=GDRIVE_CLIENT_SECRET=...
  static const String _clientId = String.fromEnvironment('GDRIVE_CLIENT_ID');
  static const String _clientSecret = String.fromEnvironment(
    'GDRIVE_CLIENT_SECRET',
  );

  static const String backupFolderName = 'RO App Backups';
  static const String _credentialsKey = 'gdrive_creds';
  static const String _lastUploadKey = 'gdrive_last_upload_date';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ClientId get _googleClientId {
    if (_clientId.isEmpty || _clientSecret.isEmpty) {
      throw Exception(
        'Google Drive is not configured. Build with '
        '--dart-define=GDRIVE_CLIENT_ID=... and GDRIVE_CLIENT_SECRET=...',
      );
    }
    return ClientId(_clientId, _clientSecret);
  }

  Future<bool> isConnected() async {
    final stored = await _storage.read(key: _credentialsKey);
    return stored != null && stored.isNotEmpty;
  }

  /// Runs the OAuth consent flow in the system browser and stores the
  /// resulting credentials (incl. refresh token) for later silent reuse.
  Future<void> connect() async {
    final client = await clientViaUserConsent(
      _googleClientId,
      [drive.DriveApi.driveFileScope],
      _launchConsentUrl,
    );
    try {
      await _storage.write(
        key: _credentialsKey,
        value: jsonEncode(client.credentials.toJson()),
      );
    } finally {
      client.close();
    }
  }

  Future<void> disconnect() async {
    await _storage.delete(key: _credentialsKey);
    await _storage.delete(key: _lastUploadKey);
  }

  /// Fire-and-forget daily upload. Safe to call at startup: returns early when
  /// not connected or already uploaded today, and never throws.
  Future<void> silentAutoUpload() async {
    try {
      if (!await isConnected()) return;

      final today = DateTime.now().toIso8601String().substring(0, 10);
      final last = await _storage.read(key: _lastUploadKey);
      if (last == today) return;

      final dbFile = await DbExporter.dbFileForUpload();
      await uploadBackup(dbFile);
      await _storage.write(key: _lastUploadKey, value: today);
    } catch (_) {
      // Fail silently so app launch is never blocked by network/auth issues.
    }
  }

  /// Returns an auto-refreshing authenticated client, or null if not connected.
  /// Caller is responsible for closing the returned client.
  Future<AutoRefreshingAuthClient?> _authClient() async {
    final stored = await _storage.read(key: _credentialsKey);
    if (stored == null || stored.isEmpty) return null;
    final creds = AccessCredentials.fromJson(
      Map<String, dynamic>.from(jsonDecode(stored) as Map),
    );
    final client = autoRefreshingClient(
      _googleClientId,
      creds,
      http.Client(),
    );
    // Persist refreshed credentials so the stored refresh token stays current.
    client.credentialUpdates.listen((updated) {
      _storage.write(key: _credentialsKey, value: jsonEncode(updated.toJson()));
    });
    return client;
  }

  Future<void> _launchConsentUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not open the Google sign-in page.');
    }
  }

  /// Uploads [dbFile] to the "RO App Backups" folder as a timestamped .db file.
  Future<drive.File> uploadBackup(File dbFile) async {
    final client = await _authClient();
    if (client == null) {
      throw Exception('Not connected to Google Drive.');
    }
    try {
      final api = drive.DriveApi(client);
      final folderId = await _ensureBackupFolder(api);
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final media = drive.Media(
        dbFile.openRead(),
        await dbFile.length(),
        contentType: 'application/octet-stream',
      );
      final metadata = drive.File()
        ..name = 'roapp-backup-$timestamp.db'
        ..parents = [folderId];
      return await api.files.create(metadata, uploadMedia: media);
    } finally {
      client.close();
    }
  }

  /// Lists backups in the folder, newest first.
  Future<List<drive.File>> listBackups() async {
    final client = await _authClient();
    if (client == null) {
      throw Exception('Not connected to Google Drive.');
    }
    try {
      final api = drive.DriveApi(client);
      final folderId = await _ensureBackupFolder(api);
      final result = await api.files.list(
        q: "'$folderId' in parents and trashed = false",
        orderBy: 'modifiedTime desc',
        $fields: 'files(id,name,modifiedTime,size)',
        spaces: 'drive',
      );
      return result.files ?? <drive.File>[];
    } finally {
      client.close();
    }
  }

  /// Downloads a backup by id into a temp file and returns it.
  Future<File> downloadBackup(String fileId) async {
    final client = await _authClient();
    if (client == null) {
      throw Exception('Not connected to Google Drive.');
    }
    try {
      final api = drive.DriveApi(client);
      final media = await api.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final tmpDir = await getTemporaryDirectory();
      final tmpFile = File(p.join(tmpDir.path, 'roapp-restore-$fileId.db'));
      final sink = tmpFile.openWrite();
      await media.stream.pipe(sink);
      await sink.flush();
      await sink.close();
      return tmpFile;
    } finally {
      client.close();
    }
  }

  Future<String> _ensureBackupFolder(drive.DriveApi api) async {
    final existing = await api.files.list(
      q: "name = '$backupFolderName' and "
          "mimeType = 'application/vnd.google-apps.folder' and trashed = false",
      $fields: 'files(id,name)',
      spaces: 'drive',
    );
    final files = existing.files ?? <drive.File>[];
    if (files.isNotEmpty && files.first.id != null) {
      return files.first.id!;
    }
    final folder = drive.File()
      ..name = backupFolderName
      ..mimeType = 'application/vnd.google-apps.folder';
    final created = await api.files.create(folder);
    return created.id!;
  }
}
