import 'package:flutter/material.dart';

import '../../app/theme/ep_colors.dart';

/// Preset avatars users can pick (stored as `avatar` key on their profile).
/// The legacy app only used the Google photo; presets are a no-upload option.
abstract final class AvatarPresets {
  static const List<String> keys = [
    'leaf',
    'sprout',
    'recycle',
    'earth',
    'bolt',
    'tree',
  ];

  static IconData icon(String key) {
    switch (key) {
      case 'leaf':
        return Icons.eco_rounded;
      case 'sprout':
        return Icons.spa_rounded;
      case 'recycle':
        return Icons.recycling_rounded;
      case 'earth':
        return Icons.public_rounded;
      case 'bolt':
        return Icons.bolt_rounded;
      case 'tree':
        return Icons.park_rounded;
      default:
        return Icons.eco_rounded;
    }
  }

  static List<Color> gradient(String key) {
    switch (key) {
      case 'sprout':
        return const [Color(0xFF8BD450), Color(0xFF2F8F4E)];
      case 'recycle':
        return const [Color(0xFF3FD0A5), Color(0xFF0E7A6B)];
      case 'earth':
        return const [Color(0xFF58B7DB), Color(0xFF1C6E8C)];
      case 'bolt':
        return const [Color(0xFFE8D84A), Color(0xFF9A8A1B)];
      case 'tree':
        return const [Color(0xFF5FB87A), Color(0xFF1F6B45)];
      case 'leaf':
      default:
        return const [Color(0xFF2BC48A), Color(0xFF0E6B4B)];
    }
  }
}

/// Circular avatar: network photo → preset → initials, in that order.
class EpAvatar extends StatelessWidget {
  const EpAvatar({
    super.key,
    this.photoUrl,
    this.presetKey,
    this.name,
    this.size = 44,
    this.ring = false,
  });

  final String? photoUrl;
  final String? presetKey;
  final String? name;
  final double size;
  final bool ring;

  String get _initial {
    final n = (name ?? '').trim();
    return n.isEmpty ? '?' : String.fromCharCode(n.runes.first).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ep;

    Widget fallback() {
      final key = presetKey;
      if (key != null && key.isNotEmpty) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AvatarPresets.gradient(key),
            ),
          ),
          child: Icon(
            AvatarPresets.icon(key),
            size: size * 0.52,
            color: Colors.white,
          ),
        );
      }
      return Container(
        color: c.surfaceRaised,
        alignment: Alignment.center,
        child: Text(
          _initial,
          style: context.text.titleMedium?.copyWith(
            fontSize: size * 0.4,
            color: c.emerald,
          ),
        ),
      );
    }

    final url = photoUrl;
    final Widget image = (url != null && url.isNotEmpty)
        ? Image.network(
            url,
            fit: BoxFit.cover,
            width: size,
            height: size,
            errorBuilder: (_, __, ___) => fallback(),
            loadingBuilder: (context, child, progress) =>
                progress == null ? child : fallback(),
          )
        : fallback();

    return Container(
      width: size,
      height: size,
      padding: ring ? const EdgeInsets.all(2.5) : EdgeInsets.zero,
      decoration: ring
          ? BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: c.lime, width: 2),
            )
          : null,
      child: ClipOval(child: image),
    );
  }
}
