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
flutterfire configure --project=ecopoint-b3d60 --platforms=android,ios
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
| Bin QR → EP | `redeemQr` | HMAC-SHA256 signature, expiry, single-use nonce (transactional), per-user rate limits (3 s / 10 per hour), daily EP cap, ban list |
| Weight → EP | `redeemDeviceWeight` | server reads the bin's own reading; single-use via `weightEventId`; freshness, min/max, cooldown, daily gram cap |
| Transfer | `transferEp` | atomic debit (never negative), credit, refund on failure, idempotent `requestId`, limits |
| Rewards / coupons / BakıKart | `purchaseReward`, `createCoupon`, `requestTransportTopUp` | server-side prices & stock, idempotent; BakıKart is a *pending request* an admin resolves (`adminResolveTransport`, refunds on reject) |
| Streak / missions / referral | `claimDailyCheckIn`, `claimChallenge`, `applyReferral` | server recomputes progress; once-per-day claims; one referrer per account, capped |
| Profile / deletion | `ensureProfile`, `updateProfile`, `deleteAccountData` | validated/sanitised; keeps the public `leaderboard/` projection in sync |
| Admin | `adminAdjustBalance`, `adminBroadcast`, `adminResolveTransport`, `adminIssueBinCode` | require custom claim `admin: true` |

The client only ever *parses* QR payloads (`QrPayload`) to pick a flow; it never awards EP.
`leaderboard/` is a public projection so clients no longer read other users' private records.

### ⚠ Deploying the new rules breaks the legacy web app
The old PWA writes balances directly; the new rules (rightly) reject that. Migrate users to the
Flutter app (or retire the PWA) before deploying `database.rules.json`.

### Bin QR codes
Format `EP1:<binId>:<nonce>:<expUnixSec>:<sig32hex>`; `sig = HMAC-SHA256(secret, "binId:nonce:exp")[:32]`.
Each code is **single-use**, so a printed sticker works once. Production needs the bin (ESP32) or a
display/back-office to mint a fresh code per deposit, or an admin tool (`adminIssueBinCode`,
`npm run qr -- bin-01`). **Bin firmware changes are required and are not part of this repo.**
`devices/{id}` must exist, and for weight redemption the firmware must publish a changing `weightEventId`.

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
firebase login && firebase use ecopoint-b3d60
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
- Release build: `flutter build apk --release --dart-define=BACKEND_URL=https://<service>.onrender.com --dart-define=GOOGLE_WEB_CLIENT_ID=<id>`.

## Features

Onboarding · email/password + Google sign-in · password reset · profile setup/edit/avatars · session persistence ·
home dashboard · native QR scanner (permission gate, duplicate-scan lock, torch) · rewards marketplace (search, categories, stock) ·
coupons · BakıKart request · EP transfer (search by name/ID or scan a friend's QR) with history · smart-bin map (OpenStreetMap, no key) + list,
location permission with fallbacks · statistics (7/30-day chart) · streak, daily missions, achievements · leaderboard ·
referral · notifications (global + personal) · settings (language az/en/ru/tr, theme dark/light/system, notification prefs, privacy, about) ·
sign-out · account deletion · offline banner + RTDB offline cache.

## Verification

Actually run in the sandbox:
- `firebase/functions`: `npm test` → **78 tests pass** (QR forgery/replay/expiry/concurrency, double-spend, idempotency, refunds, caps, rules, push tokens/delivery); `tsc` builds; building and starting from the repo root (`npm run build`, `npm start`) works.
- `python3 tool/verify_static.py`: Dart **syntax** of all files (tree-sitter), every import resolves, 338 localization keys identical across az/en/ru/tr, every `tr('…')` key exists.

**Not** run in the sandbox (needs a device): Flutter compile, any real FCM delivery, Google sign-in, camera, location. The author's machine ran `flutter analyze`/`test` and a release APK before the push/Google/icon changes; those changes still need that check.
The Dart tests in `test/` are written but unexecuted.

## What you must provide / known gaps

- Real Firebase config (`flutterfire configure`), SHA-1/256 for Google sign-in (`tool/google_sha.ps1`), the Google *web* client id (`--dart-define=GOOGLE_WEB_CLIENT_ID=…`), iOS URL scheme and APNs key (iOS has never been built).
- `QR_HMAC_SECRET`, deployed functions, deployed rules, admin claim.
- Bin firmware: signed per-deposit codes; `weightEventId`; optional `lat`/`lng` on `devices/{id}` — **no coordinates are invented**, bins without them appear only in the list.
- Push (FCM): implemented (device token registry, per-user pushes for received EP / BakıKart results, broadcast topic `news`, honours the two notification switches) but **not verified end-to-end on a device**; iOS needs an APNs key. A release/Play Store signing key will need its own SHA fingerprints.
- EcoPoint Pro purchase is **not** implemented (shown as unavailable); Pro can be set by an admin (`isPro`, `proExpiry`) and gives ×2 on scans/weight.
- Impact figures are fixed-factor **estimates** (labelled as such), not measurements.
- Daily-mission “day” follows the device date within ±1 day of Asia/Baku; scans count QR scans only.
- Coupon values assume 500 EP = 1 AZN and 5 % commission (from the legacy module); verify with partners.
- Launcher icon is generated with `dart run flutter_launcher_icons` (config in `pubspec.yaml`); no native splash, store listing or release signing config.
- Only unit tests exist (no widget/integration tests); accessibility was designed in (semantic labels, 48 dp targets) but not audited on a device.
