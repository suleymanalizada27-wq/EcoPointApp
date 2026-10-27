import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/widgets/ep_button.dart';
import '../../../core/widgets/ep_card.dart';
import '../../../core/widgets/ep_feedback.dart';
import '../../../core/widgets/ep_text_field.dart';
import '../../../core/widgets/state_views.dart';
import '../../marketplace/data/marketplace_repository.dart';
import '../../marketplace/domain/reward.dart';
import '../data/admin_api.dart';
import 'admin_common.dart';

class AdminRewardsScreen extends ConsumerWidget {
  const AdminRewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(rewardsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Mükafatlar')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _edit(context, null),
        child: const Icon(Icons.add_rounded),
      ),
      body: AsyncBody<RewardList>(
        value: list,
        onRetry: () => ref.invalidate(rewardsProvider),
        data: (data) => ListView(padding: adminPad, children: [
          if (data.isFallback)
            const Padding(
              padding: EdgeInsets.only(bottom: Sp.md),
              child: Text('Bazada mükafat yoxdur — tətbiq standart siyahını '
                  'göstərir. Yeni əlavə etdikdə bazadakı siyahı istifadə olunur.'),
            ),
          for (final r in data.items) ...[
            EpCard(
              onTap: () => _edit(context, r),
              child: Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.nameFor('az')),
                      Text('${r.id} · ${r.brand} · ${r.ep} EP'
                          '${r.stock != null ? ' · stok ${r.stock}' : ''}'
                          '${r.active ? '' : ' · GİZLİ'}'),
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

  void _edit(BuildContext context, Reward? r) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => _RewardForm(reward: r),
    ));
  }
}

class _RewardForm extends ConsumerStatefulWidget {
  const _RewardForm({this.reward});
  final Reward? reward;
  @override
  ConsumerState<_RewardForm> createState() => _FormState();
}

class _FormState extends ConsumerState<_RewardForm> {
  late final _id = TextEditingController(text: widget.reward?.id ?? '');
  late final _az = TextEditingController(text: widget.reward?.names['az'] ?? '');
  late final _en = TextEditingController(text: widget.reward?.names['en'] ?? '');
  late final _ru = TextEditingController(text: widget.reward?.names['ru'] ?? '');
  late final _tr = TextEditingController(text: widget.reward?.names['tr'] ?? '');
  late final _brand = TextEditingController(text: widget.reward?.brand ?? '');
  late final _ep = TextEditingController(text: widget.reward?.ep.toString() ?? '');
  late final _stock = TextEditingController(text: widget.reward?.stock?.toString() ?? '');
  late String _cat = _catName(widget.reward?.category ?? RewardCategory.service);
  late bool _active = widget.reward?.active ?? true;
  bool _busy = false;

  static String _catName(RewardCategory c) => c.name;

  @override
  void dispose() {
    for (final c in [_id, _az, _en, _ru, _tr, _brand, _ep, _stock]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final ep = int.tryParse(_ep.text.trim());
    if (ep == null || ep < 1) {
      showEpToast(context, 'Qiymət düzgün deyil', kind: ToastKind.error);
      return;
    }
    final stockText = _stock.text.trim();
    final data = <String, Object?>{
      'id': _id.text.trim(),
      'name': {
        'az': _az.text.trim(),
        'en': _en.text.trim(),
        'ru': _ru.text.trim(),
        'tr': _tr.text.trim(),
      },
      'brand': _brand.text.trim(),
      'ep': ep,
      'cat': _cat,
      'icon': widget.reward?.iconKey ?? '',
      'active': _active,
      if (stockText.isNotEmpty) 'stock': int.tryParse(stockText),
    };
    setState(() => _busy = true);
    final ok = await runAdmin(
        context, () => ref.read(adminApiProvider).upsertReward(data));
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final yes = await confirmSheet(context,
        title: 'Sil',
        body: 'Mükafat silinsin?',
        confirmLabel: 'Sil',
        destructive: true);
    if (!yes || !mounted) return;
    final ok = await runAdmin(context,
        () => ref.read(adminApiProvider).deleteReward(_id.text.trim()));
    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.reward == null;
    return Scaffold(
      appBar: AppBar(title: Text(isNew ? 'Yeni mükafat' : 'Mükafatı redaktə et')),
      body: ListView(padding: adminPad, children: [
        EpTextField(
          label: 'ID (latın hərf/rəqəm, məs. coffee1)',
          controller: _id,
          enabled: isNew,
        ),
        const SizedBox(height: Sp.sm),
        EpTextField(label: 'Ad (AZ) *', controller: _az),
        const SizedBox(height: Sp.sm),
        EpTextField(label: 'Ad (EN)', controller: _en),
        const SizedBox(height: Sp.sm),
        EpTextField(label: 'Ad (RU)', controller: _ru),
        const SizedBox(height: Sp.sm),
        EpTextField(label: 'Ad (TR)', controller: _tr),
        const SizedBox(height: Sp.sm),
        EpTextField(label: 'Brend', controller: _brand),
        const SizedBox(height: Sp.sm),
        EpTextField(
          label: 'Qiymət (EP)',
          controller: _ep,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: Sp.sm),
        EpTextField(
          label: 'Stok (boş = limitsiz)',
          controller: _stock,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: Sp.sm),
        DropdownButtonFormField<String>(
          value: _cat,
          decoration: const InputDecoration(labelText: 'Kateqoriya'),
          items: const [
            DropdownMenuItem(value: 'food', child: Text('Yemək')),
            DropdownMenuItem(value: 'tech', child: Text('Texnika')),
            DropdownMenuItem(value: 'eco', child: Text('Eko')),
            DropdownMenuItem(value: 'service', child: Text('Xidmət')),
          ],
          onChanged: (v) => setState(() => _cat = v ?? _cat),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Aktiv (görünür)'),
          value: _active,
          onChanged: (v) => setState(() => _active = v),
        ),
        const SizedBox(height: Sp.md),
        EpButton(label: 'Yadda saxla', onPressed: _save, loading: _busy),
        if (!isNew) ...[
          const SizedBox(height: Sp.sm),
          EpButton(label: 'Sil', kind: EpButtonKind.danger, onPressed: _delete),
        ],
      ]),
    );
  }
}
