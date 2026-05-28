import 'package:event_radar/core/models/event.dart';
import 'package:event_radar/core/utils/language.dart';
import 'package:logging/logging.dart';
import 'package:url_launcher/url_launcher.dart';

final _log = Logger('MapsLauncher');

// Opens Google Maps with driving directions to `event`. Returns true when the
// platform reports a successful launch. Returns false if the event has no
// coordinates or the launch fails — callers are expected to surface the error
// in their own UI (snackbar, dialog, …).
Future<bool> openDirectionsToEvent(Event event) async {
  if (!event.hasLocation) return false;
  final uri = Uri.https('www.google.com', '/maps/dir/', {
    'api': '1',
    'destination': '${event.latitude!},${event.longitude!}',
    if (event.venue != null) 'destination_place': event.venue!,
    'travelmode': 'driving',
    'hl': deviceLanguageCode,
  });

  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (e, s) {
    _log.warning('launchUrl failed', e, s);
    return false;
  }
}
