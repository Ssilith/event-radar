import 'package:event_radar/core/models/event.dart';
import 'package:event_radar/core/theme/app_colors.dart';
import 'package:event_radar/features/saved/models/group.dart';
import 'package:event_radar/features/saved/widgets/saved_event_row.dart';
import 'package:event_radar/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GroupSection extends StatelessWidget {
  final Group group;
  final Future<void> Function(Event) onRemove;
  const GroupSection({super.key, required this.group, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              if (group.emphasis)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    AppL10n.of(context).groupCurrent,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              Expanded(
                child: Text(
                  group.label,
                  style: GoogleFonts.syne(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: group.emphasis ? primary : AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${group.events.length}',
                style: TextStyle(color: primary, fontSize: 12),
              ),
            ],
          ),
        ),
        ...group.events.map(
          (e) => SavedEventRow(event: e, onRemove: () => onRemove(e)),
        ),
      ],
    );
  }
}
