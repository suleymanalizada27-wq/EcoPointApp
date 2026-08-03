/* ═══════════════════════════════════════════════════════════════════════
   ECOPOINT PRO — ABUNƏLİK MODELİ  v1.0
   $5/ay  ·  2× Multiplier  ·  Zero-Fee  ·  Gold Voucher  ·  IoT Alert
   ═══════════════════════════════════════════════════════════════════════ */

'use strict';

const ProModule = (() => {

  /* ── Sabitlər ── */
  const PRO_PRICE_USD      = 5;
  const IOT_FILL_THRESHOLD = 80;

  /* ── Cari Pro vəziyyəti ── */
  let _isPro       = false;
  let _proListener = null;

  /* ────────────────────────────────────────────────────────
     1. FİREBASE — Pro statusunu canlı izlə
  ──────────────────────────────────────────────────────── */
  function init(uid) {
    if (!uid) { _isPro = false; _renderAll(); return; }
    if (_proListener) db.ref(`users/${uid}/isPro`).off('value', _proListener);

    _proListener = db.ref(`users/${uid}/isPro`).on('value', snap => {
      _isPro = snap.val() === true;
      _renderAll();
    });
  }

  function reset() {
    _isPro = false;
    _proListener = null;
    _renderAll();
  }

  function isPro() { return _isPro; }

  /* ────────────────────────────────────────────────────────
     2. PRO-YA KEÇ
  ──────────────────────────────────────────────────────── */
  async function upgradeToPro() {
    if (!UID) { showToast('Əvvəlcə hesabınıza daxil olun', 'err'); return; }
    if (_isPro) { showToast('Artıq Pro istifadəçisisiniz! 🚀', 'ok'); return; }

    const confirmed = await _showPaywall();
    if (!confirmed) return;

    try {
      await db.ref(`users/${UID}`).update({
        isPro:     true,
        proSince:  Date.now(),
        proExpiry: Date.now() + 30 * 24 * 60 * 60 * 1000
      });
      await db.ref('analytics/proSubscriptions').push({ uid: UID, ts: Date.now() });

      showToast('🚀 EcoPoint PRO aktiv oldu! Bütün üstünlüklər sizindir.', 'ok');
      epPopup && epPopup(0, '🚀 PRO!');
      launchConfetti && launchConfetti();
    } catch (e) {
      showToast('Xəta baş verdi, yenidən cəhd edin.', 'err');
    }
  }

  /* ────────────────────────────────────────────────────────
     3. Köməkçi metodlar (digər modullar istifadə edir)
  ──────────────────────────────────────────────────────── */
  function applyMultiplier(base) { return _isPro ? base * 2 : base; }
  function getCommissionRate()   { return _isPro ? 0 : 0.05; }
  function getEpToAznRate(base)  { return _isPro ? (base || 0.001) * 1.2 : (base || 0.001); }

  /* IoT doluluq bildirişi */
  function checkFillAlert(fillPct, devName) {
    if (!_isPro || fillPct < IOT_FILL_THRESHOLD) return;
    _showFillAlert(fillPct, devName);
  }

  /* ────────────────────────────────────────────────────────
     4. UI RENDER
  ──────────────────────────────────────────────────────── */
  function _renderAll() {
    document.querySelectorAll('.pro-status-box').forEach(box => {
      box.innerHTML = _isPro ? _proHTML() : _freeHTML();
    });
  }

  function _proHTML() {
    return `
    <div class="psb-active">
      <div class="psb-glow"></div>
      <div class="psb-badge-row">
        <span class="psb-rocket">🚀</span>
        <span class="psb-title-text">EcoPoint PRO</span>
        <span class="psb-crown">👑</span>
      </div>
      <div class="psb-perks-row">
        <span class="psb-perk">⚡ 2× Xal</span>
        <span class="psb-perk">🎟️ 0% Komissiya</span>
        <span class="psb-perk">💎 Gold Rate</span>
        <span class="psb-perk">📡 IoT Alert</span>
      </div>
      <div class="psb-active-pill">✦ AKTİV ABUNƏLİK</div>
    </div>`;
  }

  function _freeHTML() {
    return `
    <div class="psb-free">
      <div class="psb-free-top">
        <span class="psb-free-label">EcoPoint Free</span>
        <span class="psb-free-pill">PULSUZ</span>
      </div>
      <div class="psb-items">
        <div class="psb-item"><span class="psb-item-ico">⚡</span><div><div class="psb-item-t">2× Xal Multiplier</div><div class="psb-item-s">Hər tullantıdan 2 dəfə çox EP qazanın</div></div></div>
        <div class="psb-item"><span class="psb-item-ico">🎟️</span><div><div class="psb-item-t">Zero-Fee Kuponlar</div><div class="psb-item-s">5% komissiya yox — tam dəyər sizin</div></div></div>
        <div class="psb-item"><span class="psb-item-ico">💎</span><div><div class="psb-item-t">Gold Voucher Rate</div><div class="psb-item-s">1000 EP = 1.2 AZN (standart 1.0)</div></div></div>
        <div class="psb-item"><span class="psb-item-ico">📡</span><div><div class="psb-item-t">IoT Prioritet Bildirişlər</div><div class="psb-item-s">Qutu dolu — siz ilk bilirsiniz, 2× xal</div></div></div>
      </div>
      <button class="psb-upgrade-btn" onclick="ProModule.upgradeToPro()">
        <span>🚀 PRO-YA KEÇ</span><span class="psb-price">$${PRO_PRICE_USD}/ay</span>
      </button>
      <div class="psb-proof"><span>👤👤👤</span><span>+2.4K istifadəçi artıq PRO-da</span></div>
    </div>`;
  }

  /* ────────────────────────────────────────────────────────
     5. PAYWALL MODALI
  ──────────────────────────────────────────────────────── */
  function _showPaywall() {
    return new Promise(resolve => {
      document.getElementById('pro-paywall')?.remove();

      const el = document.createElement('div');
      el.id = 'pro-paywall';
      el.innerHTML = `
        <div class="ppw-bg" id="ppw-bg"></div>
        <div class="ppw-sheet" id="ppw-sheet">
          <div class="ppw-stars" aria-hidden="true">${
            Array.from({length:20},(_,i)=>`<div class="ppw-star" style="--i:${i}"></div>`).join('')
          }</div>
          <div class="ppw-logo-wrap"><div class="ppw-ring"></div><div class="ppw-logo-emoji">🚀</div></div>
          <div class="ppw-h1">EcoPoint PRO</div>
          <div class="ppw-sub">Dünyaya daha böyük təsir et. Daha çox qazan.</div>
          <div class="ppw-feats">
            <div class="ppw-feat"><span class="ppw-dot">✦</span><div><strong>2× Xal Multiplier</strong> — eyni tullantıdan 2 dəfə çox EP</div></div>
            <div class="ppw-feat"><span class="ppw-dot">✦</span><div><strong>Zero-Fee Kuponlar</strong> — 5% komissiya silindi</div></div>
            <div class="ppw-feat"><span class="ppw-dot">✦</span><div><strong>Gold Voucher Rate</strong> — EP-niz 20% daha dəyərli</div></div>
            <div class="ppw-feat"><span class="ppw-dot">✦</span><div><strong>IoT Ani Bildirişlər</strong> — qutu dolar, siz ilk bilirsiniz</div></div>
            <div class="ppw-feat"><span class="ppw-dot">✦</span><div><strong>Pro Badge</strong> — cəmiyyətdə fərqlənin</div></div>
          </div>
          <div class="ppw-price-box">
            <div class="ppw-amount"><span class="ppw-cur">$</span><span class="ppw-num">${PRO_PRICE_USD}</span><span class="ppw-per">/ay</span></div>
            <div class="ppw-saving">Gündə cəmi 17 qəpik!</div>
          </div>
          <button class="ppw-cta" id="ppw-ok">⚡ PRO-YA KEÇ — İndi Başla</button>
          <button class="ppw-skip" id="ppw-skip">Hələlik pulsuz davam et</button>
          <div class="ppw-trust">🔒 Təhlükəsiz · İstənilən vaxt ləğv · 30 gün pulsuz sınaq</div>
        </div>`;

      document.body.appendChild(el);
      requestAnimationFrame(() => el.classList.add('ppw-on'));

      const close = (val) => { el.classList.remove('ppw-on'); setTimeout(() => el.remove(), 380); resolve(val); };
      document.getElementById('ppw-ok').onclick   = () => close(true);
      document.getElementById('ppw-skip').onclick = () => close(false);
      document.getElementById('ppw-bg').onclick   = () => close(false);
    });
  }

  /* ────────────────────────────────────────────────────────
     6. IoT DOLULUQ XƏBƏRDARLIĞı
  ──────────────────────────────────────────────────────── */
  const _shownAlerts = new Set();

  function _showFillAlert(fillPct, devName) {
    const key = `${devName}-${Math.floor(fillPct/10)}`;
    if (_shownAlerts.has(key)) return;
    _shownAlerts.add(key);

    const el = document.createElement('div');
    el.className = 'iot-pro-alert';
    el.innerHTML = `
      <div class="ipa-pulse"></div>
      <span class="ipa-ico">📡</span>
      <div class="ipa-body">
        <div class="ipa-title">Yerlər məhduddur — Tez Hərəkət Et!</div>
        <div class="ipa-desc"><strong>${escHtml(devName)}</strong> ${fillPct}% doludur. İndi get, <span class="ipa-em">2× xal</span> qazan! 🏆</div>
      </div>
      <button class="ipa-x" onclick="this.closest('.iot-pro-alert').remove()">✕</button>`;

    document.body.appendChild(el);
    requestAnimationFrame(() => el.classList.add('ipa-on'));
    if (navigator.vibrate) navigator.vibrate([25, 50, 25]);

    setTimeout(() => { el.classList.remove('ipa-on'); setTimeout(() => el.remove(), 400); }, 12000);
  }

  /* ────────────────────────────────────────────────────────
     7. STİLLƏR
  ──────────────────────────────────────────────────────── */
  (function injectCSS() {
    const s = document.createElement('style');
    s.id = 'pro-module-css';
    s.textContent = `

/* ═══════════ PRO STATUS BOX ═══════════ */
.pro-status-box { margin: 14px 0; }

/* ── Aktiv (Pro) ── */
.psb-active {
  position: relative;
  background: linear-gradient(135deg, #081408 0%, #04100a 100%);
  border: 1px solid rgba(0,255,122,.28);
  border-radius: 20px;
  padding: 18px 20px;
  overflow: hidden;
}
.psb-glow {
  position: absolute; top: -50px; right: -50px;
  width: 160px; height: 160px; border-radius: 50%;
  background: radial-gradient(circle, rgba(0,255,122,.16) 0%, transparent 70%);
  pointer-events: none;
}
.psb-badge-row { display: flex; align-items: center; gap: 8px; margin-bottom: 12px; }
.psb-rocket { font-size: 22px; }
.psb-title-text {
  font-size: 18px; font-weight: 800; letter-spacing: .4px;
  background: linear-gradient(90deg, #00ff7a, #00e5c8, #00bfff);
  -webkit-background-clip: text; -webkit-text-fill-color: transparent; background-clip: text;
}
.psb-crown { font-size: 18px; margin-left: auto; }
.psb-perks-row { display: flex; flex-wrap: wrap; gap: 6px; margin-bottom: 14px; }
.psb-perk {
  font-size: 11px; font-weight: 600; color: rgba(0,255,122,.85);
  background: rgba(0,255,122,.07); border: 1px solid rgba(0,255,122,.18);
  border-radius: 100px; padding: 4px 10px;
}
.psb-active-pill {
  display: inline-block; font-size: 10px; font-weight: 700; letter-spacing: 1.4px;
  color: #010a06; background: linear-gradient(90deg,#00ff7a,#00e5c8);
  border-radius: 100px; padding: 4px 14px;
}

/* ── Pulsuz ── */
.psb-free {
  background: rgba(255,255,255,.03);
  border: 1px solid rgba(255,255,255,.09);
  border-radius: 20px; padding: 18px;
}
.psb-free-top { display: flex; align-items: center; justify-content: space-between; margin-bottom: 16px; }
.psb-free-label { font-size: 15px; font-weight: 700; color: var(--t1,#e0e0e0); }
.psb-free-pill {
  font-size: 9px; font-weight: 700; letter-spacing: 1.4px;
  color: var(--t2,#888); background: rgba(255,255,255,.07);
  border: 1px solid rgba(255,255,255,.12); border-radius: 100px; padding: 3px 9px;
}
.psb-items { display: flex; flex-direction: column; gap: 11px; margin-bottom: 18px; }
.psb-item { display: flex; align-items: flex-start; gap: 11px; }
.psb-item-ico {
  font-size: 18px; flex-shrink: 0; width: 34px; height: 34px;
  display: flex; align-items: center; justify-content: center;
  background: rgba(0,255,122,.06); border: 1px solid rgba(0,255,122,.13);
  border-radius: 10px;
}
.psb-item-t { font-size: 13px; font-weight: 700; color: var(--t1,#e0e0e0); margin-bottom: 2px; }
.psb-item-s { font-size: 11px; color: var(--t2,#888); line-height: 1.4; }

.psb-upgrade-btn {
  width: 100%; display: flex; align-items: center; justify-content: center; gap: 10px;
  padding: 16px; border: none; border-radius: 14px; cursor: pointer; margin-bottom: 12px;
  background: linear-gradient(135deg, #00ff7a, #00c8a8 50%, #0090e8);
  background-size: 200%; animation: proGrad 3s ease infinite;
  color: #010a06; font-size: 15px; font-weight: 800; letter-spacing: .3px;
  box-shadow: 0 4px 24px rgba(0,255,122,.24); transition: transform .18s;
}
.psb-upgrade-btn:active { transform: scale(.97); }
.psb-price { font-size: 12px; font-weight: 600; opacity: .7; }
.psb-proof { display: flex; align-items: center; justify-content: center; gap: 7px; font-size: 11px; color: var(--t2,#888); }

@keyframes proGrad { 0%,100%{background-position:0% 50%} 50%{background-position:100% 50%} }

/* ═══════════ PAYWALL ═══════════ */
#pro-paywall {
  position: fixed; inset: 0; z-index: 9990;
  display: flex; align-items: flex-end;
  opacity: 0; pointer-events: none; transition: opacity .3s ease;
}
#pro-paywall.ppw-on { opacity: 1; pointer-events: all; }
.ppw-bg { position: absolute; inset: 0; background: rgba(0,0,0,.72); backdrop-filter: blur(7px); -webkit-backdrop-filter: blur(7px); }

.ppw-sheet {
  position: relative; z-index: 1; width: 100%; max-width: 480px; margin: 0 auto;
  background: linear-gradient(180deg, #071510 0%, #040d09 100%);
  border: 1px solid rgba(0,255,122,.2);
  border-radius: 28px 28px 0 0;
  padding: 28px 22px 38px; overflow: hidden;
  transform: translateY(50px);
  transition: transform .45s cubic-bezier(.34,1.56,.64,1);
}
#pro-paywall.ppw-on .ppw-sheet { transform: translateY(0); }

/* Stars */
.ppw-stars { position: absolute; inset: 0; pointer-events: none; overflow: hidden; }
.ppw-star {
  position: absolute;
  width: 3px; height: 3px; border-radius: 50%;
  background: rgba(0,255,122,.7);
  top: calc(var(--i) * 5%);
  left: calc(var(--i) * 5.2% + 2%);
  animation: ppwTwinkle calc(1.8s + var(--i) * .08s) ease-in-out infinite alternate;
  opacity: .3;
}
@keyframes ppwTwinkle { from{opacity:.15;transform:scale(.7)} to{opacity:.9;transform:scale(1.3)} }

.ppw-logo-wrap {
  position: relative; width: 68px; height: 68px;
  margin: 0 auto 14px; display: flex; align-items: center; justify-content: center;
}
.ppw-ring {
  position: absolute; inset: 0; border-radius: 50%;
  border: 2px solid transparent;
  background: linear-gradient(135deg,#00ff7a,#00e5c8,#0090e8) border-box;
  -webkit-mask: linear-gradient(#fff 0 0) padding-box, linear-gradient(#fff 0 0);
  -webkit-mask-composite: destination-out; mask-composite: exclude;
  animation: ppwSpin 4s linear infinite;
}
@keyframes ppwSpin { to{transform:rotate(360deg)} }
.ppw-logo-emoji { font-size: 30px; position: relative; z-index: 1; }

.ppw-h1 {
  font-size: 23px; font-weight: 800; text-align: center; margin-bottom: 5px;
  background: linear-gradient(90deg,#00ff7a,#00e5c8,#00bfff);
  -webkit-background-clip: text; -webkit-text-fill-color: transparent; background-clip: text;
}
.ppw-sub { font-size: 12px; color: rgba(255,255,255,.5); text-align: center; margin-bottom: 20px; }
.ppw-feats { display: flex; flex-direction: column; gap: 11px; margin-bottom: 20px; }
.ppw-feat { display: flex; align-items: flex-start; gap: 10px; font-size: 13px; color: rgba(255,255,255,.82); line-height: 1.45; }
.ppw-dot { color: #00ff7a; font-size: 13px; font-weight: 700; flex-shrink: 0; margin-top: 1px; }

.ppw-price-box {
  display: flex; align-items: center; gap: 14px; margin-bottom: 18px;
  background: rgba(0,255,122,.05); border: 1px solid rgba(0,255,122,.14);
  border-radius: 14px; padding: 13px 18px;
}
.ppw-amount { display: flex; align-items: baseline; gap: 2px; }
.ppw-cur { font-size: 17px; font-weight: 700; color: #00ff7a; }
.ppw-num { font-size: 42px; font-weight: 900; color: #00ff7a; letter-spacing: -2px; }
.ppw-per { font-size: 13px; color: rgba(0,255,122,.6); margin-left: 2px; }
.ppw-saving { font-size: 11px; color: rgba(255,255,255,.45); }

.ppw-cta {
  width: 100%; padding: 17px; border: none; border-radius: 15px; cursor: pointer;
  background: linear-gradient(135deg,#00ff7a,#00c8a8,#0090e8); background-size: 200%;
  animation: proGrad 3s ease infinite;
  color: #010a06; font-size: 16px; font-weight: 800; letter-spacing: .4px;
  margin-bottom: 11px; box-shadow: 0 6px 32px rgba(0,255,122,.28);
  transition: transform .18s;
}
.ppw-cta:active { transform: scale(.98); }
.ppw-skip {
  display: block; width: 100%; padding: 11px; background: none; border: none;
  color: rgba(255,255,255,.3); font-size: 13px; cursor: pointer; text-align: center;
  margin-bottom: 14px; transition: color .2s;
}
.ppw-skip:hover { color: rgba(255,255,255,.6); }
.ppw-trust { font-size: 10px; color: rgba(255,255,255,.28); text-align: center; }

/* ═══════════ IoT PRO ALERT ═══════════ */
.iot-pro-alert {
  position: fixed; top: 16px; left: 50%;
  transform: translateX(-50%) translateY(-130%);
  z-index: 8800;
  width: calc(100% - 32px); max-width: 420px;
  display: flex; align-items: center; gap: 11px;
  background: linear-gradient(135deg,#0e2418,#071510);
  border: 1.5px solid rgba(0,255,122,.38); border-radius: 18px;
  padding: 13px 15px;
  box-shadow: 0 8px 40px rgba(0,0,0,.55);
  transition: transform .5s cubic-bezier(.34,1.56,.64,1);
}
.iot-pro-alert.ipa-on { transform: translateX(-50%) translateY(0); }
.ipa-pulse {
  position: absolute; top: -10px; left: -10px;
  width: 60px; height: 60px; border-radius: 50%;
  background: radial-gradient(circle,rgba(0,255,122,.15) 0%,transparent 70%);
  animation: ipaPulse 2s ease-in-out infinite; pointer-events: none;
}
@keyframes ipaPulse { 0%,100%{transform:scale(1);opacity:.5} 50%{transform:scale(1.4);opacity:1} }
.ipa-ico { font-size: 24px; flex-shrink: 0; position: relative; z-index: 1; }
.ipa-body { flex: 1; min-width: 0; position: relative; z-index: 1; }
.ipa-title { font-size: 12px; font-weight: 800; color: #00ff7a; margin-bottom: 3px; }
.ipa-desc { font-size: 11px; color: rgba(255,255,255,.72); line-height: 1.4; }
.ipa-em { color: #00ff7a; font-weight: 700; }
.ipa-x {
  flex-shrink: 0; width: 24px; height: 24px; border-radius: 50%;
  border: 1px solid rgba(255,255,255,.12); background: rgba(255,255,255,.05);
  color: rgba(255,255,255,.45); font-size: 11px; cursor: pointer;
  display: flex; align-items: center; justify-content: center;
  position: relative; z-index: 1; transition: background .2s, color .2s;
}
.ipa-x:hover { background: rgba(255,71,87,.2); color: #ff4757; }

    `;
    document.head.appendChild(s);
  })();

  /* ────────────────────────────────────────────────────────
     8. İLK RENDER — UID hələ yoxdursa Free göstər
  ──────────────────────────────────────────────────────── */
  setTimeout(() => { if (!_isPro) _renderAll(); }, 200);

  return { init, reset, isPro, upgradeToPro, applyMultiplier, getCommissionRate, getEpToAznRate, checkFillAlert };

})();
