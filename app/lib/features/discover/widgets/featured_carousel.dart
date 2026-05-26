import 'package:event_radar/core/models/event.dart';
import 'package:event_radar/features/discover/widgets/featured_card.dart';
import 'package:flutter/material.dart';

class FeaturedCarousel extends StatelessWidget {
  final List<Event> events;
  final Set<String> bookmarked;
  final ValueChanged<Event> onToggleBookmark;
  final ValueChanged<Event> onOpenDetails;

  const FeaturedCarousel({
    super.key,
    required this.events,
    required this.bookmarked,
    required this.onToggleBookmark,
    required this.onOpenDetails,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: events.length,
        itemBuilder: (ctx, i) => FeaturedCard(
          event: events[i],
          isSaved: bookmarked.contains(events[i].id),
          onToggleSave: () => onToggleBookmark(events[i]),
          onOpenDetails: () => onOpenDetails(events[i]),
        ),
      ),
    );
  }
}
