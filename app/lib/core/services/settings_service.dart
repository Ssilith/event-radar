import 'package:event_radar/core/models/distance_unit.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';

final _log = Logger('SettingsService');

// Persists user-tweakable app settings. Each value is a ValueListenable so
// dependent widgets (MaterialApp, distance labels, notification gates) can
// rebuild reactively. Locale of null follows the device locale.
class SettingsService {
  SettingsService._();
  static final SettingsService instance = SettingsService._();

  static const _boxName = 'settings';
  static const _keyThemeMode = 'theme_mode';
  static const _keyLocale = 'locale_code';
  static const _keyDistanceUnit = 'distance_unit';
  static const _keyNotificationsEnabled = 'notifications_enabled';

  Box<String>? _box;

  final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier<ThemeMode>(ThemeMode.system);
  final ValueNotifier<Locale?> locale = ValueNotifier<Locale?>(null);
  final ValueNotifier<DistanceUnit> distanceUnit =
      ValueNotifier<DistanceUnit>(DistanceUnit.km);
  final ValueNotifier<bool> notificationsEnabled =
      ValueNotifier<bool>(true);

  Future<void> init() async {
    try {
      _box = await Hive.openBox<String>(_boxName);
    } catch (e, s) {
      _log.warning('open box failed', e, s);
      return;
    }
    themeMode.value = _decodeThemeMode(_box?.get(_keyThemeMode));
    locale.value = _decodeLocale(_box?.get(_keyLocale));
    distanceUnit.value = _decodeDistanceUnit(_box?.get(_keyDistanceUnit));
    notificationsEnabled.value =
        _decodeBool(_box?.get(_keyNotificationsEnabled), defaultValue: true);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    await _box?.put(_keyThemeMode, _encodeThemeMode(mode));
  }

  Future<void> setLocale(Locale? value) async {
    locale.value = value;
    if (value == null) {
      await _box?.delete(_keyLocale);
    } else {
      await _box?.put(_keyLocale, value.languageCode);
    }
  }

  Future<void> setDistanceUnit(DistanceUnit unit) async {
    distanceUnit.value = unit;
    await _box?.put(_keyDistanceUnit, unit.name);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    notificationsEnabled.value = enabled;
    await _box?.put(_keyNotificationsEnabled, enabled ? '1' : '0');
  }

  static String _encodeThemeMode(ThemeMode m) => switch (m) {
        ThemeMode.system => 'system',
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
      };

  static ThemeMode _decodeThemeMode(String? raw) => switch (raw) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  static Locale? _decodeLocale(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return Locale(raw);
  }

  static DistanceUnit _decodeDistanceUnit(String? raw) => switch (raw) {
        'mi' => DistanceUnit.mi,
        _ => DistanceUnit.km,
      };

  static bool _decodeBool(String? raw, {required bool defaultValue}) =>
      switch (raw) {
        '1' => true,
        '0' => false,
        _ => defaultValue,
      };
}
