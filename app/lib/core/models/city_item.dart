import 'package:extension_utils/string_utils.dart';

//* A city the user can browse, identified by name + ISO country code
class CityItem {
  final String name;
  final String countryCode;

  const CityItem(this.name, this.countryCode);

  //* "Name:CC" key used for dataset slugs and lookups
  String get slug => '$name:$countryCode';

  @override
  String toString() => name.capitalize();

  //* Case-insensitive on name so GPS/dataset casing differences still match
  @override
  bool operator ==(Object other) =>
      other is CityItem &&
      other.name.toLowerCase() == name.toLowerCase() &&
      other.countryCode == countryCode;

  //* Must mirror == (same fields, same lowercasing) for Set/Map correctness
  @override
  int get hashCode => Object.hash(name.toLowerCase(), countryCode);
}
