import 'package:event_radar/core/models/distance_unit.dart';
import 'package:event_radar/core/models/event.dart';
import 'package:event_radar/core/services/bookmark_actions.dart';
import 'package:event_radar/core/services/city_service.dart';
import 'package:event_radar/core/services/event_cache_service.dart';
import 'package:event_radar/core/services/settings_service.dart';
import 'package:event_radar/core/theme/app_colors.dart';
import 'package:event_radar/core/utils/event_time.dart';
import 'package:event_radar/core/utils/html_parsing.dart';
import 'package:event_radar/core/utils/maps_launcher.dart';
import 'package:event_radar/features/event_details/widgets/event_hero.dart';
import 'package:event_radar/features/event_details/widgets/info_row.dart';
import 'package:event_radar/l10n/generated/app_localizations.dart';
import 'package:event_radar/widgets/category_chip.dart';
import 'package:event_radar/widgets/html_text.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

//* Full event details: hero, info rows, description, save + links
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

  //* Save/unsave this event
  Future<void> _toggleSave() async {
    final saved = await BookmarkActions.toggle(widget.event, AppL10n.of(context));
    if (!mounted) return;
    setState(() => _isSaved = saved);
  }

  //* Open the event's ticket/source URL in an in-app browser
  Future<void> _openUrl(String? url) async {
    if (url == null) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    }
  }

  //* Open external directions to the venue
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
    final hasVenueTzDifference = venueTzDiffersFromPhone(event.timezone);
    //* Past events show the date in red to reinforce the hero's "past" badge
    final dateColor = event.isPast ? Colors.red.shade400 : null;

    //* Shared CTA styles + builders (so each button can be filled or outlined)
    final filledStyle = FilledButton.styleFrom(
      backgroundColor: primary,
      foregroundColor: AppColors.onPrimary,
      padding: const EdgeInsets.symmetric(vertical: 14),
      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
    );
    final outlinedStyle = OutlinedButton.styleFrom(
      foregroundColor: primary,
      side: BorderSide(color: primary.withValues(alpha: 0.5)),
      padding: const EdgeInsets.symmetric(vertical: 14),
      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
    );
    Widget directionsButton({required bool filled}) {
      const icon = Icon(Icons.directions_rounded, size: 18);
      final label = Text(l.directions);
      return filled
          ? FilledButton.icon(
              onPressed: _openDirections,
              icon: icon,
              label: label,
              style: filledStyle,
            )
          : OutlinedButton.icon(
              onPressed: _openDirections,
              icon: icon,
              label: label,
              style: outlinedStyle,
            );
    }

    Widget viewPageButton({required bool filled}) {
      const icon = Icon(Icons.open_in_new_rounded, size: 18);
      final label = Text(l.viewPage);
      return filled
          ? FilledButton.icon(
              onPressed: () => _openUrl(event.url),
              icon: icon,
              label: label,
              style: filledStyle,
            )
          : OutlinedButton.icon(
              onPressed: () => _openUrl(event.url),
              icon: icon,
              label: label,
              style: outlinedStyle,
            );
    }
    //* Distance from the user's last GPS fix, formatted in their chosen unit
    //* (only when both a position and event coordinates are available)
    final userPos = CityService.instance.lastPosition;
    final distanceKm = userPos == null
        ? null
        : event.distanceTo(userPos.latitude, userPos.longitude);
    final distanceLabel = distanceKm == null
        ? null
        : SettingsService.instance.distanceUnit.value.format(distanceKm);

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
              background: EventHero(category: cat, status: event.status),
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
                    valueWidget: _dateValueWidget(event, context, dateColor),
                    valueColor: dateColor,
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
                      subValue: CityService.instance.displayCityName(event.city),
                    ),
                  if (distanceLabel != null)
                    InfoRow(
                      icon: Icons.near_me_rounded,
                      label: l.distanceUnitLabel,
                      value: distanceLabel,
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
                      //* Body font (not Syne) so it matches the rest of the text
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _ExpandableDescription(
                      data: unescapeHtmlIfNeeded(event.description!),
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: AppColors.textBodyAlt,
                      ),
                      moreLabel: l.showMore,
                      lessLabel: l.showLess,
                      toggleColor: primary,
                    ),
                  ],
                  if (event.hasLocation || event.url != null) ...[
                    const SizedBox(height: 24),
                    //* Both present → side by side: route (outlined) then open
                    //* page (filled). A lone button spans the full width, filled.
                    if (event.hasLocation && event.url != null)
                      Row(
                        children: [
                          Expanded(child: directionsButton(filled: false)),
                          const SizedBox(width: 10),
                          Expanded(child: viewPageButton(filled: true)),
                        ],
                      )
                    else if (event.hasLocation)
                      SizedBox(
                        width: double.infinity,
                        child: directionsButton(filled: true),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        child: viewPageButton(filled: true),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  //* Uppercase just the first character (keeps the rest as-is, unlike a full
  //* capitalize, so the English date's other words stay intact)
  String _capFirst(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  //* Start (+ end for a genuine multi-day range) formatted with a locale-aware
  //* skeleton so both the names AND the order follow the active language
  ({String start, String? end}) _dateParts(Event event, String locale) {
    final fmt = DateFormat.yMMMEd(locale);
    final s = eventWallClock(event);
    final start = _capFirst(fmt.format(s));
    if (event.end == null) return (start: start, end: null);
    final e = eventWallClock(event, when: event.end);
    if (DateUtils.isSameDay(s, e)) return (start: start, end: null);
    return (start: start, end: _capFirst(fmt.format(e)));
  }

  //* Date line: single day, or "start → end" for multi-day events
  String _formatDate(Event event, BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final parts = _dateParts(event, locale);
    return parts.end == null ? parts.start : '${parts.start}  →  ${parts.end}';
  }

  //* Multi-day date range with the arrow as an inline, vertically-centered
  //* icon (the "→" glyph rides too high against the text); null for single day
  Widget? _dateValueWidget(Event event, BuildContext context, Color? color) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final parts = _dateParts(event, locale);
    if (parts.end == null) return null;
    return Text.rich(
      TextSpan(
        style: TextStyle(
          fontSize: 14,
          color: color ?? AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        children: [
          TextSpan(text: parts.start),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Icon(
                Icons.arrow_forward_rounded,
                size: 14,
                color: color ?? AppColors.textPlaceholder,
              ),
            ),
          ),
          TextSpan(text: parts.end),
        ],
      ),
    );
  }

  //* Time range in the venue's tz (start–end same day, else just start)
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

  //* Time range in the phone's tz, with a date prefix when the day differs
  String _formatTimePhone(Event event, BuildContext context) {
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

//* Justified HTML description, clamped to [_collapsedLines] with a show
//* more/less toggle that only appears when the text actually overflows
class _ExpandableDescription extends StatefulWidget {
  final String data;
  final TextStyle style;
  final String moreLabel;
  final String lessLabel;
  final Color toggleColor;

  const _ExpandableDescription({
    required this.data,
    required this.style,
    required this.moreLabel,
    required this.lessLabel,
    required this.toggleColor,
  });

  @override
  State<_ExpandableDescription> createState() => _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<_ExpandableDescription> {
  static const _collapsedLines = 4;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final span = htmlToSpan(widget.data, baseStyle: widget.style);
    return LayoutBuilder(
      builder: (context, constraints) {
        //* Measure whether the text would exceed the collapsed line count
        final painter = TextPainter(
          text: span,
          maxLines: _collapsedLines,
          textAlign: TextAlign.justify,
          textDirection: Directionality.of(context),
        )..layout(maxWidth: constraints.maxWidth);
        final overflows = painter.didExceedMaxLines;

        //* The whole block toggles when it overflows (easier than a small target)
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: overflows
              ? () => setState(() => _expanded = !_expanded)
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HtmlText(
                widget.data,
                style: widget.style,
                textAlign: TextAlign.justify,
                maxLines: _expanded ? null : _collapsedLines,
                overflow: _expanded ? TextOverflow.clip : TextOverflow.ellipsis,
              ),
              if (overflows)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  //* Right-aligned for right-handed thumb reach
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _expanded ? widget.lessLabel : widget.moreLabel,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: widget.toggleColor,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          _expanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: widget.toggleColor,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
