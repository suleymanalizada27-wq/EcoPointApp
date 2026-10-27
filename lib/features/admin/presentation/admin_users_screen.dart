import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/widgets/ep_button.dart';
import '../../../core/widgets/ep_card.dart';
import '../../../core/widgets/ep_feedback.dart';
import '../../../core/widgets/ep_text_field.dart';
import '../data/admin_api.dart';
import 'admin_common.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});
  @override
  ConsumerState<AdminUsersScreen> createState() => _State();
}

class _State extends ConsumerState<AdminUsersScreen> {
  final _q = TextEditingController();
  List<Map<String, Object?>> _rows = const [];
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final r = await ref.read(adminApiProvider).searchUsers(_q.text.trim());
      if (mounted) setState(() => _rows = r);
    } catch (e) {
      if (mounted) setState(() => _error = adminErrorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('İstifadəçilər')),
      body: ListView(padding: adminPad, children: [
        EpTextField(
          label: 'Ad (ən azı 2 hərf) və ya UID',
          controller: _q,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _search(),
        ),
        const SizedBox(height: Sp.sm),
        EpButton(label: 'Axtar', onPressed: _search, loading: _busy),
        if (_error != null) Padding(
          padding: const EdgeInsets.only(top: Sp.sm),
          child: Text(_error!),
        ),
        const SizedBox(height: Sp.md),
        for (final u in _rows) ...[
          EpCard(
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => AdminUserDetailScreen(uid: '${u['uid']}'),
            )),
            child: Row(children: [
              Expanded(child: Text('${u['name']}')),
              Text('${u['ep']} EP'),
            ]),
          ),
          const SizedBox(height: Sp.sm),
        ],
      ]),
    );
  }
}

class AdminUserDetailScreen extends ConsumerStatefulWidget {
  const AdminUserDetailScreen({super.key, required this.uid});
  final String uid;
  @override
  ConsumerState<AdminUserDetailScreen> createState() => _DetailState();
}

class _DetailState extends ConsumerState<AdminUserDetailScreen> {
  Map<String, Object?>? _u;
  String? _error;
  final _delta = TextEditingController();
  final _reason = TextEditingController();
  final _days = TextEditingController(text: '30');

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _delta.dispose();
    _reason.dispose();
    _days.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final u = await ref.read(adminApiProvider).getUser(widget.uid);
      if (mounted) setState(() => _u = u);
    } catch (e) {
      if (mounted) setState(() => _error = adminErrorText(e));
    }
  }

  Future<void> _adjust() async {
    final d = int.tryParse(_delta.text.trim());
    if (d == null || d == 0) {
      showEpToast(context, 'EP məbləği düzgün deyil', kind: ToastKind.error);
      return;
    }
    final ok = await confirmSheet(context,
        title: 'Balansı dəyiş',
        body: '${d > 0 ? '+' : ''}$d EP tətbiq olunsun?',
        confirmLabel: 'Təsdiq et');
    if (!ok || !mounted) return;
    final done = await runAdmin(
        context,
        () => ref
            .read(adminApiProvider)
            .adjustBalance(widget.uid, d, _reason.text.trim()));
    if (done) {
      _delta.clear();
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = _u;
    return Scaffold(
      appBar: AppBar(title: const Text('İstifadəçi')),
      body: u == null
          ? Center(
              child: _error == null
                  ? const CircularProgressIndicator()
                  : Padding(
                      padding: adminPad, child: Text(_error!)))
          : ListView(padding: adminPad, children: [
              EpCard(
                child: Column(children: [
                  AdminLine('Ad', '${u['name']}'),
                  AdminLine('E-poçt', '${u['email']}'),
                  AdminLine('UID', widget.uid),
                  AdminLine('Balans', '${u['balance']} EP'),
                  AdminLine('Qazanılıb', '${u['earned']} EP'),
                  AdminLine('Xərclənib', '${u['spent']} EP'),
                  AdminLine('Dəvətlər', '${u['referralCount']}'),
                  AdminLine('Qeydiyyat', fmtTs(u['createdAt'])),
                  AdminLine('Pro',
                      u['isPro'] == true ? 'Bəli (${fmtTs(u['proExpiry'])})' : 'Xeyr'),
                  AdminLine('Bloklu', u['banned'] == true ? 'BƏLİ' : 'Xeyr'),
                ]),
              ),
              const SizedBox(height: Sp.md),
              EpTextField(
                label: 'EP dəyişikliyi (məs. 100 və ya -50)',
                controller: _delta,
                keyboardType: const TextInputType.numberWithOptions(signed: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[-0-9]'))],
              ),
              const SizedBox(height: Sp.sm),
              EpTextField(label: 'Səbəb', controller: _reason),
              const SizedBox(height: Sp.sm),
              EpButton(label: 'Balansı dəyiş', onPressed: _adjust),
              const SizedBox(height: Sp.lg),
              EpButton(
                label: u['banned'] == true ? 'Bloku aç' : 'Blokla',
                kind: u['banned'] == true ? EpButtonKind.secondary : EpButtonKind.danger,
                onPressed: () async {
                  final ban = u['banned'] != true;
                  final ok = await confirmSheet(context,
                      title: ban ? 'Blokla' : 'Bloku aç',
                      body: 'Əminsiniz?',
                      confirmLabel: 'Bəli',
                      destructive: ban);
                  if (!ok || !context.mounted) return;
                  final done = await runAdmin(
                      context,
                      () => ref
                          .read(adminApiProvider)
                          .setBan(widget.uid, ban, _reason.text.trim()));
                  if (done) await _load();
                },
              ),
              const SizedBox(height: Sp.lg),
              EpTextField(
                label: 'Pro müddəti (gün, 0 = ləğv)',
                controller: _days,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: Sp.sm),
              EpButton(
                label: 'Pro təyin et',
                kind: EpButtonKind.secondary,
                onPressed: () async {
                  final d = int.tryParse(_days.text.trim());
                  if (d == null) return;
                  final done = await runAdmin(context,
                      () => ref.read(adminApiProvider).setPro(widget.uid, d));
                  if (done) await _load();
                },
              ),
            ]),
    );
  }
}
