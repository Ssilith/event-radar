class AppConfig {
  static const vercelBase = String.fromEnvironment('VERCEL_BASE');

  static String get datasetsBase => '$vercelBase/api/datasets';
  static String get triggerUrl => '$vercelBase/api/trigger';

  static void validate() {
    if (vercelBase.isEmpty) {
      throw StateError('Missing --dart-define VERCEL_BASE');
    }
  }
}
