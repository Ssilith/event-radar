import 'package:event_radar/core/config.dart';
import 'package:event_radar/core/services/event_cache_service.dart';
import 'package:event_radar/core/services/notification_service.dart';
import 'package:event_radar/core/services/settings_service.dart';
import 'package:event_radar/core/utils/event_time.dart';
import 'package:event_radar/core/utils/logger.dart';

// One-shot startup tasks. Keeps main.dart down to widgets-binding +
// splash-preserve + runApp, so the entrypoint reads as a thin shell and the
// init order lives in one named, documented place.
class AppBootstrap {
  AppBootstrap._();

  static Future<void> initialize() async {
    initLogger();
    AppConfig.validate();
    initVenueTime();
    await EventCacheService.init();
    await SettingsService.instance.init();
    await NotificationService.instance.init();
    _wireNotificationToggle();
  }

  // When the user turns reminders off, drop every scheduled notification so
  // stale ones don't fire later. Future bookmarks won't schedule because the
  // ValueNotifier gates `scheduleEventReminder`.
  static void _wireNotificationToggle() {
    SettingsService.instance.notificationsEnabled.addListener(() {
      if (!SettingsService.instance.notificationsEnabled.value) {
        NotificationService.instance.cancelAll();
      }
    });
  }
}
