import 'package:event_radar/core/theme/app_colors.dart';
import 'package:event_radar/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

//* Icon + label + value row (Date/Time/Venue/Price) on the details screen
class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subValue;
  final bool highlight;
  //* Optional custom value widget (e.g. a date range with an inline arrow);
  //* falls back to a plain [value] Text when null
  final Widget? valueWidget;
  //* Optional value colour override (takes precedence over [highlight])
  final Color? valueColor;

  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.subValue,
    this.highlight = false,
    this.valueWidget,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.surfacePill),
            ),
            child: Icon(icon, size: 16, color: primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(), style: AppText.fieldLabel),
                const SizedBox(height: 2),
                valueWidget ??
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            valueColor ??
                            (highlight ? primary : AppColors.textPrimary),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                if (subValue != null && subValue!.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subValue!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textPlaceholder,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
