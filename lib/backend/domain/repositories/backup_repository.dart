abstract class BackupRepository {
  /// Creates a backup of the current database to the specified [targetDirectory].
  /// Returns the full path of the created backup file.
  Future<String> createBackup(String targetDirectory);

  /// Restores the database from the specified [sourceFilePath].
  /// Warning: This will overwrite the current database.
  Future<void> restoreBackup(String sourceFilePath);
}
