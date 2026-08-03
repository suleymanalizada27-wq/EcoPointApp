/* ═══════════════════════════════════════════════════════════════
   ECOPOINT PRO — TƏHLÜKƏSİZLİK VƏ KODUN QORUNMASI MODULU
   Anti-Cheat Məntiqi + Firebase Security Rules + Obfuscation
   ═══════════════════════════════════════════════════════════════ */

// ─────────────────────────────────────────────
//  MODUL 3A: ANTI-CHEAT DOĞRULAMA MƏNTİQİ
// ─────────────────────────────────────────────


const SecurityModule = (() => {

  // Konfiqurasiya
  const CFG = {
    MAX_SCANS_PER_HOUR:    10,    // Saatda max QR skan
    MAX_WEIGHT_PER_DAY:    5000,  // Gündəlik max çəki (qram)
    MAX_EP_PER_DAY:        5000,  // Gündəlik max EP qazanma
    MIN_SCAN_INTERVAL_MS:  15000, // 2 skan arası min. 15 saniyə
    SUSPICIOUS_WEIGHT:     10000, // 10kq+ şübhəlidir
    DEVICE_FINGERPRINT_KEY:'ep_device_fp',
  };

  // ── Cihaz Barmaq İzi ──
  function getDeviceFingerprint() {
    let fp = localStorage.getItem(CFG.DEVICE_FINGERPRINT_KEY);
    if (!fp) {
      const raw = [
        navigator.userAgent,
        navigator.language,
        screen.width + 'x' + screen.height,
        navigator.hardwareConcurrency || 0,
        Intl.DateTimeFormat().resolvedOptions().timeZone
      ].join('|');
      // Sadə hash
      fp = btoa(raw).replace(/[^a-zA-Z0-9]/g,'').slice(0, 32);
      localStorage.setItem(CFG.DEVICE_FINGERPRINT_KEY, fp);
    }
    return fp;
  }

  // ── QR Skan Sürəti Yoxlaması ──
  async function validateScanRate(uid) {
    const now = Date.now();
    const oneHourAgo = now - 3600000;

    // Son saatdakı skanları say
    const snap = await db.ref(`users/${uid}/scanLog`)
      .orderByChild('ts')
      .startAt(oneHourAgo)
      .once('value');

    const scansLastHour = snap.numChildren();

    if (scansLastHour >= CFG.MAX_SCANS_PER_HOUR) {
      await flagSuspicious(uid, 'RATE_LIMIT', `Saatda ${scansLastHour} skan`);
      throw new Error(`⚠️ Saatda maksimum ${CFG.MAX_SCANS_PER_HOUR} skan icazə verilir`);
    }

    // Son skanın vaxtını yoxla
    const lastScanSnap = await db.ref(`users/${uid}/lastScan`).once('value');
    const lastScan = lastScanSnap.val() || 0;

    if (now - lastScan < CFG.MIN_SCAN_INTERVAL_MS) {
      const waitSec = Math.ceil((CFG.MIN_SCAN_INTERVAL_MS - (now - lastScan)) / 1000);
      throw new Error(`⏳ ${waitSec} saniyə gözləyin`);
    }

    return true;
  }

  // ── Çəki Məlumatı Doğrulaması ──
  async function validateWeightData(uid, weightGrams, deviceId) {
    const now = Date.now();

    // 1. Ağırlıq limitini yoxla
    if (weightGrams > CFG.SUSPICIOUS_WEIGHT) {
      await flagSuspicious(uid, 'EXCESSIVE_WEIGHT', `${weightGrams}q`);
      throw new Error('Anormal çəki aşkarlandı. Sistem administratoruna bildirildi.');
    }

    // 2. Cihazın autentikliyini yoxla
    const deviceSnap = await db.ref(`devices/${deviceId}`).once('value');
    if (!deviceSnap.exists()) {
      await flagSuspicious(uid, 'UNKNOWN_DEVICE', deviceId);
      throw new Error('Bu cihaz qeydiyyatda deyil');
    }

    const device = deviceSnap.val();

    // 3. Cihaz aktiv siqnalı yoxla (son 60 saniyə)
    if (!device.lastSeen || (now - device.lastSeen > 60000)) {
      throw new Error('Cihaz oflayn görünür. Növbəti canlı siqnal gözlənir.');
    }

    // 4. Cihazın bildirdiyi çəki ilə istifadəçi tələbini müqayisə et
    const deviceWeight = device.weight || 0;
    const tolerance = 50; // 50 qram fərq icazə verilir

    if (Math.abs(deviceWeight - weightGrams) > tolerance) {
      await flagSuspicious(uid, 'WEIGHT_MISMATCH',
        `Cihaz: ${deviceWeight}q, Tələb: ${weightGrams}q`);
      throw new Error('Çəki məlumatı uyğun gəlmir. Cihaz dəyərini gözləyin.');
    }

    // 5. Gündəlik çəki limitini yoxla
    const todayStart = new Date(); todayStart.setHours(0,0,0,0);
    const daySnap = await db.ref(`users/${uid}/dailyWeight`)
      .orderByChild('ts')
      .startAt(todayStart.getTime())
      .once('value');

    let dailyWeight = 0;
    daySnap.forEach(c => { dailyWeight += (c.val().grams || 0); });

    if (dailyWeight + weightGrams > CFG.MAX_WEIGHT_PER_DAY) {
      throw new Error(`Gündəlik limit: ${CFG.MAX_WEIGHT_PER_DAY}q. Artıq: ${dailyWeight}q`);
    }

    return true;
  }

  // ── Gündəlik EP Limitini Yoxla ──
  async function validateDailyEPLimit(uid, epToAdd) {
    const todayStart = new Date(); todayStart.setHours(0,0,0,0);

    const snap = await db.ref(`users/${uid}/dailyEarned`)
      .orderByChild('ts')
      .startAt(todayStart.getTime())
      .once('value');

    let dailyEarned = 0;
    snap.forEach(c => { dailyEarned += (c.val().ep || 0); });

    if (dailyEarned + epToAdd > CFG.MAX_EP_PER_DAY) {
      await flagSuspicious(uid, 'DAILY_EP_LIMIT',
        `Gündəlik: ${dailyEarned} + ${epToAdd} > ${CFG.MAX_EP_PER_DAY}`);
      throw new Error(`Gündəlik maksimum ${CFG.MAX_EP_PER_DAY} EP qazanmaq mümkündür`);
    }
    return true;
  }

  // ── Şübhəli fəaliyyəti qeydə al ──
  async function flagSuspicious(uid, reason, detail) {
    console.warn(`[SECURITY] ${uid}: ${reason} — ${detail}`);
    await db.ref(`security/flags`).push({
      uid,
      reason,
      detail,
      deviceFP: getDeviceFingerprint(),
      ts: Date.now()
    });
    // Admin bildirişi
    await db.ref(`users/${uid}/warnings`).transaction(cur => (cur || 0) + 1);
  }

  // ── İstifadəçi qadağasını yoxla ──
  async function checkUserBan(uid) {
    const snap = await db.ref(`security/banned/${uid}`).once('value');
    if (snap.val()) throw new Error('Hesabınız müvəqqəti bloklanmışdır. Dəstəklə əlaqə saxlayın.');
    return false;
  }

  // ── EP ödənişindən əvvəl tam yoxlama paketi ──
  async function runFullSecurityCheck(uid, epAmount, context) {
    await checkUserBan(uid);

    if (context === 'scan') {
      await validateScanRate(uid);
    }

    if (context === 'weight') {
      await validateDailyEPLimit(uid, epAmount);
    }

    // Cihaz barmaq izini yaz
    await db.ref(`users/${uid}/devices/${getDeviceFingerprint()}`).set({
      lastSeen: Date.now(),
      ua: navigator.userAgent.slice(0, 80)
    });

    return true;
  }

  return {
    getDeviceFingerprint,
    validateScanRate,
    validateWeightData,
    validateDailyEPLimit,
    flagSuspicious,
    checkUserBan,
    runFullSecurityCheck,
    CFG
  };
})();


