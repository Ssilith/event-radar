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

  //* Initialize the plugin once (Android + iOS settings)
  Future<void> init() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/launcher_icon');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
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

  //* Schedule a reminder for a saved event (no-op if disabled/denied/past)
  Future<void> scheduleEventReminder(
    Event event, {
    required String title,
    required String body,
  }) async {
    if (!SettingsService.instance.notificationsEnabled.value) return;
    await init();
    if (!await ensurePermission()) return;

    //* Anchor in the venue's tz so it fires relative to where the event happens
    final venueTz = venueLocation(event.timezone);
    final reminder = _reminderTime(event, venueTz);
    if (reminder == null) return;

    try {
      await _plugin.zonedSchedule(
        id: _idFor(event.id),
        title: title,
        body: body,
        scheduledDate: reminder,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: 'Reminders for events you have saved.',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: event.id,
      );
    } catch (e, s) {
      _log.warning('zonedSchedule failed for ${event.id}', e, s);
    }
  }

  //* When to fire: 24h before start, else 24h from now; null if ended/ending
  tz.TZDateTime? _reminderTime(Event event, tz.Location venueTz) {
    final start = tz.TZDateTime.from(event.start, venueTz);
    final now = tz.TZDateTime.now(venueTz);

    final dayBefore = start.subtract(const Duration(days: 1));
    if (dayBefore.isAfter(now)) return dayBefore;

    final end = event.end == null
        ? start
        : tz.TZDateTime.from(event.end!, venueTz);
    if (!end.isAfter(now)) {
      _log.info('skipping reminder for ${event.id}: event already ended');
      return null;
    }

    final reminder = now.add(const Duration(days: 1));
    if (reminder.isAfter(end)) {
      _log.info('skipping reminder for ${event.id}: ends within 24h');
      return null;
    }
    return reminder;
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
