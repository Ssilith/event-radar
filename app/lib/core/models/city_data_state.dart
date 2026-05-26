import 'package:event_radar/core/models/event.dart';

enum CityDataStatus {
  // Data was served from cache or a fresh remote dataset — no scrape needed.
  fresh,
  // A scrape has been requested and is starting up.
  triggered,
  // Still waiting for the scrape to produce results.
  polling,
  // Scrape completed and fresh events are available.
  ready,
  // Scrape did not complete within the allowed window.
  timeout,
  // Something went wrong and the flow cannot continue.
  error,
}

// Carries the data-fetching state for a city. We deliberately don't embed
// user-visible English strings here; presentation layers translate the status
// into a localized message via AppL10n.
class CityDataState {
  final CityDataStatus status;
  final List<Event> events;

  const CityDataState(this.status, {this.events = const []});

  const CityDataState.triggered() : this(CityDataStatus.triggered);
  const CityDataState.polling() : this(CityDataStatus.polling);
  const CityDataState.error() : this(CityDataStatus.error);
  const CityDataState.timeout() : this(CityDataStatus.timeout);
}
