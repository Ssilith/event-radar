import 'package:event_radar/core/theme/app_colors.dart';
import 'package:event_radar/core/theme/app_shadows.dart';
import 'package:event_radar/core/utils/date_filter.dart';
import 'package:event_radar/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

class DateFilterBar extends StatelessWidget {
  final DateFilter filter;
  final bool freeOnly;
  final ValueChanged<DateFilter> onFilterChanged;
  final ValueChanged<bool> onFreeOnlyChanged;

  const DateFilterBar({
    super.key,
    required this.filter,
    required this.freeOnly,
    required this.onFilterChanged,
    required this.onFreeOnlyChanged,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final l = AppL10n.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
      child: Row(
        children: [
          ...DateFilter.values.map((f) {
            final sel = filter == f;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onFilterChanged(f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: sel ? primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: sel ? primary : AppColors.borderStrong,
                    ),
                    boxShadow: sel ? AppShadows.subtle : null,
                  ),
                  child: Text(
                    f.label(l),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                      color: sel ? Colors.black : AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            );
          }),
          // Separator + Free-only toggle. Lives in the same scroll row so
          // mobile users don't get another vertical band of chips.
          Container(
            width: 1,
            height: 18,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            color: AppColors.borderStrong,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: GestureDetector(
              onTap: () => onFreeOnlyChanged(!freeOnly),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: freeOnly ? primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: freeOnly ? primary : AppColors.borderStrong,
                  ),
                  boxShadow: freeOnly ? AppShadows.subtle : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.savings_rounded,
                      size: 14,
                      color: freeOnly ? Colors.black : AppColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l.filterFreeOnly,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            freeOnly ? FontWeight.w700 : FontWeight.w400,
                        color: freeOnly ? Colors.black : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
