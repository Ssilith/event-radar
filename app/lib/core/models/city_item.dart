import 'package:diacritic/diacritic.dart';
import 'package:extension_utils/string_utils.dart';

//* A city the user can browse, identified by name + ISO country code
class CityItem {
  final String name;
  final String countryCode;

  const CityItem(this.name, this.countryCode);

  //* "Name:CC" key used for dataset slugs and lookups
  String get slug => '$name:$countryCode';

  //* Diacritic- and case-folded name so "Wrocław" (GPS/API) and "Wroclaw"
  //* (dataset slug) are treated as the same city
  String get _nameKey => removeDiacritics(name).toLowerCase();

  @override
  String toString() => name.capitalize();

  @override
  bool operator ==(Object other) =>
      other is CityItem &&
      other._nameKey == _nameKey &&
      other.countryCode == countryCode;

  //* Must mirror == (same normalized fields) for Set/Map correctness
  @override
  int get hashCode => Object.hash(_nameKey, countryCode);
}
