import 'package:event_radar/core/config.dart';
import 'package:event_radar/core/services/event_cache_service.dart';
import 'package:event_radar/core/services/notification_service.dart';
import 'package:event_radar/core/services/settings_service.dart';
import 'package:event_radar/core/utils/event_time.dart';
import 'package:event_radar/core/utils/logger.dart';

//* One-shot startup tasks, in order, so main.dart stays a thin shell
class AppBootstrap {
  AppBootstrap._();

  //* Run all startup init (logger, config, tz, caches, settings, notifications)
  static Future<void> initialize() async {
    initLogger();
    AppConfig.validate();
    initVenueTime();
    await EventCacheService.init();
    await SettingsService.instance.init();
    await NotificationService.instance.init();
    _wireNotificationToggle();
  }

  //* Cancel all scheduled reminders whenever the user turns reminders off
  static void _wireNotificationToggle() {
    SettingsService.instance.notificationsEnabled.addListener(() {
      if (!SettingsService.instance.notificationsEnabled.value) {
        NotificationService.instance.cancelAll();
      }
    });
  }
}
