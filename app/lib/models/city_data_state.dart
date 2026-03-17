import 'package:event_radar/models/event.dart';

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

class CityDataState {
  final CityDataStatus status;
  final List<Event> events;
  final String? message;

  const CityDataState(this.status, {this.events = const [], this.message});

  const CityDataState.triggered()
    : this(
        CityDataStatus.triggered,
        message:
            'Discovering events - usually takes about 2 minutes the first time.',
      );

  const CityDataState.polling()
    : this(CityDataStatus.polling, message: 'Still discovering events…');

  const CityDataState.error()
    : this(
        CityDataStatus.error,
        message: 'Could not start event discovery. Try again later.',
      );

  const CityDataState.timeout()
    : this(
        CityDataStatus.timeout,
        message:
            'Discovery is taking longer than expected. Check back in a few minutes.',
      );
}
