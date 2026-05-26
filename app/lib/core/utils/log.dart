import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

// Thin wrapper around dart:developer's log() so we get tagged, leveled output
// in DevTools without scattering print()s through the codebase. Use this
// instead of `print` or silent `catch (_)` blocks — even rare failures should
// leave a breadcrumb.
//
// Levels match dart:developer convention (higher = more severe).
class Log {
  Log._();

  static const _levelFine = 500;
  static const _levelInfo = 800;
  static const _levelWarning = 900;
  static const _levelError = 1000;

  // In release builds, suppress anything below WARNING to keep logs quiet.
  static int get _threshold => kReleaseMode ? _levelWarning : _levelFine;

  static void debug(String tag, String message) =>
      _emit(_levelFine, tag, message);

  static void info(String tag, String message) =>
      _emit(_levelInfo, tag, message);

  static void warn(String tag, String message, [Object? error, StackTrace? st]) =>
      _emit(_levelWarning, tag, message, error, st);

  static void error(String tag, String message, [Object? error, StackTrace? st]) =>
      _emit(_levelError, tag, message, error, st);

  static void _emit(
    int level,
    String tag,
    String message, [
    Object? error,
    StackTrace? st,
  ]) {
    if (level < _threshold) return;
    developer.log(
      message,
      level: level,
      name: tag,
      error: error,
      stackTrace: st,
    );
  }
}
