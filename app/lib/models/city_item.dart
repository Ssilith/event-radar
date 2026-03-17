import 'package:event_radar/extensions/string_extensions.dart';

class CityItem {
  final String name;
  final String countryCode;

  const CityItem(this.name, this.countryCode);

  String get slug => '$name:$countryCode';

  @override
  String toString() => name.capitalize();

  @override
  bool operator ==(Object other) =>
      other is CityItem &&
      other.name.toLowerCase() == name.toLowerCase() &&
      other.countryCode == countryCode;

  @override
  int get hashCode => Object.hash(name.toLowerCase(), countryCode);
}
