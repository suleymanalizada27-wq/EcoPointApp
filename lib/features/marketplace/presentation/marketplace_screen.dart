import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/ep_colors.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/services/firebase_providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/ep_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../wallet/data/wallet_providers.dart';
import '../data/marketplace_repository.dart';
import '../domain/reward.dart';
import 'reward_sheets.dart';

String categoryLabelKey(RewardCategory c) => switch (c) {
      RewardCategory.food => 'cat_food',
      RewardCategory.tech => 'cat_tech',
      RewardCategory.eco => 'cat_eco',
      RewardCategory.service => 'cat_service',
    };

class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> {
  RewardCategory? _category;
  String _query = '';

  List<Reward> _filter(List<Reward> all, String lang) {
    final q = _query.trim().toLowerCase();
    return all.where((r) {
      if (_category != null && r.category != _category) return false;
      if (q.isEmpty) return true;
      return r.nameFor(lang).toLowerCase().contains(q) ||
          r.brand.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ep;
    final rewards = ref.watch(rewardsProvider);
    final balance = ref.watch(balanceProvider).valueOrNull ?? 0;
    final lang = Localizations.localeOf(context).languageCode;

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  Sp.gutter, Sp.md, Sp.gutter, Sp.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(context.tr('market_title'),
                              style: context.text.headlineMedium),
                        ),
                        const SizedBox(height: 2),
                        Text(context.tr('market_sub'),
                            style: context.text.bodyMedium
                                ?.copyWith(color: c.textSecondary)),
                      ],
                    ),
                  ),
                  _BalanceChip(balance: balance),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: Sp.gutter, vertical: Sp.sm),
              child: _SearchField(
                hint: context.tr('market_search'),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: Sp.gutter),
                children: [
                  _CategoryChip(
                    label: context.tr('cat_all'),
                    selected: _category == null,
                    onTap: () => setState(() => _category = null),
                  ),
                  for (final cat in RewardCategory.values)
                    _CategoryChip(
                      label: context.tr(categoryLabelKey(cat)),
                      selected: _category == cat,
                      onTap: () => setState(() => _category = cat),
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => context.push('/purchases'),
                icon: const Icon(Icons.receipt_long_rounded, size: 18),
                label: Text(context.tr('reward_history')),
                style: TextButton.styleFrom(foregroundColor: c.emerald),
              ),
            ),
          ),
          rewards.when(
            loading: () => const SliverFillRemaining(
              hasScrollBody: false,
              child: LoadingView(),
            ),
            error: (e, _) => SliverFillRemaining(
              hasScrollBody: false,
              child: ErrorView(
                error: e,
                onRetry: () => ref.invalidate(rewardsProvider),
              ),
            ),
            data: (list) {
              final items = _filter(list.items, lang);
              return SliverMainAxisGroup(
                slivers: [
                  if (list.isFallback)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                            Sp.gutter, 0, Sp.gutter, Sp.sm),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded,
                                size: 16, color: c.textTertiary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                context.tr('market_catalog_local'),
                                style: context.text.bodySmall
                                    ?.copyWith(color: c.textTertiary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (items.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyView(
                        icon: Icons.search_off_rounded,
                        message: context.tr('market_empty'),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                          Sp.gutter, 0, Sp.gutter, 120),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 260,
                          mainAxisSpacing: Sp.sm,
                          crossAxisSpacing: Sp.sm,
                          mainAxisExtent: 196,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, i) => RewardCard(
                            reward: items[i],
                            balance: balance,
                            onTap: () => openRewardFlow(context, items[i]),
                          ),
                          childCount: items.length,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Opens the right sheet for the reward kind (item / coupon / transport).
void openRewardFlow(BuildContext context, Reward reward) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) {
      switch (reward.kind) {
        case RewardKind.coupon:
          return CouponSheet(reward: reward);
        case RewardKind.transport:
          return TransportSheet(reward: reward);
        case RewardKind.item:
          return RewardSheet(reward: reward);
      }
    },
  );
}

class RewardCard extends ConsumerWidget {
  const RewardCard({
    super.key,
    required this.reward,
    required this.balance,
    required this.onTap,
    this.compact = false,
  });

  final Reward reward;
  final int balance;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.ep;
    final lang = Localizations.localeOf(context).languageCode;
    final signedIn = ref.watch(uidProvider) != null;
    final affordable = !signedIn || balance >= reward.ep;
    final name = reward.nameFor(lang);

    return EpCard(
      onTap: reward.inStock ? onTap : null,
      padding: const EdgeInsets.all(Sp.sm),
      semanticLabel:
          '$name, ${reward.brand}, ${Fmt.number(reward.ep)} ${context.tr('ep_unit')}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Rad.md),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    c.emerald.withValues(alpha: 0.20),
                    c.emeraldDeep.withValues(alpha: 0.10),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(reward.icon, size: 44, color: c.emerald),
                  ),
                  if (!reward.inStock)
                    Positioned(
                      left: 6,
                      top: 6,
                      child: EpBadge(
                        label: context.tr('reward_out_of_stock'),
                        color: c.danger,
                      ),
                    ),
                  if (reward.kind != RewardKind.item)
                    Positioned(
                      left: 6,
                      top: 6,
                      child: EpBadge(
                        label: context.tr('reward_partner'),
                        color: c.info,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Sp.xs),
          Text(name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.titleSmall),
          Text(reward.brand,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodySmall),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '${Fmt.number(reward.ep)} ${context.tr('ep_unit')}',
                style: context.text.titleSmall?.copyWith(
                  color: affordable ? c.emerald : c.textTertiary,
                ),
              ),
              const Spacer(),
              if (!affordable)
                Icon(Icons.lock_outline_rounded,
                    size: 16, color: c.textTertiary),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalanceChip extends StatelessWidget {
  const _BalanceChip({required this.balance});
  final int balance;

  @override
  Widget build(BuildContext context) {
    final c = context.ep;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: c.lime.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(Rad.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_rounded, size: 16, color: c.lime),
          const SizedBox(width: 4),
          Text(
            Fmt.number(balance),
            style: context.text.titleSmall?.copyWith(color: c.lime),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.hint, required this.onChanged});
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.ep;
    return TextField(
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: context.text.bodyLarge,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: context.text.bodyMedium?.copyWith(color: c.textTertiary),
        prefixIcon: Icon(Icons.search_rounded, color: c.textSecondary),
        filled: true,
        fillColor: c.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Rad.pill),
          borderSide: BorderSide(color: c.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Rad.pill),
          borderSide: BorderSide(color: c.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Rad.pill),
          borderSide: BorderSide(color: c.emerald, width: 1.6),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ep;
    return Padding(
      padding: const EdgeInsets.only(right: Sp.xs),
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        excludeSemantics: true,
        child: Material(
          color: selected ? c.emerald : c.surface,
          shape: StadiumBorder(
            side: BorderSide(color: selected ? c.emerald : c.outline),
          ),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  label,
                  style: context.text.labelMedium?.copyWith(
                    color: selected
                        ? (Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF04140D)
                            : Colors.white)
                        : c.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
