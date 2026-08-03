/* ═══════════════════════════════════════════════════════════════
   ECOPOINT PRO — IoT SENSOR & CİHAZ İNTEQRASİYA MODULU
   ESP32 + Load Cell + Ultrasonic → Firebase → UI
   ═══════════════════════════════════════════════════════════════ */

// ─────────────────────────────────────────────
//  MODUL 1: IoT SENSOR İNTEQRASİYASI
// ─────────────────────────────────────────────

const IoTModule = (() => {

  // Firebase-dəki IoT məlumatlarının yolu
  // ESP32 bu yola məlumat yazır: /devices/{deviceId}/...
  const DEVICES_PATH = 'devices';
  const WEIGHT_PATH  = 'iot/weight';        // Canlı çəki (qram)
  const POINTS_PATH  = 'iot/pendingPoints'; // Hesablanmış xal (onaylamamış)

  // Xal dərəcəsi: hər 100 qrama görə neçə EP
  const POINT_RATE = 10; // 100q = 10 EP

  // Anti-cheat: son 5 dəqiqədə maksimum neçə dəfə çəki qeydə alına bilər
  const MAX_WEIGHT_EVENTS_PER_5MIN = 5;
  const MAX_SINGLE_WEIGHT_GRAMS   = 10000; // 10 kq üstü şübhəlidir

  let deviceListeners = {};
  let weightListener  = null;

  // ── 1a. Admin Panelindən Bütün Cihazları İzlə ──
  function startDeviceMonitoring() {
    db.ref(DEVICES_PATH).on('value', snapshot => {
      const devices = snapshot.val() || {};
      renderDeviceDashboard(devices);
    });
  }

  // ── 1b. Cihaz məlumatlarını Admin Panelində göstər ──
  function renderDeviceDashboard(devices) {
    const container = document.getElementById('iot-device-grid');
    if (!container) return;

    const entries = Object.entries(devices);
    if (entries.length === 0) {
      container.innerHTML = `
        <div class="iot-empty">
          <div class="iot-empty-ico">📡</div>
          <div>Heç bir cihaz qoşulmayıb</div>
        </div>`;
      return;
    }

    container.innerHTML = entries.map(([id, dev]) => {
      const fillPct   = Math.min(100, Math.max(0, dev.fillPercent || 0));
      const temp      = dev.temperature || 0;
      const lastSeen  = dev.lastSeen ? timeAgo(dev.lastSeen) : 'Bilinmir';
      const isOnline  = dev.lastSeen && (Date.now() - dev.lastSeen < 60000);
      const fillColor = fillPct > 80 ? '#ff4757' : fillPct > 50 ? '#ffa502' : '#00ff7a';

      // Pro IoT bildirişini yoxla
      if (typeof ProModule !== 'undefined' && ProModule.isPro()) {
        ProModule.checkFillAlert(fillPct, dev.name || id);
      }

      return `
      <div class="iot-device-card ${isOnline ? 'online' : 'offline'}">
        <div class="iot-dev-header">
          <div class="iot-dev-id">
            <div class="iot-status-dot" style="background:${isOnline ? '#00ff7a' : '#ff4757'}"></div>
            ${escHtml(dev.name || id)}
          </div>
          <div class="iot-dev-time">${lastSeen}</div>
        </div>

        <!-- Doluluq Sensoru (Ultrasonic) -->
        <div class="iot-metric">
          <div class="iot-metric-label">
            <span>📦 Doluluq</span>
            <strong style="color:${fillColor}">${fillPct}%</strong>
          </div>
          <div class="iot-fill-bar">
            <div class="iot-fill-inner" style="width:${fillPct}%;background:${fillColor}"></div>
          </div>
          ${fillPct > 80 ? `<div class="iot-alert">⚠️ Boşaldılmalıdır!</div>` : ''}
        </div>

        <!-- Temperatur Sensoru -->
        <div class="iot-metric">
          <div class="iot-metric-label">
            <span>🌡️ Temperatur</span>
            <strong style="color:${temp > 40 ? '#ff4757' : 'var(--t1)'}">${temp}°C</strong>
          </div>
        </div>

        <!-- Load Cell - Çəki -->
        <div class="iot-metric">
          <div class="iot-metric-label">
            <span>⚖️ Çəki</span>
            <strong>${(dev.weight || 0).toLocaleString()} q</strong>
          </div>
        </div>

        <!-- Cihazın yerləşdiyi yer -->
        <div class="iot-dev-footer">
          <span class="iot-location">📍 ${escHtml(dev.location || 'Məlum deyil')}</span>
          <button class="iot-action-btn" onclick="IoTModule.requestEmptyDevice('${id}')">
            🗑️ Boşalt
          </button>
        </div>
      </div>`;
    }).join('');
  }

  // ── 1c. İstifadəçi ekranında Canlı Çəki (Step 02) ──
  function startLiveWeightDisplay(deviceId) {
    // Əvvəlki listener-i sil
    if (weightListener) {
      db.ref(`${DEVICES_PATH}/${deviceId}/weight`).off('value', weightListener);
    }

    const weightEl  = document.getElementById('live-weight-value');
    const pointsEl  = document.getElementById('live-weight-points');
    const barEl     = document.getElementById('weight-progress-bar');

    weightListener = db.ref(`${DEVICES_PATH}/${deviceId}/weight`).on('value', snap => {
      const grams = Math.max(0, snap.val() || 0);

      // Çəkini göstər
      if (weightEl) weightEl.textContent = grams.toLocaleString();

      // Xalı hesabla (Step 03 məntiqi)
      const points = calculatePoints(grams, POINT_RATE);
      if (pointsEl) pointsEl.textContent = points;

      // Proqres çubuğu (maksimum 500q normaldır)
      if (barEl) {
        const pct = Math.min(100, (grams / 500) * 100);
        barEl.style.width = pct + '%';
        barEl.style.background = pct > 80 ? '#00ff7a' : 'var(--g1)';
      }

      // Pending xalı Firebase-ə yaz (təsdiq gözləyir)
      if (UID) {
        db.ref(`users/${UID}/${POINTS_PATH}`).set({ grams, points, ts: Date.now() });
      }
    });
  }

  function stopLiveWeightDisplay(deviceId) {
    if (weightListener) {
      db.ref(`${DEVICES_PATH}/${deviceId}/weight`).off('value', weightListener);
      weightListener = null;
    }
    if (UID) {
      db.ref(`users/${UID}/${POINTS_PATH}`).remove();
    }
  }

  // ── 1d. Boşaltma siqnalı (Admin) ──
  function requestEmptyDevice(deviceId) {
    db.ref(`${DEVICES_PATH}/${deviceId}/commands`).push({
      cmd: 'EMPTY',
      requestedBy: UID,
      ts: Date.now()
    });
    showToast('📡 Boşaltma siqnalı göndərildi', 'ok');
  }

  // Köməkçi: vaxt fərqi
  function timeAgo(ts) {
    const diff = Math.floor((Date.now() - ts) / 1000);
    if (diff < 60)  return diff + ' san əvvəl';
    if (diff < 3600) return Math.floor(diff/60) + ' dəq əvvəl';
    return Math.floor(diff/3600) + ' saat əvvəl';
  }

  return {
    startDeviceMonitoring,
    startLiveWeightDisplay,
    stopLiveWeightDisplay,
    requestEmptyDevice,
    POINT_RATE
  };
})();


