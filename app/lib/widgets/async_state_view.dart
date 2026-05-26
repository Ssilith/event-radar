import 'package:event_radar/core/models/city_data_state.dart';
import 'package:event_radar/l10n/generated/app_localizations.dart';
import 'package:event_radar/widgets/status_view.dart';
import 'package:flutter/material.dart';

// Maps a CityDataState to the right placeholder widget (loading / empty /
// error / timeout) when no data is available yet. Use this so each screen
// stops re-writing the same `switch (state.status) { ... }` block.
class AsyncStateView extends StatelessWidget {
  final CityDataState state;
  final WidgetBuilder dataBuilder;
  final VoidCallback? onRetry;

  const AsyncStateView({
    super.key,
    required this.state,
    required this.dataBuilder,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = state.status == CityDataStatus.fresh ||
        state.status == CityDataStatus.ready;
    if (hasData) return dataBuilder(context);

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
      CityDataStatus.triggered =>
        StatusView.loading(message: l.scrapeStartedMessage),
      CityDataStatus.polling =>
        StatusView.loading(message: l.scrapePollingMessage),
      _ => StatusView.loading(message: l.statusLoading),
    };
  }
}
