// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppL10nPl extends AppL10n {
  AppL10nPl([String locale = 'pl']) : super(locale);

  @override
  String get appTitle => 'Event Radar';

  @override
  String get discoveringEventsIn => 'ODKRYWAJ WYDARZENIA W';

  @override
  String get chooseCity => 'Wybierz miasto';

  @override
  String get chooseCityTitle => 'Wybierz miasto';

  @override
  String get cityBadgeRecent => 'Ostatnie';

  @override
  String get cityBadgeNearby => 'W pobliżu';

  @override
  String get cityBadgeFetched => 'Dostępne';

  @override
  String get chooseCityToDiscoverEvents =>
      'Wybierz miasto, aby\nodkryć wydarzenia';

  @override
  String get pickACity => 'Wybierz miasto';

  @override
  String get regionTooltip => 'Region';

  @override
  String get settingsTitle => 'Ustawienia';

  @override
  String get themeLabel => 'Motyw';

  @override
  String get themeSystem => 'Systemowy';

  @override
  String get themeLight => 'Jasny';

  @override
  String get themeDark => 'Ciemny';

  @override
  String get languageLabel => 'Język';

  @override
  String get languageSystem => 'Systemowy';

  @override
  String get languageEnglish => 'English';

  @override
  String get languagePolish => 'Polski';

  @override
  String get distanceUnitLabel => 'Odległość';

  @override
  String get distanceUnitKm => 'Kilometry';

  @override
  String get distanceUnitMi => 'Mile';

  @override
  String get notificationsLabel => 'Przypomnienia';

  @override
  String get notificationsHint =>
      'Powiadom dzień przed zapisanymi wydarzeniami.';

  @override
  String notificationsTitle(String title) {
    return '$title jutro';
  }

  @override
  String notificationsBody(String time, String venuePart) {
    return 'Początek: $time$venuePart';
  }

  @override
  String get nearbySection => 'W pobliżu';

  @override
  String get sortByLabel => 'Sortuj';

  @override
  String get sortByDate => 'Data';

  @override
  String get sortByNearby => 'Najbliższe';

  @override
  String get searchHint => 'Szukaj wydarzeń';

  @override
  String get featuredSection => 'Polecane';

  @override
  String get allEventsSection => 'Wszystkie wydarzenia';

  @override
  String eventsFound(int count) {
    return 'znaleziono $count';
  }

  @override
  String eventsAutoDiscoveredFrom(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wydarzeń',
      many: '$count wydarzeń',
      few: '$count wydarzenia',
      one: '1 wydarzenie',
    );
    return '$_temp0 pobrane z';
  }

  @override
  String get schemaOrg => 'schema.org';

  @override
  String get discoveringEventsLoading => 'Wyszukiwanie wydarzeń…';

  @override
  String get stillDiscoveringEventsLoading => 'Nadal wyszukuję wydarzenia…';

  @override
  String get showingOfflineData => 'Wyświetlanie danych offline';

  @override
  String get savedForLater => 'ZAPISANE NA PÓŹNIEJ';

  @override
  String get bookmarks => 'Zakładki';

  @override
  String savedCount(int count) {
    return 'zapisane: $count';
  }

  @override
  String get byLocation => 'Według lokalizacji';

  @override
  String get byDate => 'Według daty';

  @override
  String get bucketToday => 'Dziś';

  @override
  String get bucketTomorrow => 'Jutro';

  @override
  String get bucketThisWeek => 'W tym tygodniu';

  @override
  String get bucketThisMonth => 'W tym miesiącu';

  @override
  String get bucketLater => 'Później';

  @override
  String get bucketPast => 'Minione';

  @override
  String get groupUnknown => 'Nieznane';

  @override
  String get groupCurrent => 'OBECNE';

  @override
  String get noSavedEvents => 'Brak zapisanych wydarzeń';

  @override
  String get noSavedEventsBody =>
      'Stuknij ikonę zakładki przy wydarzeniu\nw Odkrywaniu, aby zapisać je tutaj.';

  @override
  String get mapTitle => 'Mapa';

  @override
  String get mapNoCitySelected =>
      'Wybierz miasto w zakładce Odkrywaj, aby zobaczyć wydarzenia na mapie.';

  @override
  String get mapNoEvents => 'Brak wydarzeń do wyświetlenia.';

  @override
  String get fitToEvents => 'Dopasuj do wydarzeń';

  @override
  String get myLocation => 'Moja lokalizacja';

  @override
  String get today => 'dziś';

  @override
  String get events => 'Wydarzenia';

  @override
  String upcomingCount(int count) {
    return '$count nadchodzących';
  }

  @override
  String todayCount(int count) {
    return '$count dziś';
  }

  @override
  String eventCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wydarzeń',
      many: '$count wydarzeń',
      few: '$count wydarzenia',
      one: '1 wydarzenie',
    );
    return '$_temp0';
  }

  @override
  String get loadingEvents => 'Ładowanie wydarzeń…';

  @override
  String get collapse => 'Zwiń';

  @override
  String get dismiss => 'Zamknij';

  @override
  String get directions => 'Trasa';

  @override
  String get details => 'Szczegóły';

  @override
  String get locationPermissionDenied => 'Brak zgody na lokalizację';

  @override
  String get locationPermissionDeniedForever =>
      'Lokalizacja jest trwale zablokowana';

  @override
  String get settings => 'Ustawienia';

  @override
  String get couldNotGetLocation => 'Nie można ustalić Twojej lokalizacji';

  @override
  String get couldNotOpenMaps => 'Nie udało się otworzyć Google Maps';

  @override
  String get dateLabel => 'Data';

  @override
  String get timeLabel => 'Godzina';

  @override
  String get venueLabel => 'Miejsce';

  @override
  String get priceLabel => 'Cena';

  @override
  String get free => 'Bezpłatne';

  @override
  String get unknown => 'Nieznana';

  @override
  String get aboutSection => 'Opis';

  @override
  String get viewPage => 'Otwórz stronę';

  @override
  String viaSource(String host) {
    return 'źródło: $host';
  }

  @override
  String get timeYour => 'Twojego';

  @override
  String timeSuffix(String name) {
    return 'czas $name';
  }

  @override
  String get past => 'MINIONE';

  @override
  String get upcoming => 'NADCHODZI';

  @override
  String get pasShort => 'MIN';

  @override
  String get allDay => 'Cały dzień';

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dni',
      many: '$count dni',
      few: '$count dni',
    );
    return '$_temp0';
  }

  @override
  String get filterToday => 'Dziś';

  @override
  String get filterWeek => 'W tym tygodniu';

  @override
  String get filterMonth => 'W tym miesiącu';

  @override
  String get filterAll => 'Wszystkie';

  @override
  String get filterPast => 'Minione';

  @override
  String get categoryAll => 'Wszystkie';

  @override
  String get categoryMusic => 'Muzyka';

  @override
  String get categoryTheater => 'Teatr';

  @override
  String get categoryArt => 'Sztuka';

  @override
  String get categoryFestival => 'Festiwal';

  @override
  String get categoryFood => 'Kulinaria';

  @override
  String get categorySports => 'Sport';

  @override
  String get categoryComedy => 'Kabaret';

  @override
  String get categoryDance => 'Taniec';

  @override
  String get categoryLiterature => 'Literatura';

  @override
  String get categoryEducation => 'Edukacja';

  @override
  String get categoryFamily => 'Rodzinne';

  @override
  String get categoryFilm => 'Film';

  @override
  String get categoryMarket => 'Targi';

  @override
  String get categoryBusiness => 'Biznes';

  @override
  String get categorySocial => 'Spotkania';

  @override
  String get categoryTour => 'Zwiedzanie';

  @override
  String get categoryOther => 'Inne';

  @override
  String get pageDiscover => 'Odkrywaj';

  @override
  String get pageSaved => 'Zapisane';

  @override
  String get pageMap => 'Mapa';

  @override
  String get statusErrorGeneric => 'Coś poszło nie tak';

  @override
  String get statusTimedOut => 'Upłynął limit czasu';

  @override
  String get statusLoading => 'Ładowanie…';

  @override
  String get statusEmpty =>
      'Nie znaleziono nadchodzących wydarzeń dla tego miasta';

  @override
  String get retry => 'Spróbuj ponownie';

  @override
  String get scrapeStartedMessage =>
      'Wyszukuję wydarzenia — pierwsze pobranie zwykle trwa ok. 2 minut.';

  @override
  String get scrapePollingMessage => 'Nadal wyszukuję wydarzenia…';

  @override
  String get scrapeErrorMessage =>
      'Nie udało się rozpocząć wyszukiwania. Spróbuj później.';

  @override
  String get scrapeTimeoutMessage =>
      'Wyszukiwanie trwa dłużej niż zwykle. Sprawdź ponownie za kilka minut.';
}
