import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/ep_colors.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/errors/failure.dart';
import '../../../core/widgets/ep_button.dart';
import '../../../core/widgets/ep_feedback.dart';
import '../data/bins_repository.dart';
import '../domain/smart_bin.dart';

Future<void> showBinReportSheet(BuildContext context, SmartBin bin) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _ReportSheet(bin: bin),
  );
}

class _ReportSheet extends ConsumerStatefulWidget {
  const _ReportSheet({required this.bin});
  final SmartBin bin;

  @override
  ConsumerState<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<_ReportSheet> {
  static const _kinds = ['broken', 'full', 'dirty', 'other'];
  String _kind = 'broken';
  final _note = TextEditingController();
  String? _photo; // base64 JPEG, already shrunk
  bool _busy = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final x = await ImagePicker().pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 55,
      );
      if (x == null) return;
      final bytes = await x.readAsBytes();
      if (!mounted) return;
      setState(() => _photo = base64Encode(bytes));
    } catch (_) {
      if (mounted) {
        showEpToast(context, context.tr('report_photo_failed'),
            kind: ToastKind.error);
      }
    }
  }

  Future<void> _send() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(binsRepositoryProvider).report(
            binId: widget.bin.id,
            kind: _kind,
            note: _note.text.trim(),
            photoBase64: _photo,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      showEpToast(context, context.tr('report_sent'), kind: ToastKind.success);
    } on Failure catch (f) {
      if (!mounted) return;
      final key = f.code == Failure.duplicate ? 'report_already' : f.l10nKey;
      showEpToast(context, context.tr(key), kind: ToastKind.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ep;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          Sp.gutter,
          0,
          Sp.gutter,
          Sp.lg + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(context.tr('report_title'), style: context.text.titleLarge),
              const SizedBox(height: 2),
              Text(widget.bin.name,
                  style:
                      context.text.bodyMedium?.copyWith(color: c.textSecondary)),
              const SizedBox(height: Sp.md),
              Wrap(
                spacing: Sp.xs,
                runSpacing: Sp.xs,
                children: [
                  for (final k in _kinds)
                    ChoiceChip(
                      label: Text(context.tr('report_kind_$k')),
                      selected: _kind == k,
                      onSelected: (_) => setState(() => _kind = k),
                    ),
                ],
              ),
              const SizedBox(height: Sp.md),
              TextField(
                controller: _note,
                maxLength: 200,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: context.tr('report_note_hint'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: Sp.xs),
              if (_photo != null)
                Stack(
                  alignment: AlignmentDirectional.topEnd,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        base64Decode(_photo!),
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    IconButton.filled(
                      tooltip: context.tr('report_remove_photo'),
                      onPressed: () => setState(() => _photo = null),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pick(ImageSource.camera),
                        icon: const Icon(Icons.photo_camera_rounded),
                        label: Text(context.tr('report_photo_camera')),
                      ),
                    ),
                    const SizedBox(width: Sp.xs),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pick(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_rounded),
                        label: Text(context.tr('report_photo_gallery')),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: Sp.lg),
              EpButton(
                label: context.tr('report_send'),
                icon: Icons.send_rounded,
                loading: _busy,
                onPressed: _send,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
