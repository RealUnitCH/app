/// Boundary in front of PackageManager's installer package so callers can be
/// unit-tested without a platform channel.
///
/// Production wiring is [InstallerPackageAdapter]. On Android it reads the
/// installing package name; everywhere else it returns null. Tests supply a
/// fake.
abstract class InstallerPackagePort {
  /// Installer package (e.g. `com.android.vending`), or null when none is
  /// available.
  Future<String?> readInstallerPackage();
}
