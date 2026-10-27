import 'package:flutter/material.dart';

import '../../../app/theme/ep_colors.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/widgets/ep_feedback.dart';
import '../data/admin_api.dart';

/// Runs an admin action, shows a toast, returns true on success.
Future<bool> runAdmin(
  BuildContext context,
  Future<void> Function() action, {
  String ok = 'Hazırdır',
}) async {
  try {
    await action();
    if (context.mounted) showEpToast(context, ok, kind: ToastKind.success);
    return true;
  } catch (e) {
    if (context.mounted) {
      showEpToast(context, adminErrorText(e), kind: ToastKind.error);
    }
    return false;
  }
}

String fmtTs(Object? ms) {
  final n = ms is num ? ms.toInt() : int.tryParse('$ms') ?? 0;
  if (n <= 0) return '—';
  final d = DateTime.fromMillisecondsSinceEpoch(n);
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(d.day)}.${two(d.month)}.${d.year} ${two(d.hour)}:${two(d.minute)}';
}

class AdminLine extends StatelessWidget {
  const AdminLine(this.label, this.value, {super.key});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.ep;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: TextStyle(color: c.textSecondary)),
          ),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }
}

const adminPad = EdgeInsets.all(Sp.gutter);
