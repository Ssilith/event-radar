import 'package:event_radar/core/theme/app_colors.dart';
import 'package:event_radar/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

class DiscoverSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const DiscoverSearchField({
    super.key,
    required this.controller,
    required this.query,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
        decoration: InputDecoration(
          isDense: true,
          hintText: l.searchHint,
          hintStyle: TextStyle(color: AppColors.textHint, fontSize: 14),
          prefixIcon: Icon(Icons.search, size: 18, color: AppColors.textHint),
          suffixIcon: query.isEmpty
              ? null
              : IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.textHint,
                  ),
                  onPressed: onClear,
                ),
          filled: true,
          fillColor: AppColors.surfaceHigh,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.borderStrong),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}