/* ═══════════════════════════════════════════════════════════════
   MODUL 2: DİNAMİK XAL HESABLAMA (Step 02 + Step 03)
   ═══════════════════════════════════════════════════════════════ */

// ── Əsas Formula: weight / 100 * pointRate ──
function calculatePoints(weightGrams, pointRate = 10) {
  if (!weightGrams || weightGrams <= 0) return 0;
  return Math.floor(weightGrams / 100 * pointRate);
}

// ── Çəki-dən EP qazanma (Cihaz təsdiqindən sonra çağrılır) ──
async function redeemWeightPoints(deviceId) {
  if (!UID) { showToast('Əvvəlcə daxil olun', 'err'); return; }

  // ANTI-CHEAT: cihazın son skan vaxtını yoxla
  const lastRedeemSnap = await db.ref(`devices/${deviceId}/lastRedeem`).once('value');
  const lastRedeem = lastRedeemSnap.val() || 0;
  const cooldown = 30 * 1000; // 30 saniyə arası gözlə

  if (Date.now() - lastRedeem < cooldown) {
    showToast('⏳ Zəhmət olmasa bir az gözləyin', 'warn');
    return;
  }

  // Firebase-dən pending çəkini oxu
  const pendSnap = await db.ref(`users/${UID}/iot/pendingPoints`).once('value');
  const pend = pendSnap.val();
  if (!pend || pend.grams <= 0) {
    showToast('Tərəzi üzərində tullantı aşkarlanmadı', 'warn');
    return;
  }

  const { grams, points: basePoints } = pend;
  // Pro istifadəçi üçün 2x multiplier
  const isProUser = typeof ProModule !== 'undefined' && ProModule.isPro();
  const points = isProUser ? basePoints * 2 : basePoints;
  const proTag = isProUser ? ' ⚡ 2× PRO' : '';

  if (points <= 0) {
    showToast('Minimum çəki 100 qramdır', 'warn');
    return;
  }

  // Transaction ilə xalı əlavə et
  await db.ref(`users/${UID}/balance`).transaction(cur => (cur || 0) + points);
  await db.ref(`users/${UID}/stats/earned`).transaction(cur => (cur || 0) + points);

  // Cihaza son redeem vaxtını yaz
  await db.ref(`devices/${deviceId}`).update({
    lastRedeem: Date.now(),
    lastRedeemBy: UID,
    lastRedeemGrams: grams
  });

  // Pending-i sil
  await db.ref(`users/${UID}/iot/pendingPoints`).remove();

  // Log yaz
  addTx('weight', '+' + points, `⚖️ Çəki${proTag}: ${grams}q → ${points} EP`);

  showToast(`⚖️ ${grams}g tullantı → +${points} EP qazandınız!${proTag ? ' 🚀' : ' 🎉'}`, 'ok');
  epPopup(points);
  launchConfetti && launchConfetti();
}