/* ═══════════════════════════════════════════════════════════════
   MODUL 3B: FİREBASE SECURITY RULES
   Bu qaydaları Firebase Console → Realtime Database → Rules bölməsinə kopyalayın
   ═══════════════════════════════════════════════════════════════ */

const FIREBASE_SECURITY_RULES = `
{
  "rules": {
    "users": {
      "$uid": {
        // Özü oxuya bilər; başqaları da oxuya bilər (leaderboard, transfer üçün)
        ".read": "auth !== null",

        "balance": {
          // Özü yaza bilər (öz balansını azaldır) VƏ ya başqası yaza bilər (transfer alır)
          // Validate: yeni dəyər >= 0 olmalıdır (mənfi balans olmaz)
          ".write": "auth !== null",
          ".validate": "newData.isNumber() && newData.val() >= 0 && newData.val() <= 9999999"
        },

        "stats": {
          ".write": "auth !== null && auth.uid === $uid",
          "earned": {
            ".validate": "newData.isNumber() && newData.val() >= 0"
          },
          "scans": {
            ".validate": "newData.isNumber() && newData.val() >= 0"
          }
        },

        "transactions": {
          "$txId": {
            // Özü yaza bilər VƏ başqası da yaza bilər (transfer bildirişi üçün)
            ".write": "auth !== null",
            ".validate": "newData.hasChildren(['type','amount','desc','ts'])"
          }
        },

        "incoming": {
          // Gələn köçürmələr — istənilən autentifikasiyalı user yaza bilər
          "$txId": {
            ".write": "auth !== null",
            ".validate": "newData.hasChildren(['from','amount','ts'])"
          }
        },

        "iot": {
          ".write": "auth !== null && auth.uid === $uid"
        },

        "scanLog": {
          "$logId": {
            ".write": "auth !== null && auth.uid === $uid"
          }
        },

        "lastScan": {
          ".write": "auth !== null && auth.uid === $uid"
        },

        "coupons": {
          "$couponId": {
            ".write": "auth !== null && auth.uid === $uid"
          }
        },

        "devices": {
          "$fp": {
            ".write": "auth !== null && auth.uid === $uid"
          }
        },

        // Admin-only sahələr
        "warnings": {
          ".write": false,
          ".read": "auth !== null && auth.uid === $uid"
        }
      }
    },

    "scans": {
      "$scanKey": {
        ".read": "auth !== null",
        ".write": "auth !== null"
      }
    },

    "devices": {
      // Cihaz məlumatları yalnız oxunaqdır (ESP32 server-side yazır)
      ".read": "auth !== null",
      "$deviceId": {
        ".write": false  // Yalnız server-side (trusted admin) yaza bilər
      }
    },

    "coupons": {
      "$code": {
        ".read": "auth !== null",
        // Kupon yalnız bir dəfə yaranır, sonra dəyişdirilə bilməz
        ".write": "auth !== null && !data.exists()"
      }
    },

    "transfers": {
      "$transferId": {
        ".read": "auth !== null",
        ".write": "auth !== null"
      }
    },

    "analytics": {
      ".read": false,
      ".write": "auth !== null"
    },

    "globalNotifications": {
      ".read": "auth !== null",
      ".write": "auth !== null"
    },

    "security": {
      "flags": {
        ".write": "auth !== null",
        ".read": false
      },
      "devtools": {
        ".write": "auth !== null",
        ".read": false
      },
      "banned": {
        ".read": "auth !== null",
        ".write": false
      }
    },

    "leaderboard": {
      ".read": true,
      ".write": false
    }
  }
}`;


