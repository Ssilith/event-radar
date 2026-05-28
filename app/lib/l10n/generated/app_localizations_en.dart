// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppL10nEn extends AppL10n {
  AppL10nEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Event Radar';

  @override
  String get discoveringEventsIn => 'DISCOVERING EVENTS IN';

  @override
  String get chooseCity => 'Choose a city';

  @override
  String get chooseCityTitle => 'Choose City';

  @override
  String get cityBadgeRecent => 'Recent';

  @override
  String get cityBadgeNearby => 'Nearby';

  @override
  String get cityBadgeFetched => 'Available';

  @override
  String get chooseCityToDiscoverEvents => 'Choose a city to\ndiscover events';

  @override
  String get pickACity => 'Pick a city';

  @override
  String get regionTooltip => 'Region';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get themeLabel => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get languageLabel => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get languageEnglish => 'English';

  @override
  String get languagePolish => 'Polski';

  @override
  String get distanceUnitLabel => 'Distance';

  @override
  String get distanceUnitKm => 'Kilometres';

  @override
  String get distanceUnitMi => 'Miles';

  @override
  String get notificationsLabel => 'Reminders';

  @override
  String get notificationsHint => 'Notify the day before saved events.';

  @override
  String notificationsTitle(String title) {
    return '$title is tomorrow';
  }

  @override
  String notificationsBody(String time, String venuePart) {
    return 'Starts at $time$venuePart';
  }

  @override
  String get nearbySection => 'Nearby';

  @override
  String get sortByLabel => 'Sort';

  @override
  String get sortByDate => 'Date';

  @override
  String get sortByNearby => 'Nearby';

  @override
  String get searchHint => 'Search events';

  @override
  String get featuredSection => 'Featured';

  @override
  String get allEventsSection => 'All Events';

  @override
  String eventsFound(int count) {
    return '$count found';
  }

  @override
  String eventsAutoDiscoveredFrom(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count events',
      one: '1 event',
    );
    return '$_temp0 auto-discovered from';
  }

  @override
  String get schemaOrg => 'schema.org';

  @override
  String get discoveringEventsLoading => 'Discovering events…';

  @override
  String get stillDiscoveringEventsLoading => 'Still discovering events…';

  @override
  String get showingOfflineData => 'Showing offline data';

  @override
  String get savedForLater => 'SAVED FOR LATER';

  @override
  String get bookmarks => 'Bookmarks';

  @override
  String savedCount(int count) {
    return '$count saved';
  }

  @override
  String get byLocation => 'By location';

  @override
  String get byDate => 'By date';

  @override
  String get bucketToday => 'Today';

  @override
  String get bucketTomorrow => 'Tomorrow';

  @override
  String get bucketThisWeek => 'This week';

  @override
  String get bucketThisMonth => 'This month';

  @override
  String get bucketLater => 'Later';

  @override
  String get bucketPast => 'Past';

  @override
  String get groupUnknown => 'Unknown';

  @override
  String get groupCurrent => 'CURRENT';

  @override
  String get noSavedEvents => 'No saved events yet';

  @override
  String get noSavedEventsBody =>
      'Tap the bookmark icon on an event\nin Discover to save it here.';

  @override
  String get mapTitle => 'Map';

  @override
  String get mapNoCitySelected =>
      'Select a city on the Discover tab to see events on the map.';

  @override
  String get mapNoEvents => 'No events to show.';

  @override
  String get fitToEvents => 'Fit to events';

  @override
  String get myLocation => 'My location';

  @override
  String get today => 'today';

  @override
  String get events => 'Events';

  @override
  String upcomingCount(int count) {
    return '$count upcoming';
  }

  @override
  String todayCount(int count) {
    return '$count today';
  }

  @override
  String eventCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count events',
      one: '1 event',
    );
    return '$_temp0';
  }

  @override
  String get loadingEvents => 'Loading events…';

  @override
  String get collapse => 'Collapse';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get directions => 'Directions';

  @override
  String get details => 'Details';

  @override
  String get locationPermissionDenied => 'Location permission denied';

  @override
  String get locationPermissionDeniedForever =>
      'Location permission permanently denied';

  @override
  String get settings => 'Settings';

  @override
  String get couldNotGetLocation => 'Could not get your location';

  @override
  String get couldNotOpenMaps => 'Could not open Google Maps';

  @override
  String get dateLabel => 'Date';

  @override
  String get timeLabel => 'Time';

  @override
  String get venueLabel => 'Venue';

  @override
  String get priceLabel => 'Price';

  @override
  String get free => 'Free';

  @override
  String get unknown => 'Unknown';

  @override
  String get aboutSection => 'About';

  @override
  String get viewPage => 'View page';

  @override
  String viaSource(String host) {
    return 'via $host';
  }

  @override
  String get timeYour => 'your';

  @override
  String timeSuffix(String name) {
    return '$name time';
  }

  @override
  String get past => 'PAST';

  @override
  String get upcoming => 'UPCOMING';

  @override
  String get pasShort => 'PAS';

  @override
  String get allDay => 'All day';

  @override
  String daysCount(int count) {
    return '$count days';
  }

  @override
  String get filterToday => 'Today';

  @override
  String get filterWeek => 'This week';

  @override
  String get filterMonth => 'This month';

  @override
  String get filterAll => 'All';

  @override
  String get filterFreeOnly => 'Free only';

  @override
  String get filterPast => 'Past';

  @override
  String get categoryAll => 'All';

  @override
  String get categoryMusic => 'Music';

  @override
  String get categoryTheater => 'Theater';

  @override
  String get categoryArt => 'Art';

  @override
  String get categoryFestival => 'Festival';

  @override
  String get categoryFood => 'Food';

  @override
  String get categorySports => 'Sports';

  @override
  String get categoryComedy => 'Comedy';

  @override
  String get categoryDance => 'Dance';

  @override
  String get categoryLiterature => 'Literature';

  @override
  String get categoryEducation => 'Education';

  @override
  String get categoryFamily => 'Family';

  @override
  String get categoryFilm => 'Film';

  @override
  String get categoryMarket => 'Market';

  @override
  String get categoryBusiness => 'Business';

  @override
  String get categorySocial => 'Social';

  @override
  String get categoryTour => 'Tour';

  @override
  String get categoryOther => 'Other';

  @override
  String get pageDiscover => 'Discover';

  @override
  String get pageSaved => 'Saved';

  @override
  String get pageMap => 'Map';

  @override
  String get statusErrorGeneric => 'Something went wrong';

  @override
  String get statusTimedOut => 'Timed out';

  @override
  String get statusLoading => 'Loading…';

  @override
  String get statusEmpty => 'No upcoming events found for this city';

  @override
  String get retry => 'Retry';

  @override
  String get scrapeStartedMessage =>
      'Discovering events - usually takes about 2 minutes the first time.';

  @override
  String get scrapePollingMessage => 'Still discovering events…';

  @override
  String get scrapeErrorMessage =>
      'Could not start event discovery. Try again later.';

  @override
  String get scrapeTimeoutMessage =>
      'Discovery is taking longer than expected. Check back in a few minutes.';
}
