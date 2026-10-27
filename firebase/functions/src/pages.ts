/** Public pages required by app stores: privacy policy and account deletion. */

const esc = (s: string): string =>
  s.replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c] as string);

function shell(title: string, body: string): string {
  return `<!doctype html><html lang="az"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>${esc(title)}</title>
<style>
body{font:16px/1.6 system-ui,Segoe UI,Roboto,sans-serif;margin:0;background:#0b1410;color:#e8f3ee}
main{max-width:760px;margin:0 auto;padding:24px 16px 64px}
h1{font-size:28px;margin:8px 0 4px}h2{font-size:20px;margin:28px 0 6px;color:#6ee7b7}
a{color:#6ee7b7}small,.muted{color:#9bb5aa}hr{border:0;border-top:1px solid #214034;margin:32px 0}
li{margin:4px 0}
</style></head><body><main>${body}</main></body></html>`;
}

export function privacyHtml(contact: string): string {
  const c = esc(contact);
  return shell(
    'EcoPoint — Privacy Policy',
    `<h1>EcoPoint Məxfilik Siyasəti</h1>
<p class="muted">Son yenilənmə: 2026-10-26</p>

<h2>Topladığımız məlumatlar</h2>
<ul>
<li><b>Hesab:</b> e-poçt ünvanı, ad, (Google ilə girişdə) profil şəkli və giriş identifikatoru.</li>
<li><b>Tətbiq fəaliyyəti:</b> EP balansı, əməliyyat tarixçəsi, skan və köçürmələr, gündəlik seriya, nailiyyətlər, mükafat və kupon alışları, istinad (referral) kodu.</li>
<li><b>Bildiriş məlumatı:</b> cihazın bildiriş nişanı (FCM token), tətbiq dili və bildiriş seçimləri.</li>
<li><b>Texniki xəta hesabatları:</b> tətbiqin çökmə/xəta mətni, tətbiq versiyası, platforma. Şəxsi məzmun daxil deyil.</li>
<li><b>BakıKart sorğusu:</b> doldurma üçün daxil etdiyiniz 16 rəqəmli kart nömrəsi yalnız serverdə növbədə saxlanılır.</li>
</ul>

<h2>Cihazda qalan məlumatlar</h2>
<ul>
<li><b>Kamera:</b> yalnız QR kodu oxumaq üçündür. Şəkil və video saxlanmır və göndərilmir.</li>
<li><b>Məkan:</b> yalnız xəritədə sizə yaxın qutuları göstərmək üçün cihazda istifadə olunur. Dəqiq məkanınız serverə göndərilmir.</li>
</ul>

<h2>Məlumatdan necə istifadə edirik</h2>
<p>Hesabı idarə etmək, EP hesablamaq və yoxlamaq, saxtakarlığın qarşısını almaq, bildirişlər göndərmək (gündəlik xatırlatma, seriya xəbərdarlığı, həftəlik xülasə, EP daxil olması) və tətbiqin xətalarını düzəltmək üçün. Məlumatınızı satmırıq və reklam üçün istifadə etmirik.</p>

<h2>Üçüncü tərəflər</h2>
<ul>
<li><b>Google Firebase</b> (giriş, verilənlər bazası, bildirişlər).</li>
<li><b>Render</b> (server hostinqi).</li>
<li><b>OpenStreetMap</b> (xəritə lövhələri; xəritəni açanda IP ünvanınız onların serverinə görünə bilər).</li>
</ul>

<h2>Saxlama və silinmə</h2>
<p>Məlumatlar hesabınız mövcud olduğu müddətdə saxlanılır. Hesabı sildikdə profil, balans, əməliyyat tarixçəsi, bildiriş nişanları və liderlər cədvəlindəki qeyd silinir. Təhlükəsizlik və mühasibat qeydləri (köçürmə və admin jurnalı) anonimləşdirilmiş şəkildə qala bilər. Xəta hesabatları 14 gündən sonra avtomatik silinir.</p>

<h2>Hüquqlarınız</h2>
<p>Məlumatlarınıza giriş, düzəliş və silinmə tələb edə bilərsiniz. Hesabı tətbiqdən silə bilərsiniz (Profil → Ayarlar → Hesabı sil) və ya <a href="/delete-account">bu səhifədəki</a> qaydalarla bizə yaza bilərsiniz.</p>

<h2>Uşaqlar</h2>
<p>Tətbiq 13 yaşdan kiçik uşaqlar üçün nəzərdə tutulmayıb.</p>

<h2>Əlaqə</h2>
<p><a href="mailto:${c}">${c}</a></p>

<hr>
<h1>EcoPoint Privacy Policy</h1>
<p><b>Data we collect:</b> account data (email, name, profile photo when you use Google sign-in), app activity (EP balance, transactions, scans, transfers, streaks, purchases, referral code), notification data (device push token, app language, notification preferences), technical error reports (error text, app version, platform), and, only when you request a BakıKart top-up, the card number you enter (kept server-side in a queue).</p>
<p><b>Stays on your device:</b> the camera is used only to read QR codes (no photos or video are stored or sent); your location is used only to show nearby bins on the map and is not sent to our server.</p>
<p><b>Use:</b> to run your account, calculate and verify EP, prevent fraud, send notifications (daily reminder, streak warning, weekly summary, EP received) and fix bugs. We do not sell data or use it for advertising.</p>
<p><b>Third parties:</b> Google Firebase (sign-in, database, notifications), Render (hosting), OpenStreetMap (map tiles).</p>
<p><b>Retention and deletion:</b> data is kept while your account exists. Deleting your account removes your profile, balance, transaction history, push tokens and leaderboard entry; security and accounting records (transfers, admin log) may remain without your profile. Error reports are deleted after 14 days. Delete your account in the app (Profile → Settings → Delete account) or contact <a href="mailto:${c}">${c}</a>.</p>
<p><b>Children:</b> the app is not directed at children under 13.</p>`,
  );
}