/* ═══════════════════════════════════════════════════════════════
   MODUL 3C: KOD QORUMA (BUILD SİSTEMİ)
   Netlify ilə istifadə üçün netlify.toml + build skript
   ═══════════════════════════════════════════════════════════════ */

/* ── netlify.toml məzmunu ──
[build]
  command = "npm run build"
  publish = "dist"

[[headers]]
  for = "/*"
  [headers.values]
    X-Content-Type-Options = "nosniff"
    X-Frame-Options = "DENY"
    X-XSS-Protection = "1; mode=block"
    Content-Security-Policy = "default-src 'self'; script-src 'self' 'unsafe-inline' https://www.gstatic.com https://cdn.jsdelivr.net https://cdnjs.cloudflare.com; connect-src 'self' https://*.firebaseio.com wss://*.firebaseio.com https://firebaseinstallations.googleapis.com; img-src 'self' data: https:; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com https://cdnjs.cloudflare.com; font-src 'self' https://fonts.gstatic.com https://cdnjs.cloudflare.com;"
    Referrer-Policy = "strict-origin-when-cross-origin"

[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200
*/

/* ── package.json build skripti ──
{
  "scripts": {
    "build": "npm run minify:js && npm run minify:css && npm run obfuscate",
    "minify:js": "terser app.js ecopoint-iot-module.js ecopoint-marketplace-module.js ecopoint-security-module.js -o dist/app.min.js --compress --mangle",
    "minify:css": "cleancss style.css -o dist/style.min.css",
    "obfuscate": "javascript-obfuscator dist/app.min.js --output dist/app.min.js --compact true --string-array true --rotate-string-array true --string-array-encoding rc4 --dead-code-injection true --dead-code-injection-threshold 0.3"
  },
  "devDependencies": {
    "terser": "^5.30.0",
    "clean-css-cli": "^5.6.3",
    "javascript-obfuscator": "^4.1.1"
  }
}
*/

