import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

// Configures the package:logging root logger to forward records to DevTools
// via dart:developer.log. Each module owns a `Logger('SomeName')` and emits
// via `.fine/.info/.warning/.severe`; the LogRecord names propagate to the
// `name` field shown in DevTools, replacing the manual tag we used before.
//
// Release builds suppress anything below WARNING to keep production logs
// quiet without losing failure breadcrumbs.
void initLogger() {
  Logger.root.level = kReleaseMode ? Level.WARNING : Level.ALL;
  Logger.root.onRecord.listen((record) {
    developer.log(
      record.message,
      time: record.time,
      level: record.level.value,
      name: record.loggerName,
      error: record.error,
      stackTrace: record.stackTrace,
    );
  });
}
