import 'package:event_radar/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:motion_toast/motion_toast.dart';

//* Animated toast
class AppToast {
  AppToast._();

  //* Reminder confirmation: brand accent, bold title + detail line, bell badge
  static void reminder(
    BuildContext context, {
    required String title,
    required String message,
  }) => _show(
    context,
    title: title,
    message: message,
    accent: Theme.of(context).colorScheme.primary,
    icon: Icons.notifications_active_rounded,
  );

  //* Error / failure: red accent, single line
  static void error(BuildContext context, String message) => _show(
    context,
    message: message,
    accent: Colors.red.shade400,
    icon: Icons.error_outline_rounded,
  );

  static void _show(
    BuildContext context, {
    String? title,
    required String message,
    required Color accent,
    required IconData icon,
  }) {
    MotionToast(
      //* The card itself is a plain elevated surface; colour lives in the badge
      primaryColor: AppColors.surface,
      //* Hairline border (stands in for a shadow, which the app omits)
      secondaryColor: AppColors.borderStrong,
      displayBorder: true,
      displaySideBar: false,
      opacity: 1,
      description: _content(
        title: title,
        message: message,
        accent: accent,
        icon: icon,
      ),
      width: 320,
      height: title == null ? 60 : 76,
      borderRadius: 16,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      //* Snappier than the 1.5s default slide
      animationDuration: const Duration(milliseconds: 450),
      //* Sit just above the bottom nav bar. (margin would clip the content.)
      toastAlignment: const Alignment(0, 0.82),
    ).show(context);
  }

  //* The toast's inner layout: accent icon-badge + title/detail text
  static Widget _content({
    String? title,
    required String message,
    required Color accent,
    required IconData icon,
  }) {
    final isSingleLine = title == null;
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: accent.withValues(alpha: 0.4)),
          ),
          child: Icon(icon, color: accent, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null) ...[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
              ],
              Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSingleLine
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontWeight: isSingleLine ? FontWeight.w600 : FontWeight.w500,
                  fontSize: isSingleLine ? 13.5 : 12.5,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
