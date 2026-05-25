import 'package:event_radar/models/event.dart';
import 'package:event_radar/models/event_category.dart';
import 'package:event_radar/services/event_cache_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class EventDetailsScreen extends StatefulWidget {
  final Event event;
  const EventDetailsScreen({super.key, required this.event});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  late bool _isSaved;

  @override
  void initState() {
    super.initState();
    _isSaved = EventCacheService.bookmarkedIds().contains(widget.event.id);
  }

  Future<void> _toggleSave() async {
    final saved = await EventCacheService.toggleBookmark(widget.event);
    if (!mounted) return;
    setState(() => _isSaved = saved);
  }

  Future<void> _openUrl(String? url) async {
    if (url == null) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    }
  }

  EventCategory get _resolvedCategory => EventCategory.values.firstWhere(
    (c) =>
        c.value.toLowerCase() == widget.event.category.value.toLowerCase(),
    orElse: () => EventCategory.other,
  );

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final primary = Theme.of(context).colorScheme.primary;
    final cat = _resolvedCategory;
    final isPast = !event.isUpcoming;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: const Color(0xFF0A0A0A),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isSaved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_outline_rounded,
                  color: _isSaved ? primary : Colors.white70,
                ),
                onPressed: _toggleSave,
              ),
            ],
            expandedHeight: 220,
            flexibleSpace: FlexibleSpaceBar(
              background: _Hero(category: cat, isPast: isPast),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CategoryChip(category: cat),
                  const SizedBox(height: 14),
                  Text(
                    event.title,
                    style: GoogleFonts.syne(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _InfoRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Date',
                    value: _formatDate(event.start, event.end),
                  ),
                  _InfoRow(
                    icon: Icons.schedule_rounded,
                    label: 'Time',
                    value: _formatTime(event.start, event.end),
                  ),
                  if (event.venue != null)
                    _InfoRow(
                      icon: Icons.location_on_rounded,
                      label: 'Venue',
                      value: event.venue!,
                      subValue: event.city,
                    ),
                  _InfoRow(
                    icon: Icons.sell_rounded,
                    label: 'Price',
                    value: event.isFree
                        ? 'Free'
                        : (event.hasPrice ? event.price! : 'Unknown'),
                    highlight: event.isFree,
                  ),
                  if (event.description != null &&
                      event.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Text(
                      'About',
                      style: GoogleFonts.syne(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      event.description!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFFBFBFBF),
                        height: 1.5,
                      ),
                    ),
                  ],
                  if (event.url != null) ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _openUrl(event.url),
                        icon: const Icon(Icons.open_in_new_rounded, size: 18),
                        label: const Text('View page'),
                        style: FilledButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    if (event.source != null) ...[
                      const SizedBox(height: 10),
                      Center(
                        child: Text(
                          'via ${Uri.tryParse(event.source!)?.host ?? event.source}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime start, DateTime? end) {
    final fmt = DateFormat('EEE, MMM d, yyyy');
    if (end == null || DateUtils.isSameDay(start, end)) return fmt.format(start);
    return '${fmt.format(start)}  →  ${fmt.format(end)}';
  }

  String _formatTime(DateTime start, DateTime? end) {
    if (end == null) return DateFormat('HH:mm').format(start);
    if (DateUtils.isSameDay(start, end)) {
      return '${DateFormat('HH:mm').format(start)} – ${DateFormat('HH:mm').format(end)}';
    }
    return DateFormat('HH:mm').format(start);
  }
}

class _Hero extends StatelessWidget {
  final EventCategory category;
  final bool isPast;
  const _Hero({required this.category, required this.isPast});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            category.color.withValues(alpha: 0.45),
            category.color.withValues(alpha: 0.15),
            const Color(0xFF0A0A0A),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: category.color.withValues(alpha: 0.10),
              ),
            ),
          ),
          Center(
            child: Icon(
              category.iconData,
              size: 88,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isPast
                    ? Colors.red.withValues(alpha: 0.2)
                    : primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isPast ? 'PAST' : 'UPCOMING',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                  color: isPast ? Colors.red.shade300 : primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final EventCategory category;
  const _CategoryChip({required this.category});

  @override
  Widget build(BuildContext context) {
    final color = category.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(category.iconData, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            category.value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subValue;
  final bool highlight;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.subValue,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF161616),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF222222)),
            ),
            child: Icon(icon, size: 16, color: primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.4,
                    color: Color(0xFF666666),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: highlight ? primary : Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subValue != null && subValue!.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subValue!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF888888),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
