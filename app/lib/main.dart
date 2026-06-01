import 'package:event_radar/core/app_bootstrap.dart';
import 'package:event_radar/core/services/settings_service.dart';
import 'package:event_radar/core/theme/app_colors.dart';
import 'package:event_radar/app_shell.dart';
import 'package:event_radar/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await AppBootstrap.initialize();
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
              // AppShell's screens read colours from the global AppColors
              // tokens rather than Theme.of(context), so they have no
              // inherited dependency that fires on a theme flip. The
              // MaterialApp above does rebuild, but the initial route (and a
              // const AppShell) is insulated by the Navigator and is not
              // re-run. Re-listening to themeMode here, inside the route,
              // forces AppShell to rebuild so its whole subtree repaints with
              // the new brightness. A non-const AppShell is required: a const
              // instance is identity-equal across rebuilds and Flutter would
              // skip it, whereas a fresh instance with the same type/key
              // updates the element while preserving _AppShellState.
              home: ValueListenableBuilder<ThemeMode>(
                valueListenable: settings.themeMode,
                // ignore: prefer_const_constructors
                builder: (_, _, _) => AppShell(),
              ),
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
