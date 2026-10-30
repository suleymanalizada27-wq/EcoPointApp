import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/ep_feedback.dart';
import '../data/bins_repository.dart';
import '../domain/smart_bin.dart';

/// Opens the phone's maps app with walking directions to [bin].
Future<void> openDirections(BuildContext context, SmartBin bin) async {
  if (!bin.hasCoordinates) return;
  final uri = Uri.parse(
    'https://www.google.com/maps/dir/?api=1'
    '&destination=${bin.lat},${bin.lng}&travelmode=walking',
  );
  var ok = false;
  try {
    ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    ok = false;
  }
  if (!ok && context.mounted) {
    showEpToast(context, context.tr('bins_open_failed'), kind: ToastKind.error);
  }
}

/// Nearest bin that is online, mapped and not nearly full; null if none or
/// the user's location is unknown.
SmartBin? nearestAvailableBin(
  List<SmartBin> bins,
  LocationState? location,
  DateTime now,
) {
  if (location == null || !location.hasFix) return null;
  SmartBin? best;
  double bestDist = double.infinity;
  for (final b in bins) {
    if (!b.hasCoordinates || !b.isOnline(now)) continue;
    if (b.fillPercent >= AppConstants.binFullWarningPercent) continue;
    final d = location.distanceTo(b);
    if (d != null && d < bestDist) {
      bestDist = d;
      best = b;
    }
  }
  return best;
}
