import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../constants/app_constants.dart';
import '../utils/json_utils.dart';

/// A newer app version announced by the backend (`GET /app-version`).
class UpdateInfo {
  const UpdateInfo({required this.latest, required this.url, this.notes});
  final String latest;
  final String url;
  final String? notes;
}

/// True when [a] is a higher dotted version than [b] (1.10.0 > 1.9.3).
bool isNewerVersion(String a, String b) {
  List<int> parts(String v) => v
      .split('+')
      .first
      .split('.')
      .map((p) => int.tryParse(p.trim()) ?? 0)
      .toList();
  final x = parts(a);
  final y = parts(b);
  for (var i = 0; i < 3; i++) {
    final xi = i < x.length ? x[i] : 0;
    final yi = i < y.length ? y[i] : 0;
    if (xi != yi) return xi > yi;
  }
  return false;
}

/// Asked once per app start. Any failure (offline, sleeping server, no
/// version configured) simply means "no notice".
final updateInfoProvider = FutureProvider<UpdateInfo?>((ref) async {
  try {
    final base = AppConstants.backendUrl.replaceAll(RegExp(r'/+$'), '');
    final res = await http
        .get(Uri.parse('$base/app-version'))
        .timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) return null;
    final m = asMap(jsonDecode(utf8.decode(res.bodyBytes)));
    final latest = m['latest'];
    final url = m['url'];
    if (latest is! String || url is! String) return null;
    if (!url.startsWith('https://') && !url.startsWith('http://')) return null;
    if (!isNewerVersion(latest, AppConstants.appVersion)) return null;
    final notes = m['notes'];
    return UpdateInfo(
      latest: latest,
      url: url,
      notes: notes is String && notes.isNotEmpty ? notes : null,
    );
  } catch (_) {
    return null;
  }
});
