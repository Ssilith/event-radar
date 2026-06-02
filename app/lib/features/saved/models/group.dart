import 'package:event_radar/core/models/event.dart';

//* A labelled bucket of bookmarks; emphasis flags "current city"/"Today"
class Group {
  final String label;
  final List<Event> events;
  final bool emphasis;
  const Group({
    required this.label,
    required this.events,
    required this.emphasis,
  });
}
