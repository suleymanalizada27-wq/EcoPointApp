/// **Estimated** environmental impact.
///
/// The web app multiplied the scan count by fixed factors (42 g plastic,
/// 85 g CO₂, 3.2 L water, 14 Wh energy per scan). These are *not* measured by
/// the bins, so the UI always labels them as estimates.
class ImpactEstimate {
  const ImpactEstimate({
    required this.plasticGrams,
    required this.co2Grams,
    required this.waterLiters,
    required this.energyWh,
  });

  final int plasticGrams;
  final int co2Grams;
  final int waterLiters;
  final int energyWh;

  static const double plasticPerScan = 42;
  static const double co2PerScan = 85;
  static const double waterPerScan = 3.2;
  static const double energyPerScan = 14;

  factory ImpactEstimate.fromScans(int scans) {
    final s = scans < 0 ? 0 : scans;
    return ImpactEstimate(
      plasticGrams: (s * plasticPerScan).round(),
      co2Grams: (s * co2PerScan).round(),
      waterLiters: (s * waterPerScan).round(),
      energyWh: (s * energyPerScan).round(),
    );
  }
}
