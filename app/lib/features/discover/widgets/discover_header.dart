import 'package:event_radar/core/models/city_item.dart';
import 'package:event_radar/core/theme/app_colors.dart';
import 'package:event_radar/features/discover/widgets/icon_btn.dart';
import 'package:event_radar/features/discover/widgets/settings_sheet.dart';
import 'package:event_radar/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DiscoverHeader extends StatelessWidget {
  final CityItem? city;
  final bool compact;
  final VoidCallback onTapCity;

  const DiscoverHeader({
    super.key,
    required this.city,
    required this.compact,
    required this.onTapCity,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final l = AppL10n.of(context);
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          compact ? 12 : 20,
          8,
          compact ? 8 : 20,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: onTapCity,
                behavior: HitTestBehavior.opaque,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.discoveringEventsIn,
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 2,
                        color: primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            city?.name ?? l.chooseCity,
                            style: GoogleFonts.syne(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              height: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: primary,
                          size: 22,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            IconBtn(
              icon: Icons.tune_rounded,
              onTap: () => SettingsSheet.show(context),
              tooltip: l.settingsTitle,
            ),
          ],
        ),
      ),
    );
  }
}
