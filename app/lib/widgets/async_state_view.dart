import 'package:event_radar/core/models/city_data_state.dart';
import 'package:event_radar/l10n/generated/app_localizations.dart';
import 'package:event_radar/widgets/status_view.dart';
import 'package:flutter/material.dart';

class AsyncStateView extends StatelessWidget {
  final CityDataState state;
  final VoidCallback? onRetry;
  const AsyncStateView({super.key, required this.state, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return switch (state.status) {
      CityDataStatus.error => StatusView.withRetry(
        icon: Icons.error_outline,
        message: l.scrapeErrorMessage,
        onRetry: onRetry ?? () {},
        retryLabel: l.retry,
      ),
      CityDataStatus.timeout => StatusView.withRetry(
        icon: Icons.timer_off,
        message: l.scrapeTimeoutMessage,
        onRetry: onRetry ?? () {},
        retryLabel: l.retry,
      ),
      CityDataStatus.triggered => StatusView.loading(
        message: l.scrapeStartedTitle,
        body: l.scrapeStartedMessage,
      ),
      CityDataStatus.polling => StatusView.loading(
        message: l.scrapePollingMessage,
      ),
      _ => StatusView.loading(message: l.statusLoading),
    };
  }
}
