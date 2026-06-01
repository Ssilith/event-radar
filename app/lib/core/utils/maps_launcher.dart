import 'package:event_radar/core/models/event.dart';
import 'package:event_radar/core/utils/language.dart';
import 'package:logging/logging.dart';
import 'package:url_launcher/url_launcher.dart';

final _log = Logger('MapsLauncher');

//* Open Google Maps driving directions to an event (false if no coords/fails)
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