export function deleteAccountHtml(contact: string): string {
  const c = esc(contact);
  return shell(
    'EcoPoint — Delete account',
    `<h1>Hesabın silinməsi</h1>
<h2>Tətbiqdən (ən sürətli yol)</h2>
<ol>
<li>EcoPoint tətbiqini aç və hesabınla daxil ol.</li>
<li><b>Profil → Ayarlar → Hesabı sil</b> seçimini seç və təsdiqlə.</li>
</ol>
<p>Silinəcəklər: profil, EP balansı, əməliyyat tarixçəsi, alışlar, kuponlar, bildiriş nişanları və liderlər cədvəlindəki qeyd. Bu əməliyyat geri qaytarılmır, silinmiş EP bərpa olunmur.</p>

<h2>Tətbiq olmadan</h2>
<p>Tətbiqə girə bilmirsənsə, qeydiyyatdakı e-poçt ünvanından <a href="mailto:${c}?subject=Delete%20my%20EcoPoint%20account">${c}</a> ünvanına “hesabımı silin” yaz. Sorğu 30 gün ərzində icra olunur.</p>

<hr>
<h1>Delete your account</h1>
<p><b>In the app:</b> sign in, then Profile → Settings → Delete account. This removes your profile, EP balance, transaction history, purchases, coupons, push tokens and leaderboard entry. It cannot be undone.</p>
<p><b>Without the app:</b> email <a href="mailto:${c}?subject=Delete%20my%20EcoPoint%20account">${c}</a> from the address you registered with; requests are handled within 30 days.</p>
<p><a href="/privacy">Privacy policy</a></p>`,
  );
}

export interface InviteOpts {
  code: string;
  inviter?: string;
  baseUrl: string;
  downloadUrl?: string;
}

/** Public landing page behind the share link; carries the preview card tags. */
export function inviteHtml(o: InviteOpts): string {
  const code = esc(o.code);
  const who = o.inviter ? esc(o.inviter) : '';
  const title = who ? `${who} səni EcoPoint-ə dəvət edir` : 'EcoPoint — təkrar emal et, EP qazan';
  const desc = 'Qeydiyyatda dəvət kodunu yaz, ikiniz də bonus EP qazanın. Təkrar emal et, mükafat al.';
  const url = `${esc(o.baseUrl)}/invite/${code}`;
  const img = `${esc(o.baseUrl)}/og.jpg`;
  const button = o.downloadUrl
    ? `<a class="btn" href="${esc(o.downloadUrl)}">Tətbiqi yüklə</a>`
    : `<p class="muted">Tətbiq tezliklə mağazada olacaq. Kodu saxla və hazır olanda istifadə et.</p>`;
  return `<!doctype html><html lang="az"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>${esc(title)}</title>
<meta name="description" content="${esc(desc)}">
<meta property="og:type" content="website">
<meta property="og:site_name" content="EcoPoint">
<meta property="og:title" content="${esc(title)}">
<meta property="og:description" content="${esc(desc)}">
<meta property="og:url" content="${url}">
<meta property="og:image" content="${img}">
<meta property="og:image:width" content="1200">
<meta property="og:image:height" content="630">
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="${esc(title)}">
<meta name="twitter:description" content="${esc(desc)}">
<meta name="twitter:image" content="${img}">
<meta name="theme-color" content="#000000">
<link rel="icon" href="/logo.png">
<style>
body{margin:0;min-height:100vh;display:flex;align-items:center;justify-content:center;background:radial-gradient(circle at 50% 0%,#0b3d2c 0,#000 60%);color:#e8f3ee;font:16px/1.5 system-ui,Segoe UI,Roboto,sans-serif}
.card{max-width:420px;width:100%;margin:24px;padding:28px 24px;text-align:center;background:#07130eee;border:1px solid #1d4a38;border-radius:24px}
img{width:140px;height:140px;border-radius:32px}
h1{font-size:24px;margin:16px 0 8px}p{margin:8px 0;color:#b7cfc4}
.code{margin:20px 0;padding:14px;border:1px dashed #6ee7b7;border-radius:16px;font-size:30px;letter-spacing:6px;color:#6ee7b7;font-weight:700}
.btn{display:block;margin-top:16px;padding:14px;border-radius:14px;background:#10b981;color:#00180f;font-weight:700;text-decoration:none}
button{margin-top:10px;width:100%;padding:12px;border-radius:14px;border:1px solid #1d4a38;background:transparent;color:#e8f3ee;font-size:15px}
.muted{font-size:14px}
</style></head><body><div class="card">
<img src="/logo.png" alt="EcoPoint">
<h1>${esc(title)}</h1>
<p>${esc(desc)}</p>
<div class="code" id="c">${code}</div>
${button}
<button onclick="navigator.clipboard&&navigator.clipboard.writeText('${code}').then(function(){this.textContent='Kopyalandı ✓'}.bind(this))">Kodu kopyala</button>
</div></body></html>`;
}
