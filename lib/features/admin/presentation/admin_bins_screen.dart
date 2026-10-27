import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/widgets/ep_button.dart';
import '../../../core/widgets/ep_card.dart';
import '../../../core/widgets/ep_feedback.dart';
import '../../../core/widgets/ep_text_field.dart';
import '../../../core/widgets/state_views.dart';
import '../../smart_bins/data/bins_repository.dart';
import '../../smart_bins/domain/smart_bin.dart';
import '../data/admin_api.dart';
import 'admin_common.dart';

class AdminBinsScreen extends ConsumerWidget {
  const AdminBinsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bins = ref.watch(binsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Qutular və QR')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _open(context, null),
        child: const Icon(Icons.add_rounded),
      ),
      body: AsyncBody<List<SmartBin>>(
        value: bins,
        onRetry: () => ref.invalidate(binsProvider),
        data: (list) => ListView(padding: adminPad, children: [
          if (list.isEmpty) const Text('Hələ qutu yoxdur.'),
          for (final b in list) ...[
            EpCard(
              onTap: () => _open(context, b),
              child: Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(b.name),
                      Text('${b.id} · ${b.locationText}'
                          '${b.hasCoordinates ? '' : ' · koordinat yoxdur'}'),
                    ],
                  ),
                ),
                const Icon(Icons.edit_rounded, size: 18),
              ]),
            ),
            const SizedBox(height: Sp.sm),
          ],
        ]),
      ),
    );
  }

  void _open(BuildContext context, SmartBin? b) => Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => _BinForm(bin: b)));
}

class _BinForm extends ConsumerStatefulWidget {
  const _BinForm({this.bin});
  final SmartBin? bin;
  @override
  ConsumerState<_BinForm> createState() => _BinState();
}

class _BinState extends ConsumerState<_BinForm> {
  late final _id = TextEditingController(text: widget.bin?.id ?? '');
  late final _name = TextEditingController(text: widget.bin?.name ?? '');
  late final _loc = TextEditingController(text: widget.bin?.locationText ?? '');
  late final _lat = TextEditingController(text: widget.bin?.lat?.toString() ?? '');
  late final _lng = TextEditingController(text: widget.bin?.lng?.toString() ?? '');
  String? _code;
  int? _expires;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_id, _name, _loc, _lat, _lng]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final latT = _lat.text.trim().replaceAll(',', '.');
    final lngT = _lng.text.trim().replaceAll(',', '.');
    final lat = double.tryParse(latT);
    final lng = double.tryParse(lngT);
    if ((latT.isNotEmpty || lngT.isNotEmpty) && (lat == null || lng == null)) {
      showEpToast(context, 'Koordinat düzgün deyil', kind: ToastKind.error);
      return;
    }
    setState(() => _busy = true);
    final ok = await runAdmin(
      context,
      () => ref.read(adminApiProvider).upsertDevice({
        'id': _id.text.trim(),
        'name': _name.text.trim(),
        'location': _loc.text.trim(),
        if (lat != null && lng != null) 'lat': lat,
        if (lat != null && lng != null) 'lng': lng,
      }),
    );
    if (mounted) setState(() => _busy = false);
    if (ok) ref.invalidate(binsProvider);
  }

  Future<void> _issue() async {
    final id = _id.text.trim();
    if (id.isEmpty) {
      showEpToast(context, 'Əvvəl qutunun ID-sini yazın', kind: ToastKind.error);
      return;
    }
    try {
      final r = await ref.read(adminApiProvider).issueBinCode(id, 3600);
      if (!mounted) return;
      setState(() {
        _code = '${r['code']}';
        _expires = (r['expiresAt'] as num?)?.toInt();
      });
    } catch (e) {
      if (mounted) showEpToast(context, adminErrorText(e), kind: ToastKind.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.bin == null;
    return Scaffold(
      appBar: AppBar(title: Text(isNew ? 'Yeni qutu' : 'Qutu')),
      body: ListView(padding: adminPad, children: [
        EpTextField(label: 'Qutu ID', controller: _id, enabled: isNew),
        const SizedBox(height: Sp.sm),
        EpTextField(label: 'Ad', controller: _name),
        const SizedBox(height: Sp.sm),
        EpTextField(label: 'Ünvan / yer', controller: _loc),
        const SizedBox(height: Sp.sm),
        EpTextField(
          label: 'Enlik (lat), məs. 40.4093',
          controller: _lat,
          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
        ),
        const SizedBox(height: Sp.sm),
        EpTextField(
          label: 'Uzunluq (lng), məs. 49.8671',
          controller: _lng,
          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
        ),
        const SizedBox(height: Sp.md),
        EpButton(label: 'Yadda saxla', onPressed: _save, loading: _busy),
        const SizedBox(height: Sp.lg),
        EpButton(
          label: 'İmzalı QR kod yarat (1 saat)',
          kind: EpButtonKind.secondary,
          onPressed: _issue,
        ),
        if (_code != null) ...[
          const SizedBox(height: Sp.md),
          Center(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(Sp.md),
              child: QrImageView(data: _code!, size: 220),
            ),
          ),
          const SizedBox(height: Sp.sm),
          SelectableText(_code!, textAlign: TextAlign.center),
          Text('Bitir: ${fmtTs((_expires ?? 0) * 1000)}',
              textAlign: TextAlign.center),
        ],
      ]),
    );
  }
}
