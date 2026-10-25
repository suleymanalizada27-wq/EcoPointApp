import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/ep_colors.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/ep_card.dart';
import '../../../core/widgets/state_views.dart';
import '../data/bins_repository.dart';
import '../domain/smart_bin.dart';
import 'bin_detail_sheet.dart';

Color fillColor(EpColors c, int pct) =>
    pct >= 80 ? c.danger : (pct >= 50 ? c.warning : c.emerald);

class BinsScreen extends ConsumerStatefulWidget {
  const BinsScreen({super.key});

  @override
  ConsumerState<BinsScreen> createState() => _BinsScreenState();
}

class _BinsScreenState extends ConsumerState<BinsScreen> {
  bool _showMap = true;
  bool _mapFailed = false;
  final MapController _mapController = MapController();

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ep;
    final bins = ref.watch(binsProvider);
    final location = ref.watch(locationProvider).valueOrNull;

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Sp.gutter, Sp.md, Sp.gutter, Sp.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(context.tr('bins_title'),
                      style: context.text.headlineMedium),
                ),
                const SizedBox(height: 2),
                Text(context.tr('bins_sub'),
                    style: context.text.bodyMedium
                        ?.copyWith(color: c.textSecondary)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Sp.gutter),
            child: _Segmented(
              leftLabel: context.tr('bins_map_tab'),
              rightLabel: context.tr('bins_list_tab'),
              leftSelected: _showMap,
              onChanged: (left) => setState(() => _showMap = left),
            ),
          ),
          const SizedBox(height: Sp.sm),
          if (location != null && !location.hasFix)
            _LocationBanner(
              status: location.status,
              onEnable: () => ref.read(locationProvider.notifier).request(),
            ),
          Expanded(
            child: bins.when(
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(
                error: e,
                onRetry: () => ref.invalidate(binsProvider),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return EmptyView(
                    icon: Icons.delete_outline_rounded,
                    message: context.tr('bins_empty'),
                  );
                }
                final sorted = _sortByDistance(list, location);
                return _showMap && !_mapFailed
                    ? _MapTab(
                        bins: sorted,
                        location: location,
                        controller: _mapController,
                        onTileError: () {
                          if (mounted && !_mapFailed) {
                            setState(() => _mapFailed = true);
                          }
                        },
                      )
                    : _ListTab(
                        bins: sorted,
                        location: location,
                        mapFailed: _mapFailed && _showMap,
                      );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<SmartBin> _sortByDistance(List<SmartBin> list, LocationState? loc) {
    if (loc == null || !loc.hasFix) return list;
    final copy = [...list];
    copy.sort((a, b) {
      final da = loc.distanceTo(a);
      final db = loc.distanceTo(b);
      if (da == null && db == null) return a.name.compareTo(b.name);
      if (da == null) return 1;
      if (db == null) return -1;
      return da.compareTo(db);
    });
    return copy;
  }
}

class _Segmented extends StatelessWidget {
  const _Segmented({
    required this.leftLabel,
    required this.rightLabel,
    required this.leftSelected,
    required this.onChanged,
  });

  final String leftLabel;
  final String rightLabel;
  final bool leftSelected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.ep;
    Widget seg(String label, bool selected, VoidCallback onTap) => Expanded(
          child: Semantics(
            button: true,
            selected: selected,
            label: label,
            excludeSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: AnimatedContainer(
                duration: Motion.fast,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? c.surfaceRaised : Colors.transparent,
                  borderRadius: BorderRadius.circular(Rad.pill),
                ),
                child: Text(
                  label,
                  style: context.text.labelLarge?.copyWith(
                    color: selected ? c.textPrimary : c.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        );

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(Rad.pill),
        border: Border.all(color: c.outline),
      ),
      child: Row(
        children: [
          seg(leftLabel, leftSelected, () => onChanged(true)),
          seg(rightLabel, !leftSelected, () => onChanged(false)),
        ],
      ),
    );
  }
}

class _LocationBanner extends StatelessWidget {
  const _LocationBanner({required this.status, required this.onEnable});
  final LocationStatus status;
  final VoidCallback onEnable;

  @override
  Widget build(BuildContext context) {
    final c = context.ep;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Sp.gutter, 0, Sp.gutter, Sp.sm),
      child: EpCard(
        color: c.surfaceRaised,
        padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.xs),
        child: Row(
          children: [
            Icon(Icons.location_off_rounded, size: 18, color: c.warning),
            const SizedBox(width: Sp.xs),
            Expanded(
              child: Text(context.tr('bins_location_off'),
                  style: context.text.bodySmall),
            ),
            TextButton(
              onPressed: status == LocationStatus.deniedForever
                  ? () => Geolocator.openAppSettings()
                  : onEnable,
              child: Text(context.tr('bins_enable_location')),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapTab extends StatelessWidget {
  const _MapTab({
    required this.bins,
    required this.location,
    required this.controller,
    required this.onTileError,
  });

  final List<SmartBin> bins;
  final LocationState? location;
  final MapController controller;
  final VoidCallback onTileError;

  @override
  Widget build(BuildContext context) {
    final c = context.ep;
    final mapped = bins.where((b) => b.hasCoordinates).toList();
    final unmapped = bins.length - mapped.length;
    final now = DateTime.now();

    LatLng center = const LatLng(
        AppConstants.defaultLat, AppConstants.defaultLng);
    double zoom = AppConstants.defaultZoom;
    if (location != null && location!.hasFix) {
      center = LatLng(location!.latitude!, location!.longitude!);
      zoom = 14;
    } else if (mapped.isNotEmpty) {
      center = LatLng(mapped.first.lat!, mapped.first.lng!);
      zoom = 13;
    }

    if (mapped.isEmpty) {
      // Honest fallback: bins exist but none has coordinates yet.
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Sp.gutter),
            child: EpCard(
              color: c.surfaceRaised,
              child: Row(
                children: [
                  Icon(Icons.map_outlined, color: c.warning),
                  const SizedBox(width: Sp.sm),
                  Expanded(
                    child: Text(
                      context.tr('bins_no_coords', {'n': unmapped}),
                      style: context.text.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
              child: _ListTab(
                  bins: bins, location: location, mapFailed: false)),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(Sp.gutter, 0, Sp.gutter, 100),
      child: ClipRRect(
        borderRadius: Rad.card,
        child: Stack(
          children: [
            FlutterMap(
              mapController: controller,
              options: MapOptions(
                initialCenter: center,
                initialZoom: zoom,
                minZoom: 3,
                maxZoom: 19,
              ),
              children: [
                TileLayer(
                  urlTemplate: AppConstants.osmTileUrl,
                  userAgentPackageName: AppConstants.androidPackage,
                  errorTileCallback: (tile, error, stack) => onTileError(),
                ),
                MarkerLayer(
                  markers: [
                    if (location != null && location!.hasFix)
                      Marker(
                        point:
                            LatLng(location!.latitude!, location!.longitude!),
                        width: 28,
                        height: 28,
                        child: Container(
                          decoration: BoxDecoration(
                            color: c.info,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                        ),
                      ),
                    for (final bin in mapped)
                      Marker(
                        point: LatLng(bin.lat!, bin.lng!),
                        width: 44,
                        height: 44,
                        child: GestureDetector(
                          onTap: () => showBinDetail(context, bin),
                          child: _BinPin(
                            bin: bin,
                            online: bin.isOnline(now),
                          ),
                        ),
                      ),
                  ],
                ),
                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution(context.tr('bins_map_attribution')),
                  ],
                ),
              ],
            ),
            if (unmapped > 0)
              Positioned(
                left: 8,
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: Sp.sm, vertical: Sp.xs),
                  decoration: BoxDecoration(
                    color: c.surface.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(Rad.md),
                  ),
                  child: Text(
                    context.tr('bins_no_coords', {'n': unmapped}),
                    style: context.text.bodySmall,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BinPin extends StatelessWidget {
  const _BinPin({required this.bin, required this.online});
  final SmartBin bin;
  final bool online;

  @override
  Widget build(BuildContext context) {
    final c = context.ep;
    final tone = online ? fillColor(c, bin.fillPercent) : c.textTertiary;
    return Semantics(
      button: true,
      label: '${bin.name}, ${bin.fillPercent}%',
      child: Container(
        decoration: BoxDecoration(
          color: tone,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [
            BoxShadow(color: Color(0x55000000), blurRadius: 8),
          ],
        ),
        child: const Icon(Icons.recycling_rounded,
            size: 22, color: Colors.white),
      ),
    );
  }
}

class _ListTab extends StatelessWidget {
  const _ListTab({
    required this.bins,
    required this.location,
    required this.mapFailed,
  });

  final List<SmartBin> bins;
  final LocationState? location;
  final bool mapFailed;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(Sp.gutter, 0, Sp.gutter, 120),
      itemCount: bins.length + (mapFailed ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: Sp.xs),
      itemBuilder: (context, i) {
        if (mapFailed && i == 0) {
          return EpCard(
            color: context.ep.surfaceRaised,
            child: Text(context.tr('bins_map_error'),
                style: context.text.bodyMedium),
          );
        }
        final bin = bins[i - (mapFailed ? 1 : 0)];
        return BinTile(
          bin: bin,
          online: bin.isOnline(now),
          distanceMeters: location?.distanceTo(bin),
          onTap: () => showBinDetail(context, bin),
        );
      },
    );
  }
}

class BinTile extends StatelessWidget {
  const BinTile({
    super.key,
    required this.bin,
    required this.online,
    required this.onTap,
    this.distanceMeters,
  });

  final SmartBin bin;
  final bool online;
  final double? distanceMeters;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ep;
    final tone = fillColor(c, bin.fillPercent);
    return EpCard(
      onTap: onTap,
      semanticLabel:
          '${bin.name}, ${context.tr('bins_fill')} ${bin.fillPercent}%',
      child: Row(
        children: [
          IconTile(icon: Icons.recycling_rounded, color: tone),
          const SizedBox(width: Sp.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bin.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.titleSmall),
                if (bin.locationText.isNotEmpty)
                  Text(bin.locationText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodySmall),
                const SizedBox(height: 6),
                EpProgressBar(
                    value: bin.fillPercent / 100, color: tone, height: 6),
                const SizedBox(height: 6),
                Row(
                  children: [
                    EpBadge(
                      label: online
                          ? context.tr('bins_online')
                          : context.tr('bins_offline'),
                      color: online ? c.emerald : c.textTertiary,
                    ),
                    if (distanceMeters != null) ...[
                      const SizedBox(width: Sp.xs),
                      Text(
                        context.tr('bins_distance',
                            {'d': Fmt.distance(distanceMeters!)}),
                        style: context.text.bodySmall,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: Sp.sm),
          Text('${bin.fillPercent}%',
              style: context.text.titleMedium?.copyWith(color: tone)),
        ],
      ),
    );
  }
}
