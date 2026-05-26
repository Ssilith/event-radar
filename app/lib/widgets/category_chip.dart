import 'package:event_radar/core/models/event_category.dart';
import 'package:event_radar/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

// Tinted pill showing an EventCategory's icon + label, color-keyed by category.
class CategoryChip extends StatelessWidget {
  final EventCategory category;
  // Slightly bigger variant used on the event details hero.
  final bool large;

  const CategoryChip({super.key, required this.category, this.large = false});

  @override
  Widget build(BuildContext context) {
    final color = category.color;
    final hPad = large ? 10.0 : 9.0;
    final vPad = large ? 5.0 : 4.0;
    final iconSize = large ? 12.0 : 11.0;
    final gap = large ? 5.0 : 4.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(category.iconData, size: iconSize, color: color),
          SizedBox(width: gap),
          Text(
            category.label(AppL10n.of(context)),
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
