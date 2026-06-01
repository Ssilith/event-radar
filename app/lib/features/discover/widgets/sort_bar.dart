import 'package:event_radar/core/theme/app_colors.dart';
import 'package:event_radar/core/theme/app_shadows.dart';
import 'package:event_radar/core/utils/event_sort.dart';
import 'package:event_radar/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

class SortBar extends StatelessWidget {
  final EventSort sort;
  final bool nearbyAvailable;
  final ValueChanged<EventSort> onChanged;

  const SortBar({
    super.key,
    required this.sort,
    required this.nearbyAvailable,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    // Nearby chip is shown but disabled when the user's GPS fix isn't known —
    // makes the option discoverable so the user knows enabling location will
    // unlock it, instead of hiding the chip silently.
    // Segmented-control style — single rounded shell with one filled segment
    // at a time. Reads as "which lens am I looking through" instead of two
    // independent toggles.
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Row(
        children: [
          Icon(Icons.sort_rounded, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Text(
            l.sortByLabel,
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 0.4,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.surfacePill),
            ),
            child: Row(
              children: EventSort.values.map((s) {
                final enabled = s == EventSort.date || nearbyAvailable;
                final selected = sort == s;
                final icon = s == EventSort.date
                    ? Icons.event_rounded
                    : Icons.near_me_rounded;
                return GestureDetector(
                  onTap: enabled ? () => onChanged(s) : null,
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: selected ? AppShadows.subtle : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 13,
                          color: selected
                              ? Colors.black
                              : enabled
                                  ? AppColors.textBody
                                  : AppColors.textFaint,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          s.label(l),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected
                                ? Colors.black
                                : enabled
                                    ? AppColors.textBody
                                    : AppColors.textFaint,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
