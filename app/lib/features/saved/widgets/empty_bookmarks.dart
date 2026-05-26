import 'package:event_radar/core/theme/app_colors.dart';
import 'package:event_radar/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EmptyBookmarks extends StatelessWidget {
  const EmptyBookmarks({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bookmark_outline_rounded,
              size: 56,
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.4),
            ),
            const SizedBox(height: 20),
            Text(
              l.noSavedEvents,
              textAlign: TextAlign.center,
              style: GoogleFonts.syne(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l.noSavedEventsBody,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textPlaceholder, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
