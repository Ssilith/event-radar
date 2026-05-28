import 'package:event_radar/core/theme/app_colors.dart';
import 'package:event_radar/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

class EventsChip extends StatelessWidget {
  final int total;
  final int todayCount;
  final VoidCallback onTap;
  const EventsChip({
    super.key,
    required this.total,
    required this.todayCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final l = AppL10n.of(context);
    return Material(
      color: AppColors.surfaceHigh,
      borderRadius: BorderRadius.circular(24),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_note_rounded, size: 16, color: primary),
              const SizedBox(width: 8),
              Text(
                l.eventCount(total),
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (todayCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    l.todayCount(todayCount),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
