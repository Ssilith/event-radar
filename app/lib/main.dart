import 'package:event_radar/core/config.dart';
import 'package:event_radar/core/services/event_cache_service.dart';
import 'package:event_radar/core/services/notification_service.dart';
import 'package:event_radar/core/services/settings_service.dart';
import 'package:event_radar/core/theme/app_colors.dart';
import 'package:event_radar/core/utils/event_time.dart';
import 'package:event_radar/core/utils/logger.dart';
import 'package:event_radar/features/home/home_screen.dart';
import 'package:event_radar/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  initLogger();
  AppConfig.validate();
  initVenueTime();
  await EventCacheService.init();
  await SettingsService.instance.init();
  await NotificationService.instance.init();
  // When the user turns reminders off, drop every scheduled notification so
  // stale ones don't fire later. Future bookmarks won't schedule because the
  // ValueNotifier gates `scheduleEventReminder`.
  SettingsService.instance.notificationsEnabled.addListener(() {
    if (!SettingsService.instance.notificationsEnabled.value) {
      NotificationService.instance.cancelAll();
    }
  });
  FlutterNativeSplash.remove();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.instance;
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: settings.themeMode,
      builder: (_, mode, _) {
        return ValueListenableBuilder<Locale?>(
          valueListenable: settings.locale,
          builder: (ctx, locale, _) {
            AppColors.applyThemeMode(
              mode,
              MediaQuery.platformBrightnessOf(ctx),
            );
            return MaterialApp(
              onGenerateTitle: (c) => AppL10n.of(c).appTitle,
              debugShowCheckedModeBanner: false,
              themeMode: mode,
              theme: _buildTheme(Brightness.light),
              darkTheme: _buildTheme(Brightness.dark),
              locale: locale,
              localizationsDelegates: AppL10n.localizationsDelegates,
              supportedLocales: AppL10n.supportedLocales,
              home: const HomeScreen(),
            );
          },
        );
      },
    );
  }

  ThemeData _buildTheme(Brightness b) => ThemeData(
    brightness: b,
    useMaterial3: true,
    colorSchemeSeed: AppColors.primary,
    scaffoldBackgroundColor: b == Brightness.dark
        ? const Color(0xFF0A0A0A)
        : const Color(0xFFFAFAFA),
  );
}
