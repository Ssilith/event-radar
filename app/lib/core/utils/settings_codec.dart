import 'package:event_radar/core/models/distance_unit.dart';
import 'package:flutter/material.dart';

//* (De)serialisation for the Hive 'settings' box; decoders fall back, never throw

//* String → ThemeMode (defaults to system)
ThemeMode themeModeFromStorage(String? raw) => switch (raw) {
  'light' => ThemeMode.light,
  'dark' => ThemeMode.dark,
  _ => ThemeMode.system,
};

//* ThemeMode → string
String themeModeToStorage(ThemeMode mode) => switch (mode) {
  ThemeMode.system => 'system',
  ThemeMode.light => 'light',
  ThemeMode.dark => 'dark',
};

//* String → DistanceUnit (defaults to km)
DistanceUnit distanceUnitFromStorage(String? raw) =>
    raw == 'mi' ? DistanceUnit.mi : DistanceUnit.km;

//* DistanceUnit → string
String distanceUnitToStorage(DistanceUnit unit) => unit.name;

//* String → Locale (null/empty = follow system)
Locale? localeFromStorage(String? raw) =>
    (raw == null || raw.isEmpty) ? null : Locale(raw);

//* String → bool with a fallback
bool boolFromStorage(String? raw, {required bool defaultValue}) => switch (raw) {
  '1' => true,
  '0' => false,
  _ => defaultValue,
};

//* bool → "1"/"0"
String boolToStorage(bool value) => value ? '1' : '0';
