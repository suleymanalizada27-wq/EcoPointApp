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

## Duolingo-style presence (v4b)
* Dashboard hero: large animated mascot + speech bubble, tap the mascot for tips.
* `EcoFriendBanner` (mascot + bubble) on Missions, Statistics, Rewards, Bins, History, Guide,
  Referral, Profile; scanner has a live bubble; `EcoFriendCelebrationHost` (in `MainShell`)
  slides EcoFriend up on every tab for excited / cheering / proud.
* Widgets: light/dark palette (`ep_widget_colors*.xml`), chunky cards, speech bubble, week-dot
  row and big action buttons on the 4x4.

## v4c
* `EcoFriendView`: pop-in on every mood change, tap = jump + sparkles (cosmetic only).
* Full-screen confetti party (big EcoFriend) for cheering / proud; excited = bottom toast.
* Streak milestones (3, 7, 14, 30, 60, 100, 365) -> proud with `ef_streak`.
* More screens: onboarding (3 moods), sign-in, sign-up, settings, transfer, my QR, achievements.
* Widget: morning / evening nudge until the app is opened today.

## v4d (widget look)
Gradient card with 3D bottom lip + gloss, soft glow behind EcoFriend, speech bubble with lip,
glossy green "Scan" button, orange week coins; separate light / dark palettes.

## v4e (time-of-day widget scenes)
`ep_widget_bg_{morning,day,evening,night}.xml` (sky gradient, sun/moon, clouds, stars, hills);
Kotlin picks the scene by local hour (05-09 / 10-15 / 16-19 / 20-04); update period 30 min.
