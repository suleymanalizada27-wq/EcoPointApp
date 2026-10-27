# Admin guide

Admin account: **greenlinegroup2026@gmail.com**.

## How admin rights work
The server (never the app) decides. A caller is admin when its Firebase ID token has the custom claim
`admin=true`, **or** `email_verified=true` and the e-mail is listed in the Render env var `ADMIN_EMAILS`
(comma separated, lower-case). Google sign-in gives a verified e-mail; password sign-ups never qualify,
so nobody can become admin by registering that address with a password.

## Set up (once)
1. Render → service → Environment: `ADMIN_EMAILS=greenlinegroup2026@gmail.com` (and optionally `CONTACT_EMAIL`). Save → redeploy.
2. In the app choose **Sign in with Google** using that account. Profile → **Admin paneli** appears.
3. Deploy the new database rules (adds `weeklyBoard`): `cd firebase; firebase deploy --only database --project ecopoint-suleyman-2026`.

## Screens
Users (search, EP adjust, ban, Pro) · Rewards · Bins (+ signed QR) · BakıKart requests · Coupon check/redeem ·
Broadcast (inbox + push to everyone) · Error log. Every admin write is logged under `adminLog`.

## Notes
- Editing a reward through the panel saves it as an ordinary item; coupon/transport-type rewards should not be edited there.
- Error log only holds Dart-level errors from signed-in users (not native crashes), kept 14 days.

## Share link
Referral share text contains `https://<your-render-url>/invite/<CODE>`. WhatsApp/Telegram show a preview card (logo + text);
the page shows the inviter's first name and the code. Set the Render env var `APP_DOWNLOAD_URL` (Play Store or APK link)
to show a "Tətbiqi yüklə" button; without it the page says the app is coming to the store soon.
The link does not open the app directly (no app-link configuration yet) — the friend types the code at sign-up.

## Statistics
Admin → Statistika: daily signups, EP earned/spent, scan count (last 14 days) and top rewards. Counters start collecting
after this update, so earlier days show 0.
