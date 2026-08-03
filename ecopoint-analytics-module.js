/* ═══════════════════════════════════════════════════════════════
   ECOPOINT PRO — MALİYYƏ ANALİTİKASI & ADMIN PANEL
   Xokkey Çubuğu Artımı + Komissiya Gəlirləri Qrafikləri
   ═══════════════════════════════════════════════════════════════ */

// ─────────────────────────────────────────────
//  MODUL 4: ADMIN ANALİTİKA MODULU
// ─────────────────────────────────────────────

const AnalyticsModule = (() => {

  // Canvas-based yüngül chart engine (xarici kitabxanasız)
  class MicroChart {
    constructor(canvasId, options = {}) {
      this.canvas = document.getElementById(canvasId);
      if (!this.canvas) return;
      this.ctx = this.canvas.getContext('2d');
      this.opts = {
        color:     options.color     || '#00ff7a',
        fillColor: options.fillColor || 'rgba(0,255,122,0.12)',
        lineWidth: options.lineWidth  || 2.5,
        padding:   options.padding    || 20,
        showDots:  options.showDots   !== false,
        showGrid:  options.showGrid   !== false,
        animate:   options.animate    !== false,
        ...options
      };
      this.animFrame = null;
    }

    draw(labels, values) {
      if (!this.ctx || !values.length) return;
      const { canvas, ctx, opts } = this;
      const W = canvas.width, H = canvas.height;
      const pad = opts.padding;

      ctx.clearRect(0, 0, W, H);

      const max   = Math.max(...values) || 1;
      const min   = 0;
      const range = max - min || 1;
      const xStep = (W - 2*pad) / Math.max(values.length - 1, 1);

      const toX = i => pad + i * xStep;
      const toY = v => H - pad - ((v - min) / range) * (H - 2*pad);

      // Grid xətləri
      if (opts.showGrid) {
        ctx.strokeStyle = 'rgba(255,255,255,0.05)';
        ctx.lineWidth = 1;
        for (let g = 0; g <= 4; g++) {
          const y = H - pad - (g / 4) * (H - 2*pad);
          ctx.beginPath();
          ctx.moveTo(pad, y);
          ctx.lineTo(W - pad, y);
          ctx.stroke();
        }
      }

      // Gradient doldurma
      const grad = ctx.createLinearGradient(0, pad, 0, H - pad);
      grad.addColorStop(0, opts.fillColor.replace('0.12', '0.25'));
      grad.addColorStop(1, opts.fillColor.replace('0.12', '0.02'));

      ctx.beginPath();
      ctx.moveTo(toX(0), toY(values[0]));
      values.forEach((v, i) => {
        if (i === 0) return;
        // Smooth bezier
        const x0 = toX(i-1), y0 = toY(values[i-1]);
        const x1 = toX(i),   y1 = toY(v);
        const cx = (x0 + x1) / 2;
        ctx.bezierCurveTo(cx, y0, cx, y1, x1, y1);
      });
      ctx.lineTo(toX(values.length-1), H-pad);
      ctx.lineTo(toX(0), H-pad);
      ctx.closePath();
      ctx.fillStyle = grad;
      ctx.fill();

      // Əyri xətt
      ctx.beginPath();
      ctx.strokeStyle = opts.color;
      ctx.lineWidth = opts.lineWidth;
      ctx.lineJoin = 'round';
      ctx.moveTo(toX(0), toY(values[0]));
      values.forEach((v, i) => {
        if (i === 0) return;
        const x0 = toX(i-1), y0 = toY(values[i-1]);
        const x1 = toX(i),   y1 = toY(v);
        const cx = (x0 + x1) / 2;
        ctx.bezierCurveTo(cx, y0, cx, y1, x1, y1);
      });
      ctx.stroke();

      // Nöqtələr
      if (opts.showDots) {
        values.forEach((v, i) => {
          ctx.beginPath();
          ctx.arc(toX(i), toY(v), 4, 0, Math.PI*2);
          ctx.fillStyle = opts.color;
          ctx.fill();
          ctx.strokeStyle = 'rgba(1,10,6,0.8)';
          ctx.lineWidth = 2;
          ctx.stroke();
        });
      }

      // X oxu etiketləri
      if (labels?.length) {
        ctx.fillStyle = 'rgba(255,255,255,0.3)';
        ctx.font = '9px DM Sans, sans-serif';
        ctx.textAlign = 'center';
        labels.forEach((lbl, i) => {
          ctx.fillText(lbl, toX(i), H - 4);
        });
      }
    }
  }

  // ── Firebase-dən analitika məlumatlarını oxu ──
  async function loadAnalytics() {
    const [
      usersSnap,
      commissionsSnap,
      dailyWasteSnap,
      scansSnap
    ] = await Promise.all([
      db.ref('users').once('value'),
      db.ref('analytics/commissions').limitToLast(90).once('value'),
      db.ref('analytics/dailyWaste').limitToLast(30).once('value'),
      db.ref('analytics/scans').limitToLast(30).once('value')
    ]);

    const users       = usersSnap.val()       || {};
    const commissions = commissionsSnap.val() || {};
    const dailyWaste  = dailyWasteSnap.val()  || {};
    const scans       = scansSnap.val()        || {};

    return { users, commissions, dailyWaste, scans };
  }

  // ── Komissiya gəlirlərini gün-gün topla ──
  function aggregateCommissionsByDay(commissions) {
    const byDay = {};
    Object.values(commissions).forEach(entry => {
      const day = new Date(entry.ts).toLocaleDateString('az-AZ', { day:'numeric', month:'short' });
      byDay[day] = (byDay[day] || 0) + (entry.commission || entry.fee || 0);
    });
    return byDay;
  }

  // ── Tullantı cəmini hesabla ──
  function aggregateWasteByDay(waste) {
    const byDay = {};
    Object.values(waste).forEach(entry => {
      const day = new Date(entry.ts).toLocaleDateString('az-AZ', { day:'numeric', month:'short' });
      byDay[day] = (byDay[day] || 0) + (entry.grams || 0);
    });
    return byDay;
  }

  // ── 30 günlük gəlir proqnozu (xokkey çubuğu modeli) ──
  function projectRevenue(historicalDayRevenues) {
    const values = Object.values(historicalDayRevenues);
    if (values.length < 3) return [];

    // Hər 7 günlük ortalama artım
    const weeklyGrowth = [];
    for (let i = 7; i < values.length; i++) {
      const prev = values.slice(i-7, i).reduce((a,b) => a+b, 0) / 7;
      const curr = values.slice(i, i+7).reduce((a,b) => a+b, 0) / 7;
      if (prev > 0) weeklyGrowth.push(curr / prev);
    }
    const avgWeeklyGrowthRate = weeklyGrowth.length
      ? weeklyGrowth.reduce((a,b)=>a+b,0) / weeklyGrowth.length
      : 1.15; // Default: hər həftə %15 artım

    // Gündəlik artım nisbəti
    const dailyGrowthRate = Math.pow(avgWeeklyGrowthRate, 1/7);

    // Son 7 günün ortalaması başlanğıc nöqtəsi
    const baseRevenue = values.slice(-7).reduce((a,b)=>a+b,0) / 7;

    // 30 günlük proqnoz
    const projection = [];
    for (let d = 1; d <= 30; d++) {
      projection.push(baseRevenue * Math.pow(dailyGrowthRate, d));
    }
    return projection;
  }

  // ── Ana render funksiyası ──
  async function renderAnalyticsDashboard() {
    const dashEl = document.getElementById('analytics-dashboard');
    if (!dashEl) return;

    dashEl.innerHTML = `
      <div class="analytics-loading">
        <div class="spin spin-g"></div>
        <div style="margin-top:8px;font-size:12px;color:var(--t2);">Məlumatlar yüklənir...</div>
      </div>`;

    let data;
    try {
      data = await loadAnalytics();
    } catch (e) {
      dashEl.innerHTML = `<div style="color:#ff4757;text-align:center;padding:20px;">Xəta: ${e.message}</div>`;
      return;
    }

    // Hesablamalar
    const userCount    = Object.keys(data.users).length;
    const commByDay    = aggregateCommissionsByDay(data.commissions);
    const wasteByDay   = aggregateWasteByDay(data.dailyWaste);
    const projection   = projectRevenue(commByDay);

    const totalComm    = Object.values(commByDay).reduce((a,b)=>a+b,0);
    const totalWasteKg = Object.values(wasteByDay).reduce((a,b)=>a+b,0) / 1000;

    // Son 14 günün etiketləri
    const last14days = Array.from({length:14}, (_,i) => {
      const d = new Date(); d.setDate(d.getDate() - (13 - i));
      return d.toLocaleDateString('az-AZ', {day:'numeric',month:'short'});
    });

    const commValues  = last14days.map(d => commByDay[d] || 0);
    const wasteValues = last14days.map(d => wasteByDay[d] || 0);
    const projLabels  = Array.from({length:30}, (_,i) => `+${i+1}g`);

    // Dashboard HTML
    dashEl.innerHTML = `
      <!-- KPI Kartları -->
      <div class="kpi-grid">
        <div class="kpi-card">
          <div class="kpi-ico">👥</div>
          <div class="kpi-val">${userCount.toLocaleString()}</div>
          <div class="kpi-lbl">Aktiv İstifadəçi</div>
          <div class="kpi-trend up">↑ Artır</div>
        </div>
        <div class="kpi-card">
          <div class="kpi-ico">💰</div>
          <div class="kpi-val">${totalComm.toFixed(2)} ₼</div>
          <div class="kpi-lbl">Cəmi Komissiya</div>
          <div class="kpi-trend up">↑ Bu ay</div>
        </div>
        <div class="kpi-card">
          <div class="kpi-ico">♻️</div>
          <div class="kpi-val">${totalWasteKg.toFixed(1)} kg</div>
          <div class="kpi-lbl">Toplanan Tullantı</div>
          <div class="kpi-trend up">↑ Rekord</div>
        </div>
        <div class="kpi-card">
          <div class="kpi-ico">📈</div>
          <div class="kpi-val">${projection.length ? projection[29].toFixed(2) : '—'} ₼</div>
          <div class="kpi-lbl">30g Proqnoz (gün)</div>
          <div class="kpi-trend up">↑ Xokkey</div>
        </div>
      </div>

      <!-- Komissiya Gəlirləri Qrafiki -->
      <div class="chart-card">
        <div class="chart-header">
          <div>
            <div class="chart-title">💰 Komissiya Gəlirləri</div>
            <div class="chart-sub">Son 14 gün (AZN)</div>
          </div>
          <div class="chart-badge green">CANLI</div>
        </div>
        <canvas id="chart-commissions" width="320" height="120"></canvas>
      </div>

      <!-- Tullantı Miqdarı Qrafiki -->
      <div class="chart-card">
        <div class="chart-header">
          <div>
            <div class="chart-title">♻️ Günlük Tullantı</div>
            <div class="chart-sub">Son 14 gün (qram)</div>
          </div>
          <div class="chart-badge teal">ECO</div>
        </div>
        <canvas id="chart-waste" width="320" height="120"></canvas>
      </div>

      <!-- Xokkey Çubuğu Proqnozu -->
      <div class="chart-card hockey">
        <div class="chart-header">
          <div>
            <div class="chart-title">🏒 30 Günlük Gəlir Proqnozu</div>
            <div class="chart-sub">Xokkey çubuğu artım modeli</div>
          </div>
          <div class="chart-badge amber">AI</div>
        </div>
        <canvas id="chart-projection" width="320" height="140"></canvas>
        <div class="hockey-note">
          Hazırkı artım tempi ilə 30 gün sonra gündəlik:
          <strong>${projection.length ? projection[29].toFixed(3) : '—'} AZN</strong> komissiya
        </div>
      </div>

      <!-- Tərəfdaş Breakdown -->
      <div class="chart-card">
        <div class="chart-title" style="margin-bottom:12px;">🤝 Tərəfdaş Gəlirləri</div>
        <div id="partner-breakdown"></div>
      </div>

      <!-- Son Əməliyyatlar -->
      <div class="chart-card">
        <div class="chart-title" style="margin-bottom:12px;">📋 Son Əməliyyatlar</div>
        <div id="recent-commissions"></div>
      </div>
    `;

    // Qrafikləri çək
    requestAnimationFrame(() => {
      new MicroChart('chart-commissions', { color: '#00ff7a', fillColor: 'rgba(0,255,122,0.12)' })
        .draw(last14days, commValues);

      new MicroChart('chart-waste', { color: '#00d4ff', fillColor: 'rgba(0,212,255,0.12)' })
        .draw(last14days, wasteValues);

      new MicroChart('chart-projection', {
        color: '#ffa502',
        fillColor: 'rgba(255,165,2,0.12)',
        showDots: false
      }).draw(projLabels, projection);
    });

    // Tərəfdaş breakdown
    renderPartnerBreakdown(data.commissions);
    renderRecentCommissions(data.commissions);
  }

  function renderPartnerBreakdown(commissions) {
    const el = document.getElementById('partner-breakdown');
    if (!el) return;

    const byPartner = {};
    Object.values(commissions).forEach(c => {
      const key = c.partnerName || c.provider || c.source || 'Digər';
      byPartner[key] = (byPartner[key] || 0) + (c.commission || c.fee || 0);
    });

    const total = Object.values(byPartner).reduce((a,b)=>a+b, 0) || 1;
    const sorted = Object.entries(byPartner).sort((a,b)=>b[1]-a[1]);

    el.innerHTML = sorted.map(([name, val]) => {
      const pct = Math.round((val/total)*100);
      return `
      <div class="pb-row">
        <div class="pb-name">${escHtml(name)}</div>
        <div class="pb-bar-wrap">
          <div class="pb-bar" style="width:${pct}%"></div>
        </div>
        <div class="pb-val">${val.toFixed(3)} ₼ (${pct}%)</div>
      </div>`;
    }).join('') || '<div style="color:var(--t2);font-size:12px;">Hələ məlumat yoxdur</div>';
  }

  function renderRecentCommissions(commissions) {
    const el = document.getElementById('recent-commissions');
    if (!el) return;

    const sorted = Object.values(commissions)
      .sort((a,b) => b.ts - a.ts)
      .slice(0, 10);

    if (!sorted.length) {
      el.innerHTML = '<div style="color:var(--t2);font-size:12px;">Hələ məlumat yoxdur</div>';
      return;
    }

    el.innerHTML = sorted.map(c => {
      const time = new Date(c.ts).toLocaleString('az-AZ', {day:'numeric',month:'short',hour:'2-digit',minute:'2-digit'});
      const source = c.source === 'transport' ? '🚌' : c.source === 'coupon' ? '🎟️' : '♻️';
      return `
      <div class="rc-row">
        <div class="rc-ico">${source}</div>
        <div class="rc-info">
          <div class="rc-name">${escHtml(c.partnerName || c.provider || c.source || '—')}</div>
          <div class="rc-time">${time}</div>
        </div>
        <div class="rc-val">+${(c.commission || c.fee || 0).toFixed(4)} ₼</div>
      </div>`;
    }).join('');
  }

  // ── Real-vaxt dinləyici ──
  function startRealtimeAnalytics() {
    // Yeni komissiya gəldikcə yenilə
    db.ref('analytics/commissions').limitToLast(1).on('child_added', () => {
      renderAnalyticsDashboard();
    });
  }

  return {
    renderAnalyticsDashboard,
    startRealtimeAnalytics,
    projectRevenue,
    MicroChart
  };
})();


