import 'package:event_radar/core/app_bootstrap.dart';
import 'package:event_radar/core/services/settings_service.dart';
import 'package:event_radar/core/theme/app_colors.dart';
import 'package:event_radar/app_shell.dart';
import 'package:event_radar/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

//* Entry point: hold the splash, run startup init, then launch the app
Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await AppBootstrap.initialize();
  FlutterNativeSplash.remove();
  runApp(const MyApp());
}

//* Root widget: rebuilds MaterialApp on theme/locale change
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
              //* AppShell subscribes to themeMode itself and rebuilds its tabs
              //* on a flip, so it can stay const here (see app_shell.dart)
              home: const AppShell(),
            );
          },
        );
      },
    );
  }

  //* ThemeData for a given brightness
  ThemeData _buildTheme(Brightness b) => ThemeData(
    brightness: b,
    useMaterial3: true,
    colorSchemeSeed: AppColors.primary,
    scaffoldBackgroundColor: b == Brightness.dark
        ? const Color(0xFF0A0A0A)
        : const Color(0xFFF2F5F9),
  );
}
