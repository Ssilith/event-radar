import 'package:event_radar/core/theme/app_colors.dart';
import 'package:event_radar/l10n/generated/app_localizations.dart';
import 'package:event_radar/widgets/loading.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

//* Centred placeholder for loading / empty / error-retry states
class StatusView extends StatelessWidget {
  final IconData? icon;
  final String? message;
  //* Optional muted subtitle under the title (empty-bookmarks style)
  final String? body;
  final bool showSpinner;
  final VoidCallback? onRetry;
  final String? retryLabel;

  const StatusView({
    super.key,
    this.icon,
    this.message,
    this.body,
    this.showSpinner = false,
    this.onRetry,
    this.retryLabel,
  });

  //* Loading state (optional subtitle for longer explanations)
  const StatusView.loading({super.key, required this.message, this.body})
    : icon = null,
      showSpinner = true,
      onRetry = null,
      retryLabel = null;

  //* Empty result (optional message overrides the default statusEmpty)
  const StatusView.empty({super.key, this.message, this.body})
    : icon = Icons.search_off,
      showSpinner = false,
      onRetry = null,
      retryLabel = null;

  //* Error / timeout
  const StatusView.withRetry({
    super.key,
    required this.icon,
    required this.message,
    required this.onRetry,
    this.retryLabel,
  }) : body = null,
       showSpinner = false;

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            //* Same hero look as the empty-bookmarks page: ripple while loading,
            //* else a large primary-tinted icon
            if (showSpinner)
              const Loading()
            else if (icon != null)
              Icon(icon, size: 56, color: primary.withValues(alpha: 0.4)),
            const SizedBox(height: 20),
            Text(
              message ?? l.statusEmpty,
              textAlign: TextAlign.center,
              style: GoogleFonts.syne(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            if (body != null) ...[
              const SizedBox(height: 8),
              Text(
                body!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPlaceholder,
                  fontSize: 13,
                ),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: onRetry,
                child: Text(retryLabel ?? l.retry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
