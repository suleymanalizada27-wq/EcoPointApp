import 'package:flutter/material.dart';

import '../../../core/utils/json_utils.dart';

enum RewardCategory { food, tech, eco, service }

enum RewardKind { item, coupon, transport }

/// A redeemable reward. Mirrors `rewards/{id}` in the database and the
/// legacy web app's hard-coded `ITEMS` array.
class Reward {
  const Reward({
    required this.id,
    required this.names,
    required this.brand,
    required this.ep,
    required this.category,
    required this.iconKey,
    this.kind = RewardKind.item,
    this.partnerId,
    this.stock,
    this.active = true,
  });

  final String id;

  /// Localised names keyed by language code (`az`, `en`, `ru`, `tr`).
  final Map<String, String> names;
  final String brand;
  final int ep;
  final RewardCategory category;
  final String iconKey;
  final RewardKind kind;
  final String? partnerId;

  /// `null` = unlimited / not tracked.
  final int? stock;
  final bool active;

  bool get inStock => active && (stock == null || stock! > 0);

  String nameFor(String languageCode) =>
      names[languageCode] ?? names['az'] ?? names['en'] ?? id;

  IconData get icon => RewardIcons.byKey(iconKey, category);

  static RewardCategory parseCategory(String? raw) {
    switch (raw) {
      case 'food':
        return RewardCategory.food;
      case 'tech':
        return RewardCategory.tech;
      case 'eco':
        return RewardCategory.eco;
      default:
        return RewardCategory.service;
    }
  }

  static RewardKind parseKind(String? raw) {
    switch (raw) {
      case 'coupon':
        return RewardKind.coupon;
      case 'transport':
        return RewardKind.transport;
      default:
        return RewardKind.item;
    }
  }

  factory Reward.fromMap(String id, Map<String, Object?> m) {
    final namesRaw = asMap(m['name']);
    final names = <String, String>{
      for (final e in namesRaw.entries) e.key: asString(e.value),
    };
    if (names.isEmpty && m['name'] is String) {
      names['az'] = m['name'] as String;
    }
    final stockRaw = m['stock'];
    return Reward(
      id: id,
      names: names,
      brand: asString(m['brand']),
      ep: asInt(m['ep']),
      category: parseCategory(asString(m['cat'])),
      iconKey: asString(m['icon']),
      kind: parseKind(asString(m['kind'])),
      partnerId: asString(m['partnerId']).isEmpty
          ? null
          : asString(m['partnerId']),
      stock: stockRaw == null ? null : asInt(stockRaw),
      active: m['active'] == null ? true : asBool(m['active']),
    );
  }
}

abstract final class RewardIcons {
  static IconData byKey(String key, RewardCategory cat) {
    switch (key) {
      case 'tea':
        return Icons.emoji_food_beverage_rounded;
      case 'fruit':
        return Icons.apple_rounded;
      case 'drink':
        return Icons.local_drink_rounded;
      case 'meal':
        return Icons.rice_bowl_rounded;
      case 'solar':
        return Icons.solar_power_rounded;
      case 'headphones':
        return Icons.headphones_rounded;
      case 'tracker':
        return Icons.sensors_rounded;
      case 'charger':
        return Icons.battery_charging_full_rounded;
      case 'toothbrush':
        return Icons.brush_rounded;
      case 'bag':
        return Icons.shopping_bag_rounded;
      case 'thermos':
        return Icons.local_cafe_rounded;
      case 'soap':
        return Icons.clean_hands_rounded;
      case 'bus':
        return Icons.directions_bus_rounded;
      case 'cinema':
        return Icons.movie_rounded;
      case 'library':
        return Icons.local_library_rounded;
      case 'kombucha':
        return Icons.liquor_rounded;
      case 'cart':
        return Icons.shopping_cart_rounded;
      case 'store':
        return Icons.storefront_rounded;
      default:
        switch (cat) {
          case RewardCategory.food:
            return Icons.restaurant_rounded;
          case RewardCategory.tech:
            return Icons.devices_rounded;
          case RewardCategory.eco:
            return Icons.eco_rounded;
          case RewardCategory.service:
            return Icons.confirmation_number_rounded;
        }
    }
  }
}
