import 'package:event_radar/core/models/distance_unit.dart';
import 'package:event_radar/core/services/settings_service.dart';
import 'package:event_radar/core/theme/app_colors.dart';
import 'package:event_radar/core/theme/app_shadows.dart';
import 'package:event_radar/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Bottom sheet exposing the two app-wide preferences: theme mode and locale.
// Tapping any chip writes through to SettingsService, which triggers MyApp to
// rebuild MaterialApp with the new values.
class SettingsSheet extends StatelessWidget {
  const SettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    // Background is painted inside the sheet (see build) — the route's own
    // backgroundColor is evaluated once on open and would not refresh when the
    // user flips the theme from inside the sheet.
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const SettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.instance;
    // Listening to themeMode here makes the WHOLE sheet rebuild on a flip, not
    // just the segmented chips. Without this, the title / handle / labels keep
    // reading the previous AppColors values because no parent rebuild reaches
    // them — the bottom-sheet route lives below MyApp's MaterialApp boundary.
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: settings.themeMode,
      builder: (context, _, _) => _SheetBody(settings: settings),
    );
  }
}

class _SheetBody extends StatelessWidget {
  final SettingsService settings;
  const _SheetBody({required this.settings});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: AppShadows.overlay,
      ),
      // SingleChildScrollView absorbs the borderline 2-px overflow that the
      // SwitchListTile's adaptive height can produce on smaller screens, and
      // keeps the sheet usable if future rows push it taller.
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: AppColors.borderStrong,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                l.settingsTitle,
                style: GoogleFonts.syne(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 18),
              _Section(label: l.themeLabel),
              const SizedBox(height: 8),
              _SegmentedRow<ThemeMode>(
                value: settings.themeMode.value,
                options: [
                  (ThemeMode.system, l.themeSystem),
                  (ThemeMode.light, l.themeLight),
                  (ThemeMode.dark, l.themeDark),
                ],
                onChanged: settings.setThemeMode,
              ),
              const SizedBox(height: 20),
              _Section(label: l.languageLabel),
              const SizedBox(height: 8),
              ValueListenableBuilder<Locale?>(
                valueListenable: settings.locale,
                builder: (_, locale, _) => _SegmentedRow<Locale?>(
                  value: locale,
                  options: [
                    (null, l.languageSystem),
                    (const Locale('en'), l.languageEnglish),
                    (const Locale('pl'), l.languagePolish),
                  ],
                  onChanged: settings.setLocale,
                ),
              ),
              const SizedBox(height: 20),
              _Section(label: l.distanceUnitLabel),
              const SizedBox(height: 8),
              ValueListenableBuilder<DistanceUnit>(
                valueListenable: settings.distanceUnit,
                builder: (_, unit, _) => _SegmentedRow<DistanceUnit>(
                  value: unit,
                  options: [
                    (DistanceUnit.km, l.distanceUnitKm),
                    (DistanceUnit.mi, l.distanceUnitMi),
                  ],
                  onChanged: settings.setDistanceUnit,
                ),
              ),
              const SizedBox(height: 20),
              _Section(label: l.notificationsLabel),
              const SizedBox(height: 4),
              ValueListenableBuilder<bool>(
                valueListenable: settings.notificationsEnabled,
                // ListTile paints its background/ink on the nearest Material
                // ancestor; the sheet's coloured Container sits between this
                // tile and the bottom-sheet Material, which would hide those
                // effects (Flutter asserts on it). A transparent Material here
                // gives the tile its own paint surface without adding any
                // colour over AppColors.surface.
                builder: (_, enabled, _) => Material(
                  type: MaterialType.transparency,
                  child: SwitchListTile.adaptive(
                    value: enabled,
                    onChanged: settings.setNotificationsEnabled,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      l.notificationsHint,
                      style: TextStyle(fontSize: 13, color: AppColors.textBody),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String label;
  const _Section({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        letterSpacing: 1.4,
        fontWeight: FontWeight.w700,
        color: AppColors.textHint,
      ),
    );
  }
}

class _SegmentedRow<T> extends StatelessWidget {
  final T value;
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;

  const _SegmentedRow({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final selected = opt.$1 == value;
        return GestureDetector(
          onTap: () => onChanged(opt.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: selected ? primary : Colors.transparent,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: selected ? primary : AppColors.borderStrong,
              ),
              boxShadow: selected ? AppShadows.subtle : null,
            ),
            child: Text(
              opt.$2,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? Colors.black : AppColors.textBody,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
