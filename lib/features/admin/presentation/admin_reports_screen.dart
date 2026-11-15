import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/widgets/ep_button.dart';
import '../../../core/widgets/ep_card.dart';
import '../../../core/widgets/state_views.dart';
import '../data/admin_api.dart';
import 'admin_common.dart';

final adminReportsProvider =
    FutureProvider.autoDispose<List<Map<String, Object?>>>(
        (ref) => ref.watch(adminApiProvider).reports());

const _kindLabel = {
  'broken': 'İşləmir',
  'full': 'Dolub',
  'dirty': 'Çirklidir',
  'other': 'Başqa',
};

/// Open problem reports from people (with an optional photo).
class AdminReportsScreen extends ConsumerWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(adminReportsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Qutu problemləri')),
      body: AsyncBody<List<Map<String, Object?>>>(
        value: list,
        onRetry: () => ref.invalidate(adminReportsProvider),
        data: (rows) {
          if (rows.isEmpty) {
            return const EmptyView(
                icon: Icons.check_circle_outline_rounded,
                message: 'Açıq problem yoxdur.');
          }
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(adminReportsProvider.future),
            child: ListView(padding: adminPad, children: [
              for (final r in rows) ...[
                EpCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AdminLine('Qutu', '${r['binId']}'),
                      AdminLine('Növ', _kindLabel['${r['kind']}'] ?? '${r['kind']}'),
                      if ('${r['note'] ?? ''}'.isNotEmpty)
                        AdminLine('Qeyd', '${r['note']}'),
                      AdminLine('İstifadəçi', '${r['uid']}'),
                      AdminLine('Vaxt', fmtTs(r['ts'])),
                      if (r['hasPhoto'] == true) _Photo(id: '${r['id']}'),
                      const SizedBox(height: Sp.sm),
                      Row(children: [
                        Expanded(
                          child: EpButton(
                            label: 'Həll olundu',
                            kind: EpButtonKind.secondary,
                            onPressed: () => _resolve(context, ref, r, false),
                          ),
                        ),
                        const SizedBox(width: Sp.sm),
                        Expanded(
                          child: EpButton(
                            label: 'Həll + işləyir',
                            onPressed: () => _resolve(context, ref, r, true),
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: Sp.sm),
              ],
            ]),
          );
        },
      ),
    );
  }

  Future<void> _resolve(BuildContext context, WidgetRef ref,
      Map<String, Object?> r, bool clear) async {
    final ok = await runAdmin(
      context,
      () => ref
          .read(adminApiProvider)
          .resolveReport('${r['id']}', clearProblem: clear),
    );
    if (ok) ref.invalidate(adminReportsProvider);
  }
}

class _Photo extends ConsumerStatefulWidget {
  const _Photo({required this.id});
  final String id;

  @override
  ConsumerState<_Photo> createState() => _PhotoState();
}

class _PhotoState extends ConsumerState<_Photo> {
  String? _b64;
  bool _loading = false;
  bool _tried = false;

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final p = await ref.read(adminApiProvider).reportPhoto(widget.id);
      if (mounted) setState(() => _b64 = p);
    } catch (_) {
      // shown as "no photo"
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _tried = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_b64 != null) {
      return Padding(
        padding: const EdgeInsets.only(top: Sp.xs),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(base64Decode(_b64!),
              height: 200, width: double.infinity, fit: BoxFit.cover),
        ),
      );
    }
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: TextButton.icon(
        onPressed: _loading ? null : _load,
        icon: const Icon(Icons.photo_rounded),
        label: Text(_tried ? 'Şəkil tapılmadı' : 'Şəkli göstər'),
      ),
    );
  }
}
