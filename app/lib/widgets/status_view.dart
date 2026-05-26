import 'package:event_radar/l10n/generated/app_localizations.dart';
import 'package:event_radar/widgets/loading.dart';
import 'package:flutter/material.dart';

class StatusView extends StatelessWidget {
  final IconData? icon;
  final String? message;
  final bool showSpinner;
  final VoidCallback? onRetry;
  final String? retryLabel;

  const StatusView({
    super.key,
    this.icon,
    this.message,
    this.showSpinner = false,
    this.onRetry,
    this.retryLabel,
  });

  // Loading state.
  const StatusView.loading({super.key, required this.message})
      : icon = null,
        showSpinner = true,
        onRetry = null,
        retryLabel = null;

  // Empty result. Uses the l10n statusEmpty string at build time.
  const StatusView.empty({super.key})
      : icon = Icons.search_off,
        message = null,
        showSpinner = false,
        onRetry = null,
        retryLabel = null;

  // Error / timeout.
  const StatusView.withRetry({
    super.key,
    required this.icon,
    required this.message,
    required this.onRetry,
    this.retryLabel,
  }) : showSpinner = false;

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showSpinner)
              const Loading()
            else if (icon != null)
              Icon(icon, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              message ?? l.statusEmpty,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
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
