import 'package:event_radar/core/models/event.dart';
import 'package:event_radar/core/services/event_cache_service.dart';
import 'package:event_radar/core/services/notification_service.dart';
import 'package:event_radar/core/utils/event_time.dart';
import 'package:event_radar/l10n/generated/app_localizations.dart';

//* Bookmark write + reminder scheduling in one call
class BookmarkActions {
  BookmarkActions._();

  //* Toggle bookmark: schedule a reminder when saved, cancel it when removed.
  //* Returns whether it's now saved and, if a reminder was scheduled, when.
  static Future<({bool saved, DateTime? reminderAt})> toggle(
    Event event,
    AppL10n l,
  ) async {
    final saved = await EventCacheService.toggleBookmark(event);
    if (!saved) {
      await NotificationService.instance.cancelEventReminder(event.id);
      return (saved: false, reminderAt: null);
    }
    final time = formatEventTime(event, 'HH:mm');
    final timeLabel = venueTzDiffersFromPhone(event.timezone)
        ? '$time ${l.timeSuffix(venueTzShortName(event.timezone))}'
        : time;
    final venuePart = event.venue == null ? '' : ' · ${event.venue}';
    final reminderAt = await NotificationService.instance.scheduleEventReminder(
      event,
      title: l.notificationsTitle(event.title),
      body: l.notificationsBody(timeLabel, venuePart),
    );
    return (saved: true, reminderAt: reminderAt);
  }
}
