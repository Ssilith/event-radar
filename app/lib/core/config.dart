//* Build-time config from --dart-define
class AppConfig {
  //* Base URL of the Vercel deployment
  static const vercelBase = String.fromEnvironment('VERCEL_BASE');

  //* Datasets proxy endpoint
  static String get datasetsBase => '$vercelBase/api/datasets';
  //* Scrape-trigger endpoint
  static String get triggerUrl => '$vercelBase/api/trigger';

  //* Throw early if required config is missing
  static void validate() {
    if (vercelBase.isEmpty) {
      throw StateError('Missing --dart-define VERCEL_BASE');
    }
  }
}
