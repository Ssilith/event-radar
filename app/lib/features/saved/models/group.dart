import 'package:event_radar/core/models/event.dart';

// A bucket of bookmarked events with a header label. `emphasis` flags the
// "current city" or "Today" group for visual highlighting.
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
