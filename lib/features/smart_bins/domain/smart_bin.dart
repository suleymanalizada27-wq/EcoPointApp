import '../../../core/constants/app_constants.dart';
import '../../../core/utils/json_utils.dart';

/// A smart recycling bin from `devices/{id}`.
///
/// Fields written by the ESP32 firmware in the legacy system: `name`,
/// `location` (text), `fillPercent`, `temperature`, `weight`, `lastSeen`.
/// **Coordinates (`lat`, `lng`) did not exist** in the legacy schema; bins
/// only appear on the map once the operator adds them. No coordinates are
/// invented by the app.
class SmartBin {
  const SmartBin({
    required this.id,
    required this.name,
    required this.locationText,
    required this.fillPercent,
    this.temperature,
    this.weightGrams,
    this.lastSeen,
    this.lat,
    this.lng,
    this.supportsWeightRedeem = false,
  });

  final String id;
  final String name;
  final String locationText;
  final int fillPercent;
  final double? temperature;
  final int? weightGrams;
  final DateTime? lastSeen;
  final double? lat;
  final double? lng;

  /// True when the firmware publishes `weightEventId`, which the backend
  /// needs to make a weight reading single-use.
  final bool supportsWeightRedeem;

  bool get hasCoordinates =>
      lat != null &&
      lng != null &&
      lat! >= -90 &&
      lat! <= 90 &&
      lng! >= -180 &&
      lng! <= 180;

  bool isOnline(DateTime now) {
    final seen = lastSeen;
    if (seen == null) return false;
    return now.difference(seen).inSeconds <= AppConstants.binOnlineWindowSeconds;
  }

  bool get isNearlyFull => fillPercent >= AppConstants.binFullWarningPercent;

  factory SmartBin.fromMap(String id, Map<String, Object?> m) {
    final seen = asInt(m['lastSeen']);
    final weight = m['weight'];
    final temp = asDoubleOrNull(m['temperature']);
    return SmartBin(
      id: id,
      name: asString(m['name'], id),
      locationText: asString(m['location']),
      fillPercent: asInt(m['fillPercent']).clamp(0, 100),
      temperature: temp,
      weightGrams: weight == null ? null : asInt(weight),
      lastSeen: seen > 0 ? DateTime.fromMillisecondsSinceEpoch(seen) : null,
      lat: asDoubleOrNull(m['lat']),
      lng: asDoubleOrNull(m['lng']),
      supportsWeightRedeem: m['weightEventId'] != null,
    );
  }
}
