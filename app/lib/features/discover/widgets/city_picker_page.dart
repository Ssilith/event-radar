import 'package:event_radar/core/models/city_item.dart';
import 'package:event_radar/core/theme/app_colors.dart';
import 'package:event_radar/l10n/generated/app_localizations.dart';
import 'package:event_radar/features/discover/widgets/city_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CityPickerPage extends StatelessWidget {
  final CityItem? initialValue;
  final ValueChanged<CityItem> onCitySelected;

  const CityPickerPage({
    super.key,
    required this.initialValue,
    required this.onCitySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          AppL10n.of(context).chooseCityTitle,
          style: GoogleFonts.syne(fontWeight: FontWeight.w700),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.surfaceElevated, height: 1),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: CityPicker(
          initialValue: initialValue,
          onCitySelected: onCitySelected,
        ),
      ),
    );
  }
}
