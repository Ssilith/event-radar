import 'package:event_radar/core/theme/app_colors.dart';
import 'package:event_radar/core/theme/app_shadows.dart';
import 'package:event_radar/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

class DiscoverStatsCard extends StatelessWidget {
  final bool isPolling;
  final int eventCount;

  const DiscoverStatsCard({
    super.key,
    required this.isPolling,
    required this.eventCount,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final l = AppL10n.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primary.withValues(alpha: 0.22)),
        boxShadow: AppShadows.subtle,
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome_rounded, size: 15, color: primary),
          const SizedBox(width: 10),
          Expanded(
            child: isPolling
                ? Text(
                    l.discoveringEventsLoading,
                    style: TextStyle(fontSize: 13, color: primary),
                  )
                : RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                      children: [
                        TextSpan(
                          text: l.eventsAutoDiscoveredFrom(eventCount),
                          style: TextStyle(
                            color: primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const TextSpan(text: ' '),
                        TextSpan(
                          text: l.schemaOrg,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          if (isPolling)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: primary),
            ),
        ],
      ),
    );
  }
}
