import 'package:event_radar/services/event_cache_service.dart';
import 'package:flutter/material.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  final Set<String> _bookmarked = {};

  @override
  void initState() {
    super.initState();
    _bookmarked.addAll(EventCacheService.bookmarkedIds());
  }

  // Future<void> _toggleBookmark(Event event) async {
  //   final id = event.id;
  //   final wasSaved = _bookmarked.contains(id);
  //   setState(() {
  //     if (wasSaved) {
  //       _bookmarked.remove(id);
  //     } else {
  //       _bookmarked.add(id);
  //     }
  //   });
  //   await EventCacheService.toggleBookmark(event);
  // }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
