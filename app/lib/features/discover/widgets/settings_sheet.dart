import 'package:event_radar/core/models/distance_unit.dart';
import 'package:event_radar/core/services/settings_service.dart';
import 'package:event_radar/core/theme/app_colors.dart';
import 'package:event_radar/core/theme/app_shadows.dart';
import 'package:event_radar/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

//* Settings sheet: theme, language, distance unit, and reminders toggle
class SettingsSheet extends StatelessWidget {
  const SettingsSheet({super.key});

  //* Open the sheet. isScrollControlled matches the city picker so it has the
  //* same full-height drag-down-to-dismiss feel; the sheet paints its own bg.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.instance;
    //* Rebuild the whole sheet on a theme flip so its own AppColors refresh
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: settings.themeMode,
      builder: (context, _, _) => _SheetBody(settings: settings),
    );
  }
}

//* The sheet's scrollable body with all the preference rows
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
      //* Scroll view absorbs minor overflow from the adaptive switch tile
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
                //* Transparent Material so the ListTile has a paint surface
                //* above the sheet's coloured Container (Flutter asserts otherwise)
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

//* Small uppercased section label
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

//* Single-select pill row (theme/language/unit options)
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
                color: selected ? AppColors.onPrimary : AppColors.textBody,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
