import 'package:event_radar/core/models/distance_unit.dart';
import 'package:event_radar/core/utils/settings_codec.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';

final _log = Logger('SettingsService');

//* App-wide preferences (theme/locale/unit/notifications), persisted in Hive
class SettingsService {
  SettingsService._();
  static final SettingsService instance = SettingsService._();

  static const _boxName = 'settings';
  static const _keyThemeMode = 'theme_mode';
  static const _keyLocale = 'locale_code';
  static const _keyDistanceUnit = 'distance_unit';
  static const _keyNotificationsEnabled = 'notifications_enabled';

  Box<String>? _box;

  final ValueNotifier<ThemeMode> themeMode = ValueNotifier<ThemeMode>(
    ThemeMode.system,
  );
  final ValueNotifier<Locale?> locale = ValueNotifier<Locale?>(null);
  final ValueNotifier<DistanceUnit> distanceUnit = ValueNotifier<DistanceUnit>(
    DistanceUnit.km,
  );
  final ValueNotifier<bool> notificationsEnabled = ValueNotifier<bool>(true);

  //* Open the box and load persisted values into the notifiers
  Future<void> init() async {
    try {
      _box = await Hive.openBox<String>(_boxName);
    } catch (e, s) {
      _log.warning('open box failed', e, s);
      return;
    }
    themeMode.value = themeModeFromStorage(_box?.get(_keyThemeMode));
    locale.value = localeFromStorage(_box?.get(_keyLocale));
    distanceUnit.value = distanceUnitFromStorage(_box?.get(_keyDistanceUnit));
    notificationsEnabled.value = boolFromStorage(
      _box?.get(_keyNotificationsEnabled),
      defaultValue: true,
    );
  }

  //* Update + persist the theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    await _box?.put(_keyThemeMode, themeModeToStorage(mode));
  }

  //* Update + persist the locale (null = follow system, clears the key)
  Future<void> setLocale(Locale? value) async {
    locale.value = value;
    if (value == null) {
      await _box?.delete(_keyLocale);
    } else {
      await _box?.put(_keyLocale, value.languageCode);
    }
  }

  //* Update + persist the distance unit
  Future<void> setDistanceUnit(DistanceUnit unit) async {
    distanceUnit.value = unit;
    await _box?.put(_keyDistanceUnit, distanceUnitToStorage(unit));
  }

  //* Update + persist whether reminders are enabled
  Future<void> setNotificationsEnabled(bool enabled) async {
    notificationsEnabled.value = enabled;
    await _box?.put(_keyNotificationsEnabled, boolToStorage(enabled));
  }
}
