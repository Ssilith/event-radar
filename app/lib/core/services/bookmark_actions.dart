import 'package:event_radar/core/models/event.dart';
import 'package:event_radar/core/services/event_cache_service.dart';
import 'package:event_radar/core/services/notification_service.dart';
import 'package:event_radar/core/utils/event_time.dart';
import 'package:event_radar/l10n/generated/app_localizations.dart';

//* Bookmark write + reminder scheduling in one call
class BookmarkActions {
  BookmarkActions._();

  //* Toggle bookmark: schedule a reminder when saved, cancel it when removed
  static Future<bool> toggle(Event event, AppL10n l) async {
    final saved = await EventCacheService.toggleBookmark(event);
    if (saved) {
      final time = formatEventTime(event, 'HH:mm');
      final venuePart = event.venue == null ? '' : ' · ${event.venue}';
      await NotificationService.instance.scheduleEventReminder(
        event,
        title: l.notificationsTitle(event.title),
        body: l.notificationsBody(time, venuePart),
      );
    } else {
      await NotificationService.instance.cancelEventReminder(event.id);
    }
    return saved;
  }
}
