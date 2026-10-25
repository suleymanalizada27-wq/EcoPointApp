import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/localization/app_localizations.dart';
import '../../app/theme/ep_colors.dart';
import '../../app/theme/tokens.dart';
import '../errors/failure.dart';
import '../services/firebase_providers.dart';
import 'ep_button.dart';

/// Centered spinner for full-section loading.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.label});
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Sp.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.6,
                color: context.ep.emerald,
              ),
            ),
            if (label != null) ...[
              const SizedBox(height: Sp.md),
              Text(label!, style: context.text.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shimmer-free skeleton block (a calm pulsing placeholder).
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({super.key, this.height = 16, this.width, this.radius = 10});
  final double height;
  final double? width;
  final double radius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ep;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            color: Color.lerp(c.surfaceRaised, c.outline, _ctrl.value),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        );
      },
    );
  }
}

/// Friendly empty state with optional action.
class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.icon,
    required this.message,
    this.title,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.ep;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Sp.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: c.emerald.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: c.emerald),
            ),
            const SizedBox(height: Sp.md),
            Text(
              title ?? context.tr('empty_title'),
              style: context.text.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Sp.xxs),
            Text(
              message,
              style: context.text.bodyMedium?.copyWith(color: c.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: Sp.lg),
              EpButton(
                label: actionLabel!,
                onPressed: onAction,
                expand: false,
                kind: EpButtonKind.secondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Error state with retry. Accepts any thrown object.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, this.onRetry});
  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.ep;
    final failure = Failure.from(error);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Sp.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: c.danger.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.cloud_off_rounded, size: 32, color: c.danger),
            ),
            const SizedBox(height: Sp.md),
            Text(
              context.tr(failure.l10nKey),
              style: context.text.bodyLarge,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: Sp.lg),
              EpButton(
                label: context.tr('retry'),
                icon: Icons.refresh_rounded,
                onPressed: onRetry,
                expand: false,
                kind: EpButtonKind.secondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Renders the four states of an [AsyncValue] consistently.
class AsyncBody<T> extends StatelessWidget {
  const AsyncBody({
    super.key,
    required this.value,
    required this.data,
    this.onRetry,
    this.loading,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;
  final Widget? loading;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      loading: () => loading ?? const LoadingView(),
      error: (e, _) => ErrorView(error: e, onRetry: onRetry),
    );
  }
}

/// Slim banner shown while the Realtime Database socket is disconnected.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(connectionProvider).valueOrNull ?? true;
    final c = context.ep;
    return AnimatedSize(
      duration: Motion.base,
      curve: Motion.curve,
      child: online
          ? const SizedBox(width: double.infinity)
          : Semantics(
              liveRegion: true,
              child: Container(
                width: double.infinity,
                color: c.warning.withValues(alpha: 0.16),
                padding: const EdgeInsets.symmetric(
                  horizontal: Sp.gutter,
                  vertical: Sp.xs,
                ),
                child: Row(
                  children: [
                    Icon(Icons.wifi_off_rounded, size: 16, color: c.warning),
                    const SizedBox(width: Sp.xs),
                    Expanded(
                      child: Text(
                        context.tr('offline_banner'),
                        style: context.text.bodySmall
                            ?.copyWith(color: c.warning),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
