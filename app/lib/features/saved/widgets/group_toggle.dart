import 'package:event_radar/core/theme/app_colors.dart';
import 'package:event_radar/core/theme/app_shadows.dart';
import 'package:event_radar/features/saved/models/group_mode.dart';
import 'package:event_radar/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

//* Segmented toggle between grouping bookmarks by location vs date
class GroupToggle extends StatelessWidget {
  final GroupMode mode;
  final ValueChanged<GroupMode> onChanged;
  const GroupToggle({super.key, required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final l = AppL10n.of(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.surfacePill),
      ),
      child: Row(
        children: [
          _toggleButton(
            label: l.byLocation,
            icon: Icons.location_city_rounded,
            selected: mode == GroupMode.location,
            primary: primary,
            onTap: () => onChanged(GroupMode.location),
          ),
          _toggleButton(
            label: l.byDate,
            icon: Icons.calendar_today_rounded,
            selected: mode == GroupMode.date,
            primary: primary,
            onTap: () => onChanged(GroupMode.date),
          ),
        ],
      ),
    );
  }

  //* One segment of the toggle
  Widget _toggleButton({
    required String label,
    required IconData icon,
    required bool selected,
    required Color primary,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: selected ? AppShadows.subtle : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: selected ? AppColors.onPrimary : AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AppColors.onPrimary : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