/* ── index.html-də integrity hash ilə script çağırışı ──
<script src="/app.min.js"
        integrity="sha384-HASH_BURAYA"
        crossorigin="anonymous"
        defer>
</script>

Note: SHA384 hash-i build zamanı `openssl dgst -sha384 -binary app.min.js | openssl base64 -A` ilə hesablayın
*/

/* ── Əlavə Qoruma: DevTools aşkarlaması ──
Mühüm: Bu metod tam qoruma vermir, lakin casual view-source-u çətinləşdirir.
Real qoruma üçün yuxarıdakı obfuscation + Firebase security rules daha effektivdir.
*/

(function devToolsDetect() {
  // Production-da aktivdir; development-də söndür
  if (location.hostname === 'localhost' || location.hostname === '127.0.0.1') return;

  let devtoolsOpen = false;
  const threshold = 160;

  const check = () => {
    if (window.outerWidth - window.innerWidth > threshold ||
        window.outerHeight - window.innerHeight > threshold) {
      if (!devtoolsOpen) {
        devtoolsOpen = true;
        // Sadəcə loq; tətbiqi bağlamaq UX-i pozur
        console.warn('[EcoPoint] DevTools aşkarlandı');
        db.ref('security/devtools').push({
          uid: typeof UID !== 'undefined' ? UID : 'guest',
          ts: Date.now(),
          url: location.href
        }).catch(() => {});
      }
    } else {
      devtoolsOpen = false;
    }
  };

  setInterval(check, 1500);
})();


/* ── Right-click & keyboard shortcut bloku ──
Qeyd: Bunlar yalnız sıradan istifadəçiləri məhdudlaşdırır.
*/
(function basicProtection() {
  if (location.hostname === 'localhost') return;

  // Sağ klik
  document.addEventListener('contextmenu', e => {
    e.preventDefault();
    return false;
  });

  // F12, Ctrl+U, Ctrl+Shift+I, Ctrl+Shift+J
  document.addEventListener('keydown', e => {
    if (e.key === 'F12' ||
        (e.ctrlKey && e.key === 'u') ||
        (e.ctrlKey && e.shiftKey && ['i','j','c'].includes(e.key.toLowerCase()))) {
      e.preventDefault();
      return false;
    }
  });
})();
