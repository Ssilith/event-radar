import 'package:event_radar/core/models/event.dart';
import 'package:event_radar/core/services/settings_service.dart';
import 'package:event_radar/core/utils/event_time.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logging/logging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;

final _log = Logger('NotificationService');

// Schedules T-1 day reminders for bookmarked events. Cancelled on unbookmark.
// Uses the event id (hashed to int) as the notification id so we can address
// each one without persisting an extra mapping.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const _channelId = 'saved_event_reminders';
  static const _channelName = 'Saved event reminders';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/launcher_icon');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );
    _initialized = true;
  }

  // Returns true when the user has granted us notification permission. On
  // older Android versions the permission is granted at install time so this
  // always returns true there.
  Future<bool> ensurePermission() async {
    final status = await Permission.notification.status;
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) return false;
    final result = await Permission.notification.request();
    return result.isGranted;
  }

  Future<void> scheduleEventReminder(
    Event event, {
    required String title,
    required String body,
  }) async {
    if (!SettingsService.instance.notificationsEnabled.value) return;
    await init();
    if (!await ensurePermission()) return;

    // The plugin's zoned scheduler needs a TZDateTime; we anchor everything in
    // the venue's location so reminders fire relative to where the event
    // actually happens.
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

  // Decides when a saved event's reminder should fire, in the venue's tz.
  //
  // - Normal case: 24h before the wall-clock start, so the user gets a
  //   heads-up the day before.
  // - Day-before slot already passed: happens for events saved inside that
  //   24h window, and for multi-day events saved after they've begun but
  //   while they're still running. Rather than drop the reminder, we simply
  //   fire 24h from now (from bookmarking) — as long as the event is still on
  //   by then.
  // - Returns null only when there's nothing left to remind about: the event
  //   has already ended, or it ends within the next 24h.
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

  Future<void> cancelEventReminder(String eventId) async {
    if (!_initialized) return;
    try {
      await _plugin.cancel(id: _idFor(eventId));
    } catch (e, s) {
      _log.warning('cancel failed for $eventId', e, s);
    }
  }

  Future<void> cancelAll() async {
    if (!_initialized) return;
    await _plugin.cancelAll();
  }

  // 32-bit signed int is all the platforms accept; xor-fold the SHA hex id.
  int _idFor(String eventId) {
    var h = 0;
    for (final c in eventId.codeUnits) {
      h = ((h << 5) - h + c) & 0x7fffffff;
    }
    return h;
  }
}
