import 'package:event_radar/core/models/event_category.dart';
import 'package:event_radar/core/theme/app_colors.dart';
import 'package:event_radar/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

class CategoryBar extends StatelessWidget {
  final EventCategory? selected;
  final List<EventCategory> available;
  final ValueChanged<EventCategory?> onChanged;

  const CategoryBar({
    super.key,
    required this.selected,
    required this.available,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l = AppL10n.of(context);
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [null, ...available].map((cat) {
          final sel = selected == cat;
          final color = cat?.color ?? scheme.primary;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              avatar: Icon(
                cat?.iconData ?? Icons.apps_rounded,
                size: 15,
                color: sel ? Colors.black : color,
              ),
              label: Text(cat?.label(l) ?? l.categoryAll),
              selected: sel,
              onSelected: (_) => onChanged(sel ? null : cat),
              showCheckmark: false,
              selectedColor: color,
              backgroundColor: AppColors.border,
              side: BorderSide(
                color: sel ? color : AppColors.borderStrong,
              ),
              labelStyle: TextStyle(
                fontSize: 12,
                color: sel ? Colors.black : AppColors.textBody,
                fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          );
        }).toList(),
      ),
    );
  }
}