// ── HTML: Çəki Ölçmə Bölməsi (Step 02 UI) ──
// Bu HTML-i Stats/Home səhifəsinə əlavə edin
const WEIGHT_SECTION_HTML = `
<div class="weight-section" id="weight-section">
  <div class="ws-header">
    <span class="ws-ico">⚖️</span>
    <div>
      <div class="ws-title">Çəki Ölçün</div>
      <div class="ws-sub">Tullantını cihaza qoyun, xal qazanın</div>
    </div>
  </div>

  <div class="ws-display">
    <div class="ws-weight-num">
      <span id="live-weight-value">0</span>
      <span class="ws-unit">gram</span>
    </div>
    <div class="ws-bar-wrap">
      <div class="ws-bar-bg">
        <div class="ws-bar-fill" id="weight-progress-bar" style="width:0%"></div>
      </div>
    </div>
    <div class="ws-points-row">
      <span class="ws-pts-label">Qazanacaqsınız:</span>
      <span class="ws-pts-val" id="live-weight-points">0</span>
      <span class="ws-pts-ep">EP</span>
    </div>
  </div>

  <button class="ws-redeem-btn" onclick="redeemWeightPoints('device001')">
    ✅ XAL QAZANIN
  </button>
  <div class="ws-hint">💡 Cihaz tərəzi üzərindəki tullantını avtomatik ölçür</div>
</div>`;


