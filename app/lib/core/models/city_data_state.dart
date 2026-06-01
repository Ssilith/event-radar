import 'package:event_radar/core/models/event.dart';

enum CityDataStatus {
  //* Data was served from cache or a fresh remote dataset - no scrape needed
  fresh,
  //* A scrape has been requested and is starting up
  triggered,
  //* Still waiting for the scrape to produce results
  polling,
  //* Scrape completed and fresh events are available
  ready,
  //* Scrape did not complete within the allowed window
  timeout,
  //* Something went wrong and the flow cannot continue
  error,
}

//* Data-fetch state for a city; status is localized by the UI, not here
class CityDataState {
  final CityDataStatus status;
  final List<Event> events;

  const CityDataState(this.status, {this.events = const []});

  //* Event-less status shortcuts (fresh/ready always carry events instead)
  const CityDataState.triggered() : this(CityDataStatus.triggered);
  const CityDataState.polling() : this(CityDataStatus.polling);
  const CityDataState.error() : this(CityDataStatus.error);
  const CityDataState.timeout() : this(CityDataStatus.timeout);
}
