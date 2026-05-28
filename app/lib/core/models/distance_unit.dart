enum DistanceUnit { km, mi }

extension DistanceUnitExt on DistanceUnit {
  // Formats a distance given in kilometers according to this unit. Mirrors
  // the original km logic: under 1 → metres / feet, under 10 → one decimal,
  // otherwise rounded. Returned label includes the unit suffix.
  String format(double km) {
    switch (this) {
      case DistanceUnit.km:
        if (km < 1) return '${(km * 1000).round()} m';
        if (km < 10) return '${km.toStringAsFixed(1)} km';
        return '${km.round()} km';
      case DistanceUnit.mi:
        final mi = km * 0.621371;
        if (mi < 0.1) return '${(km * 3280.84).round()} ft';
        if (mi < 10) return '${mi.toStringAsFixed(1)} mi';
        return '${mi.round()} mi';
    }
  }
}