/* ─── CSS: Çəki Bölməsi Üçün Stillər ─── */
const WEIGHT_CSS = `
.weight-section {
  background: linear-gradient(135deg, rgba(0,255,122,0.06), rgba(0,255,122,0.02));
  border: 1px solid rgba(0,255,122,0.15);
  border-radius: 20px;
  padding: 20px;
  margin: 12px 0;
}
.ws-header {
  display: flex; align-items: center; gap: 12px; margin-bottom: 20px;
}
.ws-ico { font-size: 28px; }
.ws-title { font-size: 16px; font-weight: 700; color: var(--t1); }
.ws-sub   { font-size: 11px; color: var(--t2); }
.ws-display { text-align: center; margin: 16px 0; }
.ws-weight-num {
  font-size: 52px; font-weight: 800; color: var(--g1);
  font-variant-numeric: tabular-nums;
}
.ws-unit { font-size: 16px; color: var(--t2); margin-left: 4px; }
.ws-bar-wrap { margin: 12px auto; max-width: 240px; }
.ws-bar-bg {
  height: 8px; background: rgba(255,255,255,0.06);
  border-radius: 4px; overflow: hidden;
}
.ws-bar-fill {
  height: 100%; border-radius: 4px;
  background: var(--g1);
  transition: width 0.4s ease, background 0.3s;
}
.ws-points-row {
  display: flex; align-items: center; justify-content: center;
  gap: 6px; font-size: 14px; color: var(--t2); margin-top: 8px;
}
.ws-pts-val { font-size: 22px; font-weight: 700; color: var(--teal); }
.ws-pts-ep  { color: var(--teal); font-weight: 600; }
.ws-redeem-btn {
  width: 100%; padding: 14px;
  background: linear-gradient(135deg, var(--g1), var(--teal));
  border: none; border-radius: 14px; color: #010a06;
  font-size: 15px; font-weight: 800; cursor: pointer;
  letter-spacing: 0.5px; margin-top: 8px;
  transition: transform 0.15s, box-shadow 0.15s;
}
.ws-redeem-btn:active { transform: scale(0.97); }
.ws-hint { font-size: 11px; color: var(--t2); text-align: center; margin-top: 10px; }

/* IoT Admin Dashboard */
.iot-device-grid {
  display: grid; grid-template-columns: 1fr 1fr; gap: 10px; margin: 10px 0;
}
@media (max-width: 500px) { .iot-device-grid { grid-template-columns: 1fr; } }
.iot-device-card {
  background: rgba(255,255,255,0.03);
  border: 1px solid rgba(255,255,255,0.08);
  border-radius: 16px; padding: 14px;
}
.iot-device-card.online  { border-color: rgba(0,255,122,0.2); }
.iot-device-card.offline { border-color: rgba(255,71,87,0.2); opacity: 0.7; }
.iot-dev-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px; }
.iot-dev-id { display: flex; align-items: center; gap: 6px; font-weight: 600; font-size: 13px; }
.iot-status-dot { width: 7px; height: 7px; border-radius: 50%; flex-shrink: 0; }
.iot-dev-time { font-size: 10px; color: var(--t2); }
.iot-metric { margin-bottom: 10px; }
.iot-metric-label { display: flex; justify-content: space-between; font-size: 12px; color: var(--t2); margin-bottom: 5px; }
.iot-fill-bar { height: 6px; background: rgba(255,255,255,0.06); border-radius: 3px; overflow: hidden; }
.iot-fill-inner { height: 100%; border-radius: 3px; transition: width 0.6s ease, background 0.3s; }
.iot-alert { font-size: 10px; color: #ff4757; margin-top: 4px; }
.iot-dev-footer { display: flex; justify-content: space-between; align-items: center; margin-top: 10px; }
.iot-location { font-size: 11px; color: var(--t2); }
.iot-action-btn {
  font-size: 11px; padding: 4px 10px; background: rgba(255,71,87,0.1);
  border: 1px solid rgba(255,71,87,0.2); border-radius: 8px;
  color: #ff4757; cursor: pointer;
}
.iot-empty { text-align: center; padding: 24px; color: var(--t2); font-size: 13px; }
.iot-empty-ico { font-size: 36px; margin-bottom: 8px; }
`;

// ── Stilləri sayfaya əlavə et ──
(function injectWeightStyles() {
  const style = document.createElement('style');
  style.textContent = WEIGHT_CSS;
  document.head.appendChild(style);
})();
