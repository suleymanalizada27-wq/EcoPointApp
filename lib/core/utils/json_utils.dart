/// Safe accessors for values coming out of Firebase Realtime Database, which
/// returns loosely-typed `Map<Object?, Object?>` / `List<Object?>` / `num`.
library;

Map<String, Object?> asMap(Object? value) {
  if (value is Map) {
    return value.map((k, v) => MapEntry(k.toString(), v));
  }
  if (value is List) {
    // RTDB turns maps with sequential integer keys into lists.
    final out = <String, Object?>{};
    for (var i = 0; i < value.length; i++) {
      if (value[i] != null) out['$i'] = value[i];
    }
    return out;
  }
  return const <String, Object?>{};
}

int asInt(Object? value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) {
    final parsed = num.tryParse(value.replaceAll(',', '').trim());
    if (parsed != null) return parsed.round();
  }
  return fallback;
}

double asDouble(Object? value, [double fallback = 0]) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim()) ?? fallback;
  return fallback;
}

double? asDoubleOrNull(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim());
  return null;
}

String asString(Object? value, [String fallback = '']) {
  if (value == null) return fallback;
  if (value is String) return value;
  return value.toString();
}

bool asBool(Object? value, [bool fallback = false]) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) return value.toLowerCase() == 'true';
  return fallback;
}
