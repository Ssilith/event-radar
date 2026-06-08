import 'package:app_settings/app_settings.dart';
import 'package:event_radar/core/models/event.dart';
import 'package:event_radar/core/services/settings_service.dart';
import 'package:event_radar/core/utils/event_time.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logging/logging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;

final _log = Logger('NotificationService');

//* Schedules saved-event reminders; notification id = hashed event id
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const _channelId = 'saved_event_reminders';
  static const _channelName = 'Saved event reminders';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  //* Shared look: a high-importance heads-up that persists in the shade, so
  //* reminders pop up and aren't easy to miss
  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Reminders for events you have saved.',
      importance: Importance.max,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  //* Initialize the plugin once (Android + iOS settings)
  Future<void> init() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/launcher_icon');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );
    //* Create the channel up front with max importance (a channel's importance
    //* is fixed at creation, so this must match the details above)
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: 'Reminders for events you have saved.',
            importance: Importance.max,
          ),
        );
    _initialized = true;
  }

  //* True when notification permission is granted (requests it if undetermined)
  Future<bool> ensurePermission() async {
    final status = await Permission.notification.status;
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) return false;
    final result = await Permission.notification.request();
    return result.isGranted;
  }

  //* Schedule a reminder for a saved event; returns the fire time when one was
  //* set, or null if nothing was scheduled (disabled / denied / past)
  Future<DateTime?> scheduleEventReminder(
    Event event, {
    required String title,
    required String body,
  }) async {
    if (!SettingsService.instance.notificationsEnabled.value) return null;
    await init();
    //* Reminders are on in-app, so the OS permission must be granted too —
    //* if it isn't (and can't be requested), send the user to app settings
    if (!await ensurePermission()) {
      await AppSettings.openAppSettings(type: AppSettingsType.notification);
      return null;
    }

    //* Anchor in the venue's tz so it fires relative to where the event happens
    final venueTz = venueLocation(event.timezone);
    final reminder = _reminderTime(event, venueTz);
    if (reminder == null) return null;

    try {
      await _plugin.zonedSchedule(
        id: _idFor(event.id),
        title: title,
        body: body,
        scheduledDate: reminder,
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: event.id,
      );
      return reminder;
    } catch (e, s) {
      _log.warning('zonedSchedule failed for ${event.id}', e, s);
      return null;
    }
  }

  //* Fire 24h before start; null when the event is less than 24h away (or past)
  //* — we only remind a full day ahead, never for imminent events
  tz.TZDateTime? _reminderTime(Event event, tz.Location venueTz) {
    final start = tz.TZDateTime.from(event.start, venueTz);
    final now = tz.TZDateTime.now(venueTz);
    final dayBefore = start.subtract(const Duration(days: 1));
    if (!dayBefore.isAfter(now)) return null;
    return dayBefore;
  }

  //* Cancel a single event's reminder
  Future<void> cancelEventReminder(String eventId) async {
    if (!_initialized) return;
    try {
      await _plugin.cancel(id: _idFor(eventId));
    } catch (e, s) {
      _log.warning('cancel failed for $eventId', e, s);
    }
  }

  //* Cancel every scheduled reminder (used when reminders are turned off)
  Future<void> cancelAll() async {
    if (!_initialized) return;
    await _plugin.cancelAll();
  }

  //* Fold the SHA hex event id into a 32-bit signed int for the notification id
  int _idFor(String eventId) {
    var h = 0;
    for (final c in eventId.codeUnits) {
      h = ((h << 5) - h + c) & 0x7fffffff;
    }
    return h;
  }
}
