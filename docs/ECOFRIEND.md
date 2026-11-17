# EcoFriend mascot

Official name: **EcoFriend**. Assets: `assets/ecofriend/` (animated WebP, 512x512, ~20 fps,
transparent) and `assets/ecofriend/still/` (static PNG per mood). The originals were
VP9 WebM with alpha; they were converted to animated WebP because Flutter cannot play
alpha WebM without an extra package.

* `lib/features/ecofriend/domain/ecofriend_engine.dart` - pure-Dart state engine (priority,
  de-duplication, cool-down, auto-return to resting mood) + `widgetMoodAt`.
* `lib/features/ecofriend/application/ecofriend_controller.dart` - Riverpod controller, the single
  source of truth (Dashboard, scanner, widgets). Reacts only to backend-confirmed data; it never
  writes EP.
* `lib/features/ecofriend/presentation/ecofriend_view.dart` - `EcoFriendView`, `EcoFriendCard`
  (Dashboard), `EcoFriendHint` (static, empty/error states).
* Android widgets: `tool/android_res/widget/` (2x2, 4x2, 4x4 use static PNG; animated WebP is not
  supported by RemoteViews). Run `. .\tool\android_widget.ps1` to install.
* Widget quick links (4x4) reuse the quick_actions intent handled in `ShortcutsHost`.
* Tests: `test/ecofriend_engine_test.dart`.
