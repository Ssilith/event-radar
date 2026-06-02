import 'package:event_radar/core/theme/app_colors.dart';
import 'package:event_radar/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

//* Map placeholder shown when no city is selected
class MapEmptyState extends StatelessWidget {
  const MapEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.map_outlined,
                size: 56,
                color: primary.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 20),
              Text(
                l.mapNoCitySelected,
                textAlign: TextAlign.center,
                style: GoogleFonts.syne(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
