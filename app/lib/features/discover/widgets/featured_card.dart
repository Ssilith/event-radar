import 'package:event_radar/core/models/event.dart';
import 'package:event_radar/core/models/event_category.dart';
import 'package:event_radar/core/theme/app_colors.dart';
import 'package:event_radar/core/theme/app_shadows.dart';
import 'package:event_radar/core/utils/event_time.dart';
import 'package:event_radar/l10n/generated/app_localizations.dart';
import 'package:event_radar/widgets/category_chip.dart';
import 'package:event_radar/widgets/html_text.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FeaturedCard extends StatelessWidget {
  final Event event;
  final bool isSaved;
  final VoidCallback onToggleSave;
  final VoidCallback onOpenDetails;

  const FeaturedCard({
    super.key,
    required this.event,
    required this.isSaved,
    required this.onToggleSave,
    required this.onOpenDetails,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final l = AppL10n.of(context);
    final isPast = !event.isUpcoming;
    final catColor = event.category.color;
    final durationLabels = DurationLabels(allDay: l.allDay);

    return GestureDetector(
      onTap: onOpenDetails,
      child: Container(
        width: 295,
        margin: const EdgeInsets.only(right: 14, bottom: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              catColor.withValues(alpha: 0.3),
              catColor.withValues(alpha: 0.08),
              AppColors.surfaceLow,
            ],
            stops: const [0.0, 0.45, 1.0],
          ),
          border: Border.all(color: catColor.withValues(alpha: 0.28)),
          boxShadow: AppShadows.card,
        ),
        child: Stack(
          children: [
            // Subtle tinted corner glow.
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: catColor.withValues(alpha: 0.07),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CategoryChip(category: event.category),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onToggleSave,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              isSaved
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_outline_rounded,
                              key: ValueKey(isSaved),
                              size: 20,
                              color: isSaved ? primary : AppColors.textHint,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isPast
                              ? Colors.red.withValues(alpha: 0.18)
                              : primary.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isPast ? l.past : l.upcoming,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: isPast ? Colors.red.shade300 : primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        eventDurationLabel(event, labels: durationLabels) ?? '',
                        style: GoogleFonts.syne(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  HtmlText(
                    event.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  if (event.venue != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 11,
                          color: catColor,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            event.venue!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textPlaceholder,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (event.isFree || event.hasPrice)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.isFree ? l.free : event.price!,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: event.isFree
                                    ? primary
                                    : AppColors.textPrimary,
                              ),
                            ),
                            if (event.source != null)
                              Text(
                                l.viaSource(Uri.tryParse(event.source ?? '')?.host ?? event.source ?? ''),
                                style: TextStyle(
                                  fontSize: 9,
                                  color: AppColors.textDisabled,
                                ),
                              ),
                          ],
                        )
                      else
                        const SizedBox.shrink(),
                      if (event.url != null)
                        GestureDetector(
                          onTap: onOpenDetails,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: primary.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(
                                color: primary.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  l.details,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: primary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 12,
                                  color: primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
