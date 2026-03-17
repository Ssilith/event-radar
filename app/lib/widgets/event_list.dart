import 'package:event_radar/models/event.dart';
import 'package:event_radar/models/event_category.dart';
import 'package:flutter/material.dart';

class EventList extends StatelessWidget {
  final List<Event> events;
  const EventList({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: events.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) => _EventTile(event: events[i]),
    );
  }
}

class _EventTile extends StatelessWidget {
  final Event event;
  const _EventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: scheme.primaryContainer,
        child: Text(
          _formatMonthDay(event.start),
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ),
      title: Text(event.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: event.venue != null
          ? Text(
              event.venue!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            )
          : null,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            event.category.value,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatMonthDay(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]}\n${dt.day}';
  }
}
