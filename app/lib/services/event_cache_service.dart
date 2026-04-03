import 'dart:convert';
import 'dart:developer';

import 'package:event_radar/models/event.dart';
import 'package:hive_flutter/hive_flutter.dart';

class EventCacheService {
  EventCacheService._();

  static const _bookmarksBoxName = 'bookmarks';
  static Box<String>? _bookmarks;

  //* Initialization
  static Future<void> init() async {
    await Hive.initFlutter();
    _bookmarks = await Hive.openBox<String>(_bookmarksBoxName);
  }

  //* Add a bookmark
  static Future<void> addBookmark(Event event) async {
    if (_bookmarks == null) return;
    await _bookmarks!.put(event.id, jsonEncode(event.toJson()));
  }

  //* Remove a bookmark by id
  static Future<void> removeBookmark(String eventId) async {
    await _bookmarks?.delete(eventId);
  }

  //* Check if is bookmarked
  static bool _isBookmarked(String eventId) =>
      _bookmarks?.containsKey(eventId) ?? false;

  //* Get bookmarked event ids
  static Set<String> bookmarkedIds() =>
      _bookmarks?.keys.cast<String>().toSet() ?? {};

  //* Get bookmarked events sorted newest-start first
  static List<Event> getBookmarks() {
    if (_bookmarks == null) return [];
    final events = <Event>[];
    for (final key in _bookmarks!.keys) {
      final raw = _bookmarks!.get(key as String);
      if (raw == null) continue;
      try {
        events.add(Event.fromJson(jsonDecode(raw) as Map<String, dynamic>));
      } catch (e) {
        log(e.toString());
      }
    }
    events.sort((a, b) => b.start.compareTo(a.start));
    return events;
  }

  //* Toggle: save if not bookmarked, remove if already saved
  static Future<bool> toggleBookmark(Event event) async {
    if (_isBookmarked(event.id)) {
      await removeBookmark(event.id);
      return false;
    } else {
      await addBookmark(event);
      return true;
    }
  }
}
