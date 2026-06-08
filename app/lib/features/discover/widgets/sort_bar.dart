import 'package:event_radar/core/theme/app_colors.dart';
import 'package:event_radar/core/theme/app_shadows.dart';
import 'package:event_radar/core/utils/event_sort.dart';
import 'package:event_radar/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

//* Full-width Date/Nearby sort toggle (icon + label; Nearby disabled without GPS)
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Container(
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
            final fg = selected
                ? AppColors.onPrimary
                : enabled
                ? AppColors.textBody
                : AppColors.textFaint;
            return Expanded(
              child: GestureDetector(
                onTap: enabled ? () => onChanged(s) : null,
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: selected ? primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(21),
                    boxShadow: selected ? AppShadows.subtle : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 14, color: fg),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          s.label(l),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: fg,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
