# Play Store preparation

What is ready: privacy page `https://ecopoint-api-2vey.onrender.com/privacy`, account deletion page
`https://ecopoint-api-2vey.onrender.com/delete-account`, in-app account deletion, release-signing tooling.
What is NOT done: no release was built or uploaded, store listing text/screenshots are yours to prepare, and the
privacy/deletion texts are factual templates — have them legally reviewed.

## Steps
1. `. .\tool\make_keystore.ps1` — creates `%USERPROFILE%\ecopoint-keys\ecopoint-release.jks` (outside the repo) and `android\key.properties` (git-ignored). **Back the key up.**
2. Add the printed SHA-1 and SHA-256 to Firebase (Project settings → Android app) — otherwise Google sign-in fails in the release build. After the first upload also add the **Play App Signing** SHA from Play Console → Setup → App signing.
3. Download the refreshed `google-services.json` into `android\app\`.
4. Build: `flutter build appbundle --release --dart-define=BACKEND_URL=https://ecopoint-api-2vey.onrender.com --dart-define=GOOGLE_WEB_CLIENT_ID=<web client id>`
   → `build\app\outputs\bundle\release\app-release.aab`.
5. Play Console (one-time developer fee, identity verification): create the app, upload the AAB to internal testing first, fill **Data safety** (name, e-mail, photo, user ID, device token, crash/error logs, location only for the map — all processed to provide the app), content rating, target audience, privacy URL, account-deletion URL.
6. New personal developer accounts must run a closed test (currently 12+ testers for 14 days) before production — check the current Play policy.

Kotlin DSL projects (`build.gradle.kts`): add a `signingConfigs.create("release")` reading `key.properties` and point `buildTypes.release.signingConfig` to it.