/* ─── CSS: Analitika Stillər ─── */
const ANALYTICS_CSS = `
/* KPI Grid */
.kpi-grid {
  display: grid; grid-template-columns: 1fr 1fr; gap: 8px; margin-bottom: 12px;
}
.kpi-card {
  background: rgba(255,255,255,0.03);
  border: 1px solid rgba(255,255,255,0.08);
  border-radius: 16px; padding: 14px 12px;
}
.kpi-ico  { font-size: 22px; margin-bottom: 6px; }
.kpi-val  { font-size: 20px; font-weight: 800; color: var(--t1); line-height: 1; }
.kpi-lbl  { font-size: 10px; color: var(--t2); margin-top: 3px; }
.kpi-trend { font-size: 10px; margin-top: 4px; }
.kpi-trend.up   { color: #00ff7a; }
.kpi-trend.down { color: #ff4757; }

/* Chart Cards */
.chart-card {
  background: rgba(255,255,255,0.02);
  border: 1px solid rgba(255,255,255,0.07);
  border-radius: 18px; padding: 16px;
  margin-bottom: 12px; overflow: hidden;
}
.chart-card.hockey { border-color: rgba(255,165,2,0.2); }
.chart-header {
  display: flex; justify-content: space-between;
  align-items: flex-start; margin-bottom: 14px;
}
.chart-title { font-size: 14px; font-weight: 700; color: var(--t1); }
.chart-sub   { font-size: 10px; color: var(--t2); margin-top: 2px; }
.chart-badge {
  font-size: 9px; font-weight: 700; padding: 3px 8px;
  border-radius: 20px; letter-spacing: 1px;
}
.chart-badge.green { background: rgba(0,255,122,0.1); color: #00ff7a; }
.chart-badge.teal  { background: rgba(0,212,255,0.1); color: #00d4ff; }
.chart-badge.amber { background: rgba(255,165,2,0.1); color: #ffa502; }
.hockey-note {
  font-size: 11px; color: var(--t2);
  margin-top: 10px; text-align: center;
  padding: 8px; background: rgba(255,165,2,0.05);
  border-radius: 8px;
}
canvas { display: block; width: 100% !important; max-width: 100%; }

/* Partner Breakdown */
.pb-row {
  display: flex; align-items: center; gap: 8px;
  margin-bottom: 8px; font-size: 11px;
}
.pb-name { width: 80px; color: var(--t2); flex-shrink: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.pb-bar-wrap { flex: 1; height: 6px; background: rgba(255,255,255,0.05); border-radius: 3px; overflow: hidden; }
.pb-bar { height: 100%; border-radius: 3px; background: var(--g1); transition: width 0.6s ease; }
.pb-val { font-size: 10px; color: var(--t2); white-space: nowrap; }

/* Recent Commissions */
.rc-row {
  display: flex; align-items: center; gap: 10px;
  padding: 8px 0; border-bottom: 1px solid rgba(255,255,255,0.04);
}
.rc-ico  { font-size: 18px; flex-shrink: 0; }
.rc-info { flex: 1; }
.rc-name { font-size: 12px; color: var(--t1); }
.rc-time { font-size: 10px; color: var(--t2); }
.rc-val  { font-size: 13px; font-weight: 700; color: #00ff7a; white-space: nowrap; }

/* Analytics loading */
.analytics-loading {
  text-align: center; padding: 40px 20px;
}
`;

