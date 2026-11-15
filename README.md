# EcoPoint Pro — native Flutter app

A native (no WebView) Android + iOS rebuild of the EcoPoint Pro PWA: recycle at
smart bins, scan a QR code, earn **EP** points, spend them on rewards, send them
to friends, climb the leaderboard.

> **Verification status — read this first**
> This code was written in a sandbox with **no Dart/Flutter SDK and no access to pub.dev**.
> `flutter pub get`, `flutter analyze`, `flutter test` and `flutter build` have **never been run**.
> What *was* verified is listed under [Verification](#verification). Expect to fix a handful of
> compile/analyzer issues on the first real run; none of the Firebase integration has been
> exercised against a live project.

## Quick start

```bash
bash tool/bootstrap.sh          # flutter create android/ios + permissions/minSdk patch
dart pub global activate flutterfire_cli
flutterfire configure --project=ecopoint-suleyman-2026 --platforms=android,ios
flutter analyze && flutter test
flutter run
```

Without real Firebase credentials the app starts and shows a **“Firebase setup needed”** screen
instead of crashing (`lib/firebase_options.dart` ships with `REPLACE_*` placeholders; no keys are invented).

## Architecture

```
lib/
  app/            theme (tokens, EpColors ThemeExtension, dark+light), localization (az/en/ru/tr),
                  GoRouter (auth/onboarding redirects), MaterialApp.router
  core/           constants, Failure mapping, utils (QR parse, validators…), services
                  (Firebase bootstrap, backend callables, prefs), shared widgets
  features/<f>/   domain (pure Dart models/rules) · data (repositories + Riverpod providers) · presentation
    wallet · auth · profile · home · marketplace · smart_bins · qr_scanner · transactions
    challenges (streaks, missions, achievements) · leaderboard · notifications · statistics · shell
firebase/
  functions/      TypeScript Cloud Functions (v2 callables) + unit tests
  database.rules.json, firebase.json, seed/rewards.json
```

State: Riverpod (`Notifier`, `StreamProvider`…). Navigation: GoRouter with a `StatefulShellRoute`
(Home · Rewards · [Scan FAB] · Bins · Profile). Money-critical rules are pure Dart/TS and unit-tested.

## Security model (the most important change from the web app)

The legacy PWA let **the client write its own balance**, trusted a client-written `pendingPoints`
node, accepted *any* scanned string as worth 50 EP, and did transfers as two unchecked client
writes. All EP-changing logic now lives in Cloud Functions; **Realtime Database rules deny all
client writes except `users/{uid}/prefs`.**

| Operation | Callable | Protections |
|---|---|---|
| Scan bin QR | `openSession` / `sessionStatus` / `cancelSession` | HMAC-signed static QR, one open session per bin (3 min), per-user rate limits, ban list; **pays nothing** |
| Bin confirms deposit → EP | `POST /device/deposit` (no user token) | message signed with the bin's own HMAC key, clock skew ≤ 5 min, one open session closes exactly once, `eventId` idempotent, daily EP/gram caps; pays the person who scanned |
| Transfer | `transferEp` | atomic debit (never negative), credit, refund on failure, idempotent `requestId`, limits |
| Rewards / coupons / BakıKart | `purchaseReward`, `createCoupon`, `requestTransportTopUp` | server-side prices & stock, idempotent; BakıKart is a *pending request* an admin resolves (`adminResolveTransport`, refunds on reject) |
| Streak / missions / referral | `claimDailyCheckIn`, `claimChallenge`, `applyReferral` | server recomputes progress; once-per-day claims; one referrer per account, capped |
| Profile / deletion | `ensureProfile`, `updateProfile`, `deleteAccountData` | validated/sanitised; keeps the public `leaderboard/` projection in sync |
| Admin | `adminAdjustBalance`, `adminBroadcast`, `adminResolveTransport`, `adminIssueBinCode`, `adminSimulateDeposit` | require custom claim `admin: true` |

The client only ever *parses* QR payloads (`QrPayload`) to pick a flow; it never awards EP.
`leaderboard/` is a public projection so clients no longer read other users' private records.

### ⚠ Deploying the new rules breaks the legacy web app
The old PWA writes balances directly; the new rules (rightly) reject that. Migrate users to the
Flutter app (or retire the PWA) before deploying `database.rules.json`.

### Bin QR codes and deposits (static QR model)
The QR printed on a bin is **static** and carries no reward: `EP2:<binId>:<sig32hex>`,
`sig = HMAC-SHA256(secret, "EP2:<binId>")[:32]`. Flow: the person scans it → `openSession` (server verifies the
signature, the bin exists and is not `disabled`, one person per bin at a time, 3 min) → the app shows "put your
waste in the bin" and polls `sessionStatus` → the bin sends `POST /device/deposit` and the server credits the
person whose session is open. Print the code with the admin screen (or `npm run qr -- bin-01`, which also prints
the bin's device key).

Deposit message (JSON): `{binId, eventId, grams, ts, mac}`; `ts` = bin clock in epoch ms (±5 min), `eventId` unique per
deposit (re-sending it returns the first result), `grams` 0 when the bin has no scale (then a flat 50 EP), and
`mac = HMAC-SHA256(deviceKey, "<binId>.<eventId>.<grams>.<ts>")` as lower-case hex, where
`deviceKey = HMAC-SHA256(QR_HMAC_SECRET, "devkey:<binId>")` (printed by `npm run qr`). 10 EP per 100 g.
Errors: `no-session` (nobody scanned; nothing is burned, the bin may retry), `forbidden` (bad MAC),
`daily-limit`, `bin-disabled`.

**There are no real bins yet.** The admin screen has a *virtual bin*: scan the bin's QR with your phone, then press
"Zibil at" → the server builds a correctly signed deposit and sends it through the same code as a real bin.
It works only when the server has `SIM_ENABLED=1` (leave it off in production once real bins exist).
**Bin firmware is not part of this repo.** The old expiring `EP1` codes and `redeemDeviceWeight` were removed.

## Backend (two ways to run it)

**A. Node server on a free host (no Blaze plan needed) — recommended for this project.**
`firebase/functions` also builds as a plain Express server (`npm start`, entry `src/server-main.ts`).
The app sends `POST {BACKEND_URL}/api/<name>` with the Firebase ID token; the same services/tests as the
Cloud Functions build. Deploy to Render with `render.yaml`; env vars: `DATABASE_URL`, `QR_HMAC_SECRET`,
`FIREBASE_SERVICE_ACCOUNT` (service-account JSON). Free hosts sleep when idle: the app wakes the server on
start and a free UptimeRobot monitor on `/health` (every 5 min) keeps it warm. Build the app with
`--dart-define=BACKEND_URL=https://<your-service>.onrender.com`.

**B. Cloud Functions (needs the Blaze plan).** `src/index.ts` exports the same operations as callables, but
the Flutter client in this repo calls the HTTP server (A). To use B you must switch `BackendService` back to
`cloud_functions`.

### Cloud Functions setup (B)

```bash
cd firebase/functions && npm install && npm test && npm run build
firebase login && firebase use ecopoint-suleyman-2026
firebase functions:secrets:set QR_HMAC_SECRET        # long random string; never commit
firebase deploy --only database,functions            # needs the Blaze plan
firebase database:set /rewards firebase/seed/rewards.json   # optional: seed the catalog
# make an admin:  admin.auth().setCustomUserClaims(uid, { admin: true })
```
Bins that write to `devices/` need a custom token with claim `device: true` (or use the Admin SDK).
`pruneExpired` (daily) needs Cloud Scheduler. Consider enabling **App Check** (not configured here).

## Repository layout & updates

This repository holds the whole project: the Flutter app (`lib/`, `android/`, …) and the Node API (`firebase/functions`).
The root `package.json` only delegates to `firebase/functions`, so Render keeps building the same service
(`npm install && npm run build` / `npm start`). Pushing to `main` redeploys the API automatically.

- Publish the local project: `. .\tool\publish_repo.ps1` (mirrors the project, refuses to push secrets).
- Android push/https patch: `. .\tool\android_patch.ps1`; launcher icon: `dart run flutter_launcher_icons`.
- Google sign-in: `. .\tool\google_sha.ps1`, then build with `--dart-define=GOOGLE_WEB_CLIENT_ID=<web client id>`.
- Push self-test (e-mail account): `. .\tool\test_push.ps1` → server pushes a test notification to your phone and reports tokens/sent/errors.
- Release build: `flutter build apk --release --dart-define=BACKEND_URL=https://<service>.onrender.com --dart-define=GOOGLE_WEB_CLIENT_ID=<id>`.

## Features

Onboarding · email/password + Google sign-in · password reset · profile setup/edit/avatars · session persistence ·
home dashboard · native QR scanner (permission gate, duplicate-scan lock, torch) · rewards marketplace (search, categories, stock) ·
coupons · BakıKart request · EP transfer (search by name/ID or scan a friend's QR) with history · smart-bin map (OpenStreetMap, no key) + list,
location permission with fallbacks · statistics (7/30-day chart) · streak, daily missions, achievements · leaderboard ·
referral · notifications (global + personal) · settings (language az/en/ru/tr/es/de/it/zh/ja/ko/ar/fa/hi/pt/vi — Arabic and Persian are right-to-left, theme dark/light/system, notification prefs, privacy, about) ·
sign-out · account deletion · offline banner + RTDB offline cache.

## Verification

Actually run in the sandbox:
- `firebase/functions`: `npm test` → **140 tests pass** (static QR forgery, session/deposit flow, replay and idempotency, concurrency, double-spend, idempotency, refunds, caps, rules, push tokens/delivery, personalized smart notifications); `tsc` builds; building and starting from the repo root (`npm run build`, `npm start`) works.
- `python3 tool/verify_static.py`: Dart **syntax** of all files (tree-sitter), every import resolves, 338 localization keys identical across az/en/ru/tr, every `tr('…')` key exists.

**Not** run in the sandbox (needs a device): Flutter compile, any real FCM delivery, Google sign-in, camera, location. The author's machine ran `flutter analyze`/`test` and a release APK before the push/Google/icon changes; those changes still need that check.
The Dart tests in `test/` are written but unexecuted.

## What you must provide / known gaps

- Real Firebase config (`flutterfire configure`), SHA-1/256 for Google sign-in (`tool/google_sha.ps1`), the Google *web* client id (`--dart-define=GOOGLE_WEB_CLIENT_ID=…`), iOS URL scheme and APNs key (iOS has never been built).
- `QR_HMAC_SECRET`, deployed functions, deployed rules, admin claim.
- Bin firmware: signed per-deposit codes; `weightEventId`; optional `lat`/`lng` on `devices/{id}` — **no coordinates are invented**, bins without them appear only in the list.
- Scheduled pushes (server timer, Asia/Baku, needs the server awake): 12:00 daily check-in reminder (only if not done yet), 20:00 streak-at-risk (streak ≥ 3), Monday 10:00 weekly summary (real totals, skipped when 0). Each runs once per day (atomic marker `cron/<kind>/<day>`), follows the user's app language and the *activity* notification switch. Not verified on a device.
- Push (FCM): implemented (device token registry, per-user pushes for received EP / BakıKart results, broadcast topic `news`, honours the two notification switches) but **not verified end-to-end on a device**; iOS needs an APNs key. A release/Play Store signing key will need its own SHA fingerprints.
- EcoPoint Pro purchase is **not** implemented (shown as unavailable); Pro can be set by an admin (`isPro`, `proExpiry`) and gives ×2 on scans/weight.
- Impact figures are fixed-factor **estimates** (labelled as such), not measurements.
- Daily-mission “day” follows the device date within ±1 day of Asia/Baku; scans count QR scans only.
- Coupon values assume 500 EP = 1 AZN and 5 % commission (from the legacy module); verify with partners.
- Launcher icon is generated with `dart run flutter_launcher_icons` (config in `pubspec.yaml`); no native splash, store listing or release signing config.
- Only unit tests exist (no widget/integration tests); accessibility was designed in (semantic labels, 48 dp targets) but not audited on a device.


## Added in the latest round
- Admin panel (`/admin`, only for the verified admin e-mail) — see `docs/ADMIN.md`.
- Error reporting (Dart errors → `errorLogs`), weekly leaderboard, eco guide, partner coupon check/redeem, public `/privacy` and `/delete-account` pages.
- Play Store tooling: `tool/make_keystore.ps1`, `docs/PLAY_STORE.md`; capacity notes: `docs/SCALING.md`.

Honest gaps: Flutter code of these features is only syntax/import-checked in the sandbox (run `flutter analyze`); scheduled pushes unverified on a device; iOS never built; native crashes not captured; no Play release made.

## Round 3
- Sign-in persistence: Google users are silently signed back in if the phone loses the Firebase session (`lib/core/services/session_restore.dart`); password users cannot be restored. Cause of the original sign-outs is unconfirmed.
- Monthly goals (30 / 60 scans → 300 / 700 EP) and Monday prizes for last week's top 3 (200 / 100 / 50 EP), both paid by the server.
- Home invite card, notification primer (asks before the OS prompt, max 3 times), admin statistics, share link with preview card.

## Round 4
Crashlytics, nearest free bin + directions, statistics share image, admin suspicious-activity list + CSV export, invite App Links (`/.well-known/assetlinks.json`).
Unverified until run on a phone: Gradle plugin patch (Crashlytics), App Links verification, share image rendering, directions deep link.

## More features (v2 round)
- **Problem reports:** a bin's sheet has "Report a problem" (broken/full/dirty/other + note + optional small photo, base64 in the database, no Firebase Storage needed). Two different people reporting "broken" mark the bin "not working" on the map; admins see the list with photos (`/admin/reports`) and resolve it.
- **Favourite bins:** star a bin; when it crosses 85 % full the server pushes the people who starred it once (re-armed below 60 %). Respects the "activity" notification switch.
- **Update notice:** `GET /app-version` returns `APP_LATEST_VERSION` / `APP_DOWNLOAD_URL` / `APP_UPDATE_NOTES` (Render env). The app shows a dismissible banner when the server version is newer than `AppConstants.appVersion` (keep it equal to pubspec).
- **Launcher shortcuts** (long-press the icon): Scan, Balance. **Android 12+ system colours:** optional switch in Settings (accent only; contrast-tested surfaces stay).
- **Home-screen widget (Android):** balance + streak. Native part is added by `tool/android_widget.ps1` (not by `flutter create`); the app tolerates its absence.
- **First steps** checklist on Home (check-in, first deposit, first reward) from real data; skeleton lists while loading; confetti + haptics on a successful deposit; breathing flame on a done streak; system font scale up to 1.6x; text contrast raised to 4.5:1.

## Smart personal notifications (v2)

Hourly job (`smart-push.ts`). Each person gets **4-9 pushes a day** (adaptive): the base is 4, +1 for every day in the last 7 on which the person tapped a push (max 9); only 2 per day after 7 days without a scan (comeback mode); the "Fewer notifications" switch pins it to 4. The slots are spread evenly over the person's own 09:00-21:00 (device time zone `tz` sent at registration; default Baku). A slot sends the most useful message that is still true at send time (monthly reward ready -> monthly goal close -> reward within reach -> comeback -> daily check-in -> evening recap -> eco tip) and otherwise stays silent - the number is a maximum, content is never invented. Slots are claimed atomically (`pushLog/{uid}/slots`), so two schedulers never double-send. Tapping a push calls `ackPush` (stores only the day and kind). Prefs: `notifyActivity`, `notifyOffers`, `notifyFewer`. Tips/recap are written natively in az/en/ru/tr; other languages currently get these two kinds in English. Requires `firebase deploy --only database`.

### Free scheduler without a sleeping server
`.github/workflows/push-tick.yml` runs `npm run tick` (`tick-main.ts`) every 10 minutes on GitHub Actions. Add two repository secrets (Settings -> Secrets and variables -> Actions): `FIREBASE_SERVICE_ACCOUNT` (JSON, one line) and `DATABASE_URL`. GitHub may delay scheduled runs by 10-30 minutes and pauses schedules after 60 days without repository activity; `keepalive.yml` re-enables it monthly. The Render server's own scheduler can keep running: markers make double-runs harmless.
