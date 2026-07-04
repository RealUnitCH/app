/// Boundary in front of the platform-specific "exclude this file from the
/// device backup" call, so callers (today: `AppDatabase`) can be unit-tested
/// without going through a platform channel.
///
/// Production wiring defaults to [BackupExclusionAdapter], which talks to the
/// iOS native side via a method channel. On Android the backup is already
/// disabled app-wide (`android:allowBackup="false"` in the manifest), so the
/// adapter is a no-op there. Tests supply a fake that records the paths.
abstract class BackupExclusionPort {
  /// Marks each existing file in [paths] as excluded from the OS backup
  /// (iCloud / iTunes / Finder on iOS via `NSURLIsExcludedFromBackupKey`).
  ///
  /// Best-effort and idempotent: paths that do not exist are skipped by the
  /// platform implementation, and re-applying the flag on an already-excluded
  /// file is a no-op — so it is safe to call on every app start.
  Future<void> excludeFromBackup(List<String> paths);
}