(function injectAnalyticsStyles() {
  const style = document.createElement('style');
  style.textContent = ANALYTICS_CSS;
  document.head.appendChild(style);
})();


/* ═══════════════════════════════════════════════════════════════
   ADMIN PANEL-Ə İNTEQRASİYA: app.js-dəki loadAdmStats() funksiyasını
   aşağıdakı ilə əvəz edin (və ya genişləndirin):
   ═══════════════════════════════════════════════════════════════ */

function loadAdmStats() {
  // Mövcud admin mini-statsları yüklə
  db.ref('users').once('value', s => {
    const users = s.val() || {};
    const uids  = Object.keys(users);
    let totalScans = 0, totalEP = 0;

    uids.forEach(uid => {
      const u = users[uid];
      totalScans += (u.stats?.scans || 0);
      totalEP    += (u.balance || 0);
    });

    const admUsers = document.getElementById('adm-total-users');
    const admScans = document.getElementById('adm-total-scans');
    const admEP    = document.getElementById('adm-total-ep');

    if (admUsers) admUsers.textContent = uids.length.toLocaleString();
    if (admScans) admScans.textContent = totalScans.toLocaleString();
    if (admEP)    admEP.textContent    = totalEP.toLocaleString();

    loadAdmUsers(users);
    loadAdmActivity();
  });

  // Analitika tabını əlavə et
  addAnalyticsTabToAdmin();
}

