class SpeedUtils {
  const SpeedUtils._();

  static double metersPerSecondToKmh(double value) => value * 3.6;

  static String formatKmh(double metersPerSecond) {
    return metersPerSecondToKmh(metersPerSecond).toStringAsFixed(1);
  }
}
