import 'package:event_radar/core/models/event.dart';
import 'package:event_radar/core/services/bookmark_actions.dart';
import 'package:event_radar/core/services/event_cache_service.dart';
import 'package:event_radar/core/theme/app_colors.dart';
import 'package:event_radar/core/utils/event_time.dart';
import 'package:event_radar/core/utils/html_text.dart';
import 'package:event_radar/core/utils/maps_launcher.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:event_radar/features/event_details/widgets/event_hero.dart';
import 'package:event_radar/features/event_details/widgets/info_row.dart';
import 'package:event_radar/l10n/generated/app_localizations.dart';
import 'package:event_radar/widgets/category_chip.dart';
import 'package:event_radar/widgets/html_text.dart';
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
    final saved = await BookmarkActions.toggle(widget.event, AppL10n.of(context));
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

  Future<void> _openDirections() async {
    final ok = await openDirectionsToEvent(widget.event);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppL10n.of(context).couldNotOpenMaps)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final primary = Theme.of(context).colorScheme.primary;
    final l = AppL10n.of(context);
    final cat = event.category;
    final isPast = !event.isUpcoming;
    final hasVenueTzDifference = venueTzDiffersFromPhone(event.timezone);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.bg,
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
                  color: _isSaved ? primary : AppColors.textSecondary,
                ),
                onPressed: _toggleSave,
              ),
            ],
            expandedHeight: 220,
            flexibleSpace: FlexibleSpaceBar(
              background: EventHero(category: cat, isPast: isPast),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CategoryChip(category: cat, large: true),
                  const SizedBox(height: 14),
                  HtmlText(
                    event.title,
                    style: GoogleFonts.syne(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 20),
                  InfoRow(
                    icon: Icons.calendar_today_rounded,
                    label: l.dateLabel,
                    value: _formatDate(event, context),
                  ),
                  InfoRow(
                    icon: Icons.schedule_rounded,
                    label: l.timeLabel,
                    value: hasVenueTzDifference
                        ? '${_formatTimeVenue(event)}  ·  ${l.timeSuffix(venueTzShortName(event.timezone))}'
                        : _formatTimeVenue(event),
                    subValue: hasVenueTzDifference
                        ? '${_formatTimePhone(event, context)}  ·  ${l.timeSuffix(phoneTzShortName() ?? l.timeYour)}'
                        : null,
                  ),
                  if (event.venue != null)
                    InfoRow(
                      icon: Icons.location_on_rounded,
                      label: l.venueLabel,
                      value: event.venue!,
                      subValue: event.city,
                    ),
                  InfoRow(
                    icon: Icons.sell_rounded,
                    label: l.priceLabel,
                    value: event.isFree
                        ? l.free
                        : (event.hasPrice ? event.price! : l.unknown),
                    highlight: event.isFree,
                  ),
                  if (event.description != null &&
                      event.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Text(
                      l.aboutSection,
                      style: GoogleFonts.syne(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Html(
                      data: unescapeHtmlIfNeeded(event.description!),
                      // Style only the body so the package's per-tag defaults
                      // (b → bold, i → italic, etc.) keep working; padding +
                      // margins zeroed so it sits flush with the section head.
                      style: {
                        'body': Style(
                          margin: Margins.zero,
                          padding: HtmlPaddings.zero,
                          fontSize: FontSize(14),
                          lineHeight: const LineHeight(1.5),
                          color: AppColors.textBodyAlt,
                        ),
                        'a': Style(color: primary),
                      },
                    ),
                  ],
                  if (event.hasLocation) ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _openDirections,
                        icon: const Icon(Icons.directions_rounded, size: 18),
                        label: Text(l.directions),
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
                  ],
                  if (event.url != null) ...[
                    SizedBox(height: event.hasLocation ? 10 : 24),
                    SizedBox(
                      width: double.infinity,
                      // Demote to outlined when Directions is the primary CTA;
                      // otherwise keep the filled emphasis the page used to have.
                      child: event.hasLocation
                          ? OutlinedButton.icon(
                              onPressed: () => _openUrl(event.url),
                              icon: const Icon(Icons.open_in_new_rounded, size: 18),
                              label: Text(l.viewPage),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: primary,
                                side: BorderSide(
                                  color: primary.withValues(alpha: 0.5),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            )
                          : FilledButton.icon(
                              onPressed: () => _openUrl(event.url),
                              icon: const Icon(Icons.open_in_new_rounded, size: 18),
                              label: Text(l.viewPage),
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
                          l.viaSource(Uri.tryParse(event.source!)?.host ?? event.source!),
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textHint,
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

  String _formatDate(Event event, BuildContext context) {
    const pattern = 'EEE, MMM d, yyyy';
    final start = eventWallClock(event);
    if (event.end == null) return formatEventTime(event, pattern);
    final end = eventWallClock(event, when: event.end);
    if (DateUtils.isSameDay(start, end)) return formatEventTime(event, pattern);
    return '${formatEventTime(event, pattern)}  →  ${formatEventTime(event, pattern, when: event.end)}';
  }

  String _formatTimeVenue(Event event) {
    final startStr = formatEventTime(event, 'HH:mm');
    if (event.end == null) return startStr;
    final start = eventWallClock(event);
    final end = eventWallClock(event, when: event.end);
    if (DateUtils.isSameDay(start, end)) {
      return '$startStr – ${formatEventTime(event, 'HH:mm', when: event.end)}';
    }
    return startStr;
  }

  String _formatTimePhone(Event event, BuildContext context) {
    // Same shape as _formatTimeVenue but always in the phone's tz. Adds the
    // date prefix when the venue day and phone day disagree (e.g. a Wrocław
    // 22:30 lands the next morning in Tokyo).
    const fmt = 'HH:mm';
    const fmtWithDate = 'd MMM, HH:mm';
    final locale = Localizations.localeOf(context).toLanguageTag();
    final startLocal = event.start.toLocal();
    final venueStart = eventWallClock(event);
    final crossesDay = !DateUtils.isSameDay(startLocal, venueStart);
    final startPattern = crossesDay ? fmtWithDate : fmt;
    final startStr = DateFormat(startPattern, locale).format(startLocal);
    if (event.end == null) return startStr;
    final endLocal = event.end!.toLocal();
    if (DateUtils.isSameDay(startLocal, endLocal)) {
      return '$startStr – ${DateFormat(fmt, locale).format(endLocal)}';
    }
    return startStr;
  }
}
