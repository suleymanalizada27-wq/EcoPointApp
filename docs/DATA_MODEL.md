# Realtime Database layout

Client-readable (owner only): `users/{uid}` → `name, email, photoURL, bio, avatar, balance, referralCode, referredBy, isPro, proExpiry,`
`stats{earned,sent,scans,spent}, transactions/*, purchases/*, coupons/*, streak{count,lastDay,history}, claims/{mission}_{day},`
`daily/{day}{ep,scans,grams}, notifications/*, prefs{notifyActivity,notifyNews}` — only `prefs` is client-writable.

Public read (signed-in): `leaderboard/{uid}{name,nameLower,photoURL,avatar,ep}`, `devices/{id}`, `rewards/{id}`, `globalNotifications/*`.

Server only (no client access): `qrNonces`, `weightEvents`, `deviceState`, `idempotency/{uid}`, `rate/{key}`, `transfers`,
`coupons/{code}`, `transportRequests`, `referralCodes/{code}→uid`, `security/banned/{uid}`, `adminLog`.

Transaction doc: `{type: earn|received|sent|purchase|weight|bonus|other, amount:"+50", rawAmount:50, desc, ts, status}`
(legacy `snd`/`buy` types still parse).
