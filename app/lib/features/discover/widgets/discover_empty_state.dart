import 'package:event_radar/core/theme/app_colors.dart';
import 'package:event_radar/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';

class DiscoverEmptyState extends StatelessWidget {
  final bool cityLoading;
  final VoidCallback onPickCity;

  const DiscoverEmptyState({
    super.key,
    required this.cityLoading,
    required this.onPickCity,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final l = AppL10n.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_city_outlined,
            size: 56,
            color: primary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 20),
          Text(
            l.chooseCityToDiscoverEvents,
            textAlign: TextAlign.center,
            style: GoogleFonts.syne(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 28),
          if (cityLoading)
            SpinKitRipple(color: primary, size: 36)
          else
            FilledButton.icon(
              onPressed: onPickCity,
              icon: const Icon(Icons.search, size: 18),
              label: Text(l.pickACity),
              style: FilledButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
