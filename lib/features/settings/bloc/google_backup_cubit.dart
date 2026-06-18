import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:googleapis/drive/v3.dart' as drive;

import '../../../core/services/google_drive_service.dart';
import '../../../core/utils/db_exporter.dart';

// --- State ---
enum GoogleBackupStatus {
  idle,
  working,
  backupsLoaded,
  success,
  restored,
  failure,
}

class GoogleBackupState extends Equatable {
  final GoogleBackupStatus status;
  final bool connected;
  final String? message;
  final List<drive.File> backups;

  const GoogleBackupState({
    this.status = GoogleBackupStatus.idle,
    this.connected = false,
    this.message,
    this.backups = const [],
  });

  GoogleBackupState copyWith({
    GoogleBackupStatus? status,
    bool? connected,
    String? message,
    List<drive.File>? backups,
  }) {
    return GoogleBackupState(
      status: status ?? this.status,
      connected: connected ?? this.connected,
      message: message,
      backups: backups ?? this.backups,
    );
  }

  @override
  List<Object?> get props => [status, connected, message, backups];
}

// --- Cubit ---
class GoogleBackupCubit extends Cubit<GoogleBackupState> {
  final GoogleDriveService service;

  GoogleBackupCubit({GoogleDriveService? service})
    : service = service ?? GoogleDriveService.instance,
      super(const GoogleBackupState());

  Future<void> refreshStatus() async {
    final connected = await service.isConnected();
    emit(state.copyWith(status: GoogleBackupStatus.idle, connected: connected));
  }

  Future<void> connect() async {
    emit(
      state.copyWith(
        status: GoogleBackupStatus.working,
        message: 'Opening Google sign-in…',
      ),
    );
    try {
      await service.connect();
      emit(
        state.copyWith(
          status: GoogleBackupStatus.success,
          connected: true,
          message: 'Connected to Google Drive.',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: GoogleBackupStatus.failure, message: '$e'),
      );
    }
  }

  Future<void> disconnect() async {
    await service.disconnect();
    emit(
      state.copyWith(
        status: GoogleBackupStatus.idle,
        connected: false,
        backups: const [],
        message: 'Disconnected from Google Drive.',
      ),
    );
  }

  Future<void> backupNow() async {
    emit(
      state.copyWith(
        status: GoogleBackupStatus.working,
        message: 'Backing up to Google Drive…',
      ),
    );
    try {
      final dbFile = await DbExporter.dbFileForUpload();
      final uploaded = await service.uploadBackup(dbFile);
      emit(
        state.copyWith(
          status: GoogleBackupStatus.success,
          message: 'Backed up to Google Drive: ${uploaded.name}',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: GoogleBackupStatus.failure, message: '$e'),
      );
    }
  }

  Future<void> loadBackups() async {
    emit(
      state.copyWith(
        status: GoogleBackupStatus.working,
        message: 'Loading backups…',
      ),
    );
    try {
      final backups = await service.listBackups();
      emit(
        state.copyWith(
          status: GoogleBackupStatus.backupsLoaded,
          backups: backups,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: GoogleBackupStatus.failure, message: '$e'),
      );
    }
  }

  Future<void> restore(String fileId) async {
    emit(
      state.copyWith(
        status: GoogleBackupStatus.working,
        message: 'Restoring from Google Drive…',
      ),
    );
    try {
      final tmpFile = await service.downloadBackup(fileId);
      final message = await DbExporter.restoreFromFile(tmpFile);
      emit(
        state.copyWith(status: GoogleBackupStatus.restored, message: message),
      );
    } catch (e) {
      emit(
        state.copyWith(status: GoogleBackupStatus.failure, message: '$e'),
      );
    }
  }
}