// Admin panelə Analitika tabı əlavə et
function addAnalyticsTabToAdmin() {
  const tabsEl = document.querySelector('.adm-tabs');
  if (!tabsEl || document.getElementById('adm-analytics-tab')) return;

  // Tab düyməsi
  const tabBtn = document.createElement('div');
  tabBtn.className = 'adm-tab';
  tabBtn.id = 'adm-analytics-tab';
  tabBtn.textContent = '📈 Analitika';
  tabBtn.onclick = function() { admTab('analytics', this); };
  tabsEl.appendChild(tabBtn);

  // Tab məzmunu
  const tabContent = document.createElement('div');
  tabContent.className = 'adm-section';
  tabContent.id = 'adm-analytics';
  tabContent.innerHTML = `
    <div style="font-size:11px;color:var(--t2);margin-bottom:12px;">
      📊 Gəlir analitikası, tullantı statistikası və istifadəçi artımı
    </div>
    <div id="analytics-dashboard">
      <button class="adm-btn" onclick="AnalyticsModule.renderAnalyticsDashboard()" style="margin-bottom:12px;">
        📈 Analitikanı Yüklə
      </button>
    </div>
  `;

  // Tab-ların konteyneri (adm-body)
  const admBody = document.querySelector('.adm-body');
  if (admBody) admBody.appendChild(tabContent);
}
