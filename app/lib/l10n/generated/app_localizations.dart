import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppL10n
/// returned by `AppL10n.of(context)`.
///
/// Applications need to include `AppL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppL10n.localizationsDelegates,
///   supportedLocales: AppL10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppL10n.supportedLocales
/// property.
abstract class AppL10n {
  AppL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppL10n of(BuildContext context) {
    return Localizations.of<AppL10n>(context, AppL10n)!;
  }

  static const LocalizationsDelegate<AppL10n> delegate = _AppL10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pl'),
  ];

  /// App name shown in the launcher/title bar.
  ///
  /// In en, this message translates to:
  /// **'Event Radar'**
  String get appTitle;

  /// Overline above the current city on the Discover header.
  ///
  /// In en, this message translates to:
  /// **'DISCOVERING EVENTS IN'**
  String get discoveringEventsIn;

  /// Placeholder text shown when no city is selected.
  ///
  /// In en, this message translates to:
  /// **'Choose a city'**
  String get chooseCity;

  /// Title of the city picker page.
  ///
  /// In en, this message translates to:
  /// **'Choose City'**
  String get chooseCityTitle;

  /// Small badge on a city picker row that's been picked before.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get cityBadgeRecent;

  /// Small badge on a city picker row close to the user's current location.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get cityBadgeNearby;

  /// Small badge on a city picker row that already has an indexed dataset.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get cityBadgeFetched;

  /// Empty-state heading on Discover when no city is selected.
  ///
  /// In en, this message translates to:
  /// **'Choose a city to\ndiscover events'**
  String get chooseCityToDiscoverEvents;

  /// Label on the call-to-action button to open the city picker.
  ///
  /// In en, this message translates to:
  /// **'Pick a city'**
  String get pickACity;

  /// Tooltip on the language/region icon button.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get regionTooltip;

  /// Title of the settings bottom sheet.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Section label for the theme-mode segmented control.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeLabel;

  /// Theme-mode option that follows the OS setting.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// Light theme-mode option.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// Dark theme-mode option.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// Section label for the language segmented control.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// Language option that follows the device locale.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// English-language option.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Polish-language option (shown in Polish so users can recognise it regardless of current locale).
  ///
  /// In en, this message translates to:
  /// **'Polski'**
  String get languagePolish;

  /// Section label for the distance-unit segmented control.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distanceUnitLabel;

  /// Distance-unit option (km).
  ///
  /// In en, this message translates to:
  /// **'Kilometres'**
  String get distanceUnitKm;

  /// Distance-unit option (mi).
  ///
  /// In en, this message translates to:
  /// **'Miles'**
  String get distanceUnitMi;

  /// Section label for the saved-event notification toggle.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get notificationsLabel;

  /// Helper text describing what the notifications toggle does.
  ///
  /// In en, this message translates to:
  /// **'Notify the day before saved events.'**
  String get notificationsHint;

  /// Reminder notification title shown the day before a saved event.
  ///
  /// In en, this message translates to:
  /// **'{title} is tomorrow'**
  String notificationsTitle(String title);

  /// Reminder notification body. venuePart is empty or ' at <venue>'.
  ///
  /// In en, this message translates to:
  /// **'Starts at {time}{venuePart}'**
  String notificationsBody(String time, String venuePart);

  /// Section header for events closest to the user's location.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get nearbySection;

  /// Label preceding the sort chips above the All Events list.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sortByLabel;

  /// Sort option that orders events chronologically.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get sortByDate;

  /// Sort option that orders events by distance from the user.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get sortByNearby;

  /// Placeholder text in the search field on Discover.
  ///
  /// In en, this message translates to:
  /// **'Search events'**
  String get searchHint;

  /// Section header for the featured-events carousel.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get featuredSection;

  /// Section header for the full events list.
  ///
  /// In en, this message translates to:
  /// **'All Events'**
  String get allEventsSection;

  /// Trailing label on the All Events header showing how many events match.
  ///
  /// In en, this message translates to:
  /// **'{count} found'**
  String eventsFound(int count);

  /// Leading text in the stats card before the schema.org link.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 event} other{{count} events}} auto-discovered from'**
  String eventsAutoDiscoveredFrom(int count);

  /// Brand name of the structured-data source.
  ///
  /// In en, this message translates to:
  /// **'schema.org'**
  String get schemaOrg;

  /// Inline loading text inside the stats card.
  ///
  /// In en, this message translates to:
  /// **'Discovering events…'**
  String get discoveringEventsLoading;

  /// Same as above but after the first poll cycle.
  ///
  /// In en, this message translates to:
  /// **'Still discovering events…'**
  String get stillDiscoveringEventsLoading;

  /// Tooltip on the offline-cloud icon when cached data is shown.
  ///
  /// In en, this message translates to:
  /// **'Showing offline data'**
  String get showingOfflineData;

  /// Overline above the Bookmarks header.
  ///
  /// In en, this message translates to:
  /// **'SAVED FOR LATER'**
  String get savedForLater;

  /// Title of the Saved screen.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get bookmarks;

  /// Trailing label on the Saved header.
  ///
  /// In en, this message translates to:
  /// **'{count} saved'**
  String savedCount(int count);

  /// Group-by-city toggle label on Saved.
  ///
  /// In en, this message translates to:
  /// **'By location'**
  String get byLocation;

  /// Group-by-date toggle label on Saved.
  ///
  /// In en, this message translates to:
  /// **'By date'**
  String get byDate;

  /// Header for events happening today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get bucketToday;

  /// Header for events happening tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get bucketTomorrow;

  /// Header for events later in the current week.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get bucketThisWeek;

  /// Header for events later in the current month.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get bucketThisMonth;

  /// Header for events beyond the current month.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get bucketLater;

  /// Header for past events.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get bucketPast;

  /// Group header when city data is missing.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get groupUnknown;

  /// Small badge highlighting the user's currently-selected city group.
  ///
  /// In en, this message translates to:
  /// **'CURRENT'**
  String get groupCurrent;

  /// Empty-state heading on the Saved screen.
  ///
  /// In en, this message translates to:
  /// **'No saved events yet'**
  String get noSavedEvents;

  /// Empty-state body text on the Saved screen.
  ///
  /// In en, this message translates to:
  /// **'Tap the bookmark icon on an event\nin Discover to save it here.'**
  String get noSavedEventsBody;

  /// Fallback app-bar title on the Map screen when no city is selected.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get mapTitle;

  /// Empty-state body on the Map when no city is selected.
  ///
  /// In en, this message translates to:
  /// **'Select a city on the Discover tab to see events on the map.'**
  String get mapNoCitySelected;

  /// Empty-state body inside the expanded events panel on the Map.
  ///
  /// In en, this message translates to:
  /// **'No events to show.'**
  String get mapNoEvents;

  /// Tooltip on the fit-to-events FAB.
  ///
  /// In en, this message translates to:
  /// **'Fit to events'**
  String get fitToEvents;

  /// Tooltip on the recenter-on-user FAB.
  ///
  /// In en, this message translates to:
  /// **'My location'**
  String get myLocation;

  /// Lowercase "today" used as suffix in counts.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get today;

  /// Title of the expanded events panel on the Map.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get events;

  /// Trailing label on the events panel when no events are happening today.
  ///
  /// In en, this message translates to:
  /// **'{count} upcoming'**
  String upcomingCount(int count);

  /// Badge on the events chip / panel showing today-only event count.
  ///
  /// In en, this message translates to:
  /// **'{count} today'**
  String todayCount(int count);

  /// Pluralized event count, e.g. on the events chip and map app-bar.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 event} other{{count} events}}'**
  String eventCount(int count);

  /// Inline pill shown while events load on the Map.
  ///
  /// In en, this message translates to:
  /// **'Loading events…'**
  String get loadingEvents;

  /// Tooltip on the minimize button on a draggable overlay.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get collapse;

  /// Tooltip on the close button on a draggable overlay.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// Button that opens Google Maps directions to the event.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get directions;

  /// Button that opens the event details screen.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// Snackbar shown when the user declines location permission once.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied'**
  String get locationPermissionDenied;

  /// Snackbar shown when location permission is hard-denied; pairs with a Settings action.
  ///
  /// In en, this message translates to:
  /// **'Location permission permanently denied'**
  String get locationPermissionDeniedForever;

  /// Action label on snackbars that should deep-link to OS app settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Snackbar shown when the geolocation call throws.
  ///
  /// In en, this message translates to:
  /// **'Could not get your location'**
  String get couldNotGetLocation;

  /// Snackbar shown when launchUrl to Google Maps fails.
  ///
  /// In en, this message translates to:
  /// **'Could not open Google Maps'**
  String get couldNotOpenMaps;

  /// InfoRow label on the event details screen.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// InfoRow label on the event details screen.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get timeLabel;

  /// InfoRow label on the event details screen.
  ///
  /// In en, this message translates to:
  /// **'Venue'**
  String get venueLabel;

  /// InfoRow label on the event details screen.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get priceLabel;

  /// Price value shown for free events.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// Price value shown when the source doesn't provide one.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// Heading above the event description on the details screen.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutSection;

  /// Button label that opens the source page in the in-app browser.
  ///
  /// In en, this message translates to:
  /// **'View page'**
  String get viewPage;

  /// Attribution line under cards/buttons ("via wroclawguide.com").
  ///
  /// In en, this message translates to:
  /// **'via {host}'**
  String viaSource(String host);

  /// Fallback name used in timeSuffix when the phone IANA zone can't be resolved.
  ///
  /// In en, this message translates to:
  /// **'your'**
  String get timeYour;

  /// Time-zone label suffix, e.g. "Warsaw time" or "your time".
  ///
  /// In en, this message translates to:
  /// **'{name} time'**
  String timeSuffix(String name);

  /// Badge on past events.
  ///
  /// In en, this message translates to:
  /// **'PAST'**
  String get past;

  /// Badge on upcoming events.
  ///
  /// In en, this message translates to:
  /// **'UPCOMING'**
  String get upcoming;

  /// Compact three-letter "past" badge used inside small date squares.
  ///
  /// In en, this message translates to:
  /// **'PAS'**
  String get pasShort;

  /// Duration label for events with no end or that span multiple days.
  ///
  /// In en, this message translates to:
  /// **'All day'**
  String get allDay;

  /// Duration label for multi-day events.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String daysCount(int count);

  /// Date-filter chip label on Discover.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get filterToday;

  /// Date-filter chip label on Discover.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get filterWeek;

  /// Date-filter chip label on Discover.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get filterMonth;

  /// Date-filter chip label on Discover.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// Toggle chip on Discover that hides events with a known non-zero price.
  ///
  /// In en, this message translates to:
  /// **'Free only'**
  String get filterFreeOnly;

  /// Date-filter chip on Discover that shows only events whose start has already passed.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get filterPast;

  /// Category-filter chip label for showing every category.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get categoryAll;

  /// Event category.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get categoryMusic;

  /// Event category.
  ///
  /// In en, this message translates to:
  /// **'Theater'**
  String get categoryTheater;

  /// Event category.
  ///
  /// In en, this message translates to:
  /// **'Art'**
  String get categoryArt;

  /// Event category.
  ///
  /// In en, this message translates to:
  /// **'Festival'**
  String get categoryFestival;

  /// Event category.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get categoryFood;

  /// Event category.
  ///
  /// In en, this message translates to:
  /// **'Sports'**
  String get categorySports;

  /// Event category.
  ///
  /// In en, this message translates to:
  /// **'Comedy'**
  String get categoryComedy;

  /// Event category.
  ///
  /// In en, this message translates to:
  /// **'Dance'**
  String get categoryDance;

  /// Event category.
  ///
  /// In en, this message translates to:
  /// **'Literature'**
  String get categoryLiterature;

  /// Event category.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get categoryEducation;

  /// Event category.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get categoryFamily;

  /// Event category.
  ///
  /// In en, this message translates to:
  /// **'Film'**
  String get categoryFilm;

  /// Event category.
  ///
  /// In en, this message translates to:
  /// **'Market'**
  String get categoryMarket;

  /// Event category.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get categoryBusiness;

  /// Event category.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get categorySocial;

  /// Event category.
  ///
  /// In en, this message translates to:
  /// **'Tour'**
  String get categoryTour;

  /// Event category.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;

  /// Bottom-tab label for the Discover page.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get pageDiscover;

  /// Bottom-tab label for the Saved page.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get pageSaved;

  /// Bottom-tab label for the Map page.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get pageMap;

  /// Default error message in StatusView when none is supplied.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get statusErrorGeneric;

  /// Default timeout message in StatusView when none is supplied.
  ///
  /// In en, this message translates to:
  /// **'Timed out'**
  String get statusTimedOut;

  /// Default loading message in StatusView when none is supplied.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get statusLoading;

  /// Empty-list message used by StatusView.empty().
  ///
  /// In en, this message translates to:
  /// **'No upcoming events found for this city'**
  String get statusEmpty;

  /// Default retry button label.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Status message shown while the first scrape kicks off.
  ///
  /// In en, this message translates to:
  /// **'Discovering events - usually takes about 2 minutes the first time.'**
  String get scrapeStartedMessage;

  /// Status message shown on subsequent polls while waiting for results.
  ///
  /// In en, this message translates to:
  /// **'Still discovering events…'**
  String get scrapePollingMessage;

  /// Status message shown when the trigger call fails.
  ///
  /// In en, this message translates to:
  /// **'Could not start event discovery. Try again later.'**
  String get scrapeErrorMessage;

  /// Status message shown when polling exceeds the deadline.
  ///
  /// In en, this message translates to:
  /// **'Discovery is taking longer than expected. Check back in a few minutes.'**
  String get scrapeTimeoutMessage;
}

class _AppL10nDelegate extends LocalizationsDelegate<AppL10n> {
  const _AppL10nDelegate();

  @override
  Future<AppL10n> load(Locale locale) {
    return SynchronousFuture<AppL10n>(lookupAppL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppL10nDelegate old) => false;
}

AppL10n lookupAppL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppL10nEn();
    case 'pl':
      return AppL10nPl();
  }

  throw FlutterError(
    'AppL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
