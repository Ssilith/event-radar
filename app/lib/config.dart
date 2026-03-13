class AppConfig {
  static const datasetsBase = String.fromEnvironment(
    'DATASETS_BASE',
    defaultValue: '',
  );

  static const triggerUrl = String.fromEnvironment(
    'TRIGGER_URL',
    defaultValue: '',
  );

  static void validate() {
    final missing = <String>[];
    if (datasetsBase.isEmpty) missing.add('DATASETS_BASE');
    if (triggerUrl.isEmpty) missing.add('TRIGGER_URL');
    if (missing.isNotEmpty) {
      throw StateError(
        'Missing required --dart-define values: ${missing.join(', ')}',
      );
    }
  }
}
