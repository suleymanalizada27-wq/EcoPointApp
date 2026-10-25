import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/ep_colors.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/services/preferences.dart';
import '../../../core/widgets/ep_button.dart';
import 'auth_widgets.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pager = PageController();
  int _page = 0;

  static const _icons = [
    Icons.recycling_rounded,
    Icons.card_giftcard_rounded,
    Icons.insights_rounded,
  ];

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  Future<void> _finish({required bool toSignUp}) async {
    await ref.read(onboardedProvider.notifier).complete();
    if (!mounted) return;
    context.go(toSignUp ? '/sign-up' : '/sign-in');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ep;
    final last = _page == 2;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Sp.gutter, Sp.sm, Sp.xs, 0),
              child: Row(
                children: [
                  const BrandMark(size: 36),
                  const Spacer(),
                  AnimatedOpacity(
                    duration: Motion.fast,
                    opacity: last ? 0 : 1,
                    child: TextButton(
                      onPressed: last ? null : () => _finish(toSignUp: false),
                      child: Text(context.tr('skip')),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pager,
                itemCount: 3,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) => _Slide(
                  icon: _icons[i],
                  title: context.tr('onb_${i + 1}_title'),
                  body: context.tr('onb_${i + 1}_body'),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                final active = i == _page;
                return AnimatedContainer(
                  duration: Motion.base,
                  curve: Motion.curve,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 26 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active ? c.emerald : c.outline,
                    borderRadius: BorderRadius.circular(Rad.pill),
                  ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.all(Sp.gutter),
              child: Column(
                children: [
                  EpButton(
                    label: last
                        ? context.tr('onb_get_started')
                        : context.tr('next'),
                    onPressed: () {
                      if (last) {
                        _finish(toSignUp: true);
                      } else {
                        _pager.nextPage(
                          duration: Motion.base,
                          curve: Motion.curve,
                        );
                      }
                    },
                  ),
                  SizedBox(
                    height: 56,
                    child: last
                        ? Center(
                            child: TextButton(
                              onPressed: () => _finish(toSignUp: false),
                              child: Text(context.tr('onb_have_account')),
                            ),
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final c = context.ep;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Sp.gutter),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 168,
            height: 168,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: c.heroGradient,
              ),
              boxShadow: [
                BoxShadow(
                  color: c.emerald.withValues(alpha: 0.28),
                  blurRadius: 48,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Icon(icon, size: 76, color: c.lime),
          ),
          const SizedBox(height: Sp.xxl),
          Semantics(
            header: true,
            child: Text(title, style: context.text.displayMedium),
          ),
          const SizedBox(height: Sp.sm),
          Text(
            body,
            style: context.text.bodyLarge?.copyWith(color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}
