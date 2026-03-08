// ignore_for_file: avoid_slow_async_io

import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:poultry_accounting/core/constants/app_constants.dart';
import 'package:poultry_accounting/backend/domain/repositories/backup_repository.dart';


class BackupRepositoryImpl implements BackupRepository {
  @override
  Future<String> createBackup(String targetDirectory) async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dbFolder.path, AppConstants.databaseName);
    final dbFile = File(dbPath);

    if (!await dbFile.exists()) {
      throw Exception('ظ…ظ„ظپ ظ‚ط§ط¹ط¯ط© ط§ظ„ط¨ظٹط§ظ†ط§طھ ط؛ظٹط± ظ…ظˆط¬ظˆط¯ ظپظٹ ط§ظ„ظ…ط³ط§ط±: $dbPath');
    }

    final timestamp = DateFormat('yyyy_MM_dd_HHmm').format(DateTime.now());
    final backupFileName = 'poultry_backup_$timestamp.sqlite';
    final backupPath = p.join(targetDirectory, backupFileName);

    await dbFile.copy(backupPath);
    return backupPath;
  }

  @override
  Future<void> restoreBackup(String sourceFilePath) async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dbFolder.path, AppConstants.databaseName);
    final targetFile = File(dbPath);

    final sourceFile = File(sourceFilePath);
    if (!await sourceFile.exists()) {
      throw Exception('ظ…ظ„ظپ ط§ظ„ظ†ط³ط®ط© ط§ظ„ط§ط­طھظٹط§ط·ظٹط© ط؛ظٹط± ظ…ظˆط¬ظˆط¯');
    }

    // Attempt to overwrite the database file.
    // Note: If the database is currently open and locked by the OS (common on Windows),
    // this might fail. Ideally, we should close the DB connection before calling this.
    // Since we are in a decoupled repository, we assume the UI/Service layer might 
    // handle the "Restart" warning or we try strict copy.
    try {
      await sourceFile.copy(targetFile.path);
    } catch (e) {
      throw Exception('ظپط´ظ„ ط§ط³طھط¹ط§ط¯ط© ط§ظ„ظ†ط³ط®ط© ط§ظ„ط§ط­طھظٹط§ط·ظٹط©. ظ‚ط¯ ظٹظƒظˆظ† ط§ظ„ظ…ظ„ظپ ظ‚ظٹط¯ ط§ظ„ط§ط³طھط®ط¯ط§ظ…. ط­ط§ظˆظ„ ط¥ط¹ط§ط¯ط© طھط´ط؛ظٹظ„ ط§ظ„ط¨ط±ظ†ط§ظ…ط¬.\nط§ظ„ط®ط·ط£: $e');
    }
  }
}
