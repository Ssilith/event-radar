//* User's preferred distance unit
enum DistanceUnit { km, mi }

extension DistanceUnitExt on DistanceUnit {
  //* Format a kilometre distance in this unit (m/ft under 1, 1 decimal under 10)
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
