/* ═══════════════════════════════════════════════════════════
   ECOPOINT PRO — NATIVE MOBILE FEEL MODULE
   Pull-to-Refresh · Elastic Overscroll · Momentum · Haptics
   Plug-and-play: loads after app.js, zero conflicts
═══════════════════════════════════════════════════════════ */

(function () {
  'use strict';

  /* ─── CONFIG ─── */
  const CFG = {
    PTR_THRESHOLD:   68,   // px drag needed to trigger refresh
    PTR_MAX_DRAG:   100,   // max visual drag distance
    ELASTIC_MAX:     38,   // max elastic bounce px
    ELASTIC_RESIST: 0.32,  // rubber-band resistance (0–1, lower = more resistance)
    MOMENTUM_DECAY: 0.92,  // velocity decay per frame
    HAPTIC_SCALE:   0.93,  // touch feedback scale-down
    HAPTIC_DUR:     120,   // ms of press animation
  };

  /* ─── HELPERS ─── */
  const qs  = (s, r = document) => r.querySelector(s);
  const qsa = (s, r = document) => r.querySelectorAll(s);
  const clamp = (v, lo, hi) => Math.max(lo, Math.min(hi, v));

  /* ─────────────────────────────────────
     1. PULL-TO-REFRESH
  ───────────────────────────────────── */
  function initPullToRefresh() {
    const scroller = qs('.content');
    if (!scroller) return;

    /* Inject PTR indicator */
    const ptr = document.createElement('div');
    ptr.id = 'ptr-indicator';
    ptr.innerHTML = `
      <div class="ptr-inner">
        <svg class="ptr-spinner" viewBox="0 0 32 32">
          <circle cx="16" cy="16" r="12" fill="none" stroke-width="2.5"
            stroke="var(--g1)" stroke-linecap="round"
            stroke-dasharray="56" stroke-dashoffset="56"/>
        </svg>
        <span class="ptr-leaf">🌿</span>
      </div>`;
    scroller.parentNode.insertBefore(ptr, scroller);

    /* PTR state */
    let startY = 0, currentDrag = 0;
    let isRefreshing = false;
    let isPulling = false;

    /* Detect touch start */
    scroller.addEventListener('touchstart', e => {
      if (scroller.scrollTop > 2) return;
      startY = e.touches[0].clientY;
      isPulling = true;
    }, { passive: true });

    scroller.addEventListener('touchmove', e => {
      if (!isPulling || isRefreshing) return;
      if (scroller.scrollTop > 2) { isPulling = false; return; }

      const delta = e.touches[0].clientY - startY;
      if (delta <= 0) return;

      /* Rubber-band resistance on drag */
      currentDrag = clamp(delta * CFG.ELASTIC_RESIST * 2.2, 0, CFG.PTR_MAX_DRAG);
      applyPTRDrag(currentDrag);
    }, { passive: true });

    scroller.addEventListener('touchend', () => {
      if (!isPulling) return;
      isPulling = false;

      if (currentDrag >= CFG.PTR_THRESHOLD && !isRefreshing) {
        triggerRefresh();
      } else {
        resetPTR();
      }
      currentDrag = 0;
    });

    function applyPTRDrag(drag) {
      const pct = clamp(drag / CFG.PTR_THRESHOLD, 0, 1);

      ptr.style.height   = drag + 'px';
      ptr.style.opacity  = pct;

      /* Rotate spinner arc with drag */
      const arc = qs('.ptr-spinner circle', ptr);
      if (arc) arc.style.strokeDashoffset = 56 - (56 * pct);

      /* Scale spinner in */
      const inner = qs('.ptr-inner', ptr);
      if (inner) inner.style.transform = `scale(${0.5 + pct * 0.5}) rotate(${drag * 1.8}deg)`;

      ptr.classList.toggle('ptr-ready', drag >= CFG.PTR_THRESHOLD);
    }

    function triggerRefresh() {
      isRefreshing = true;
      ptr.classList.add('ptr-refreshing');
      ptr.style.height  = '62px';
      ptr.style.opacity = '1';

      /* Haptic if supported */
      if (navigator.vibrate) navigator.vibrate(8);

      /* Call the actual data refresh */
      doDataRefresh().finally(() => {
        setTimeout(resetPTR, 600);
      });
    }

    function resetPTR() {
      isRefreshing = false;
      ptr.classList.remove('ptr-refreshing', 'ptr-ready');
      ptr.style.transition = 'height 0.38s cubic-bezier(0.34,1.56,0.64,1), opacity 0.3s ease';
      ptr.style.height  = '0px';
      ptr.style.opacity = '0';
      setTimeout(() => { ptr.style.transition = ''; }, 420);
    }
  }

  /* ─── Actual Firebase re-fetch ─── */
  async function doDataRefresh() {
    /* Re-load balance, stats, leaderboard if user logged in */
    if (typeof UID !== 'undefined' && UID) {
      try {
        await Promise.all([
          db.ref('users/' + UID + '/balance').once('value').then(s => {
            const bal = s.val() || 0;
            const el = document.getElementById('bal-num');
            if (el) el.textContent = bal.toLocaleString();
            const dtbEl = document.getElementById('dtb-bal-num');
            if (dtbEl) dtbEl.textContent = bal.toLocaleString();
          }),
          db.ref('users/' + UID + '/stats').once('value').then(s => {
            const st = s.val() || {};
            const earned = document.getElementById('bp-earned');
            const sent   = document.getElementById('bp-sent');
            const scans  = document.getElementById('bp-scans');
            if (earned) earned.textContent = (st.earned || 0).toLocaleString();
            if (sent)   sent.textContent   = (st.sent   || 0).toLocaleString();
            if (scans)  scans.textContent  = (st.scans  || 0).toLocaleString();
          }),
        ]);
        if (typeof loadLB === 'function') loadLB();
      } catch (e) { /* silent */ }
    }
    /* Small artificial delay so spinner feels real */
    return new Promise(r => setTimeout(r, 480));
  }

  /* ─────────────────────────────────────
     2. ELASTIC OVER-SCROLL (rubber-band)
  ───────────────────────────────────── */
  function initElasticOverscroll() {
    const scroller = qs('.content');
    if (!scroller) return;

    let startY = 0, lastY = 0, velocity = 0;
    let isBouncing = false;
    let elasticOffset = 0;
    let rafId = null;

    scroller.addEventListener('touchstart', e => {
      startY = lastY = e.touches[0].clientY;
      velocity = 0;
      isBouncing = false;
      cancelAnimationFrame(rafId);
      scroller.style.transition = 'none';
    }, { passive: true });

    scroller.addEventListener('touchmove', e => {
      const y = e.touches[0].clientY;
      const dy = y - lastY;
      lastY = y;
      velocity = dy;

      const atTop    = scroller.scrollTop <= 0;
      const atBottom = scroller.scrollTop + scroller.clientHeight >= scroller.scrollHeight - 1;

      if ((atTop && dy > 0) || (atBottom && dy < 0)) {
        /* Apply rubber-band offset to the content wrapper */
        elasticOffset += dy * CFG.ELASTIC_RESIST;
        elasticOffset  = clamp(elasticOffset, -CFG.ELASTIC_MAX, CFG.ELASTIC_MAX);
        applyElastic(elasticOffset);
        isBouncing = true;
      } else if (isBouncing) {
        /* User scrolled back into normal range */
        elasticOffset = 0;
        applyElastic(0);
        isBouncing = false;
      }
    }, { passive: true });

    scroller.addEventListener('touchend', () => {
      if (elasticOffset !== 0) {
        springBack();
      }
    });

    function applyElastic(offset) {
      scroller.style.transform = `translateY(${offset}px)`;
    }

    function springBack() {
      scroller.style.transition = 'transform 0.45s cubic-bezier(0.25,1,0.5,1)';
      scroller.style.transform  = 'translateY(0px)';
      elasticOffset = 0;
      setTimeout(() => { scroller.style.transition = ''; }, 460);
    }
  }

  /* ─────────────────────────────────────
     3. SMOOTH MOMENTUM SCROLLING
  ───────────────────────────────────── */
  function initMomentumScrolling() {
    const scroller = qs('.content');
    if (!scroller) return;

    /* CSS momentum (WebKit) */
    scroller.style.webkitOverflowScrolling = 'touch';
    scroller.style.overflowY = 'scroll';

    /* Prevent content "pop" during fast fling */
    scroller.style.willChange = 'transform';
    scroller.style.transform  = 'translateZ(0)';

    /* Smooth snap for page switches — ensure no hard cuts */
    scroller.style.scrollBehavior = 'smooth';

    /* Additional: intercept wheel on desktop for smoother feel */
    scroller.addEventListener('wheel', e => {
      e.stopPropagation();
    }, { passive: true });
  }

  /* ─────────────────────────────────────
     4. TOUCH FEEDBACK (haptic scale)
  ───────────────────────────────────── */
  function initTouchFeedback() {
    /* Selectors that get press feedback */
    const SELECTORS = [
      '.feat-card', '.act', '.mkt-item', '.challenge-card',
      '.bal-hero .bstat', '.eco-stat-item',
      '.partner-card', '.streak-card', '.referral-card',
      '.guest-card', '.perk', '.si', '.lang-btn', '.lang-quick-btn',
      '.chip', '.lb-row', '.ach-item', '.adm-quick-chip',
      '.nav-item', '.nav-scan', '.hdr-btn', '.lang-float-btn',
      '.sh-btn', '.locked-btn', '.google-btn', '.guest-skip',
      '.mi-buy', '.adm-btn', '.dsb-scan-btn', '.dsb-nav-item',
      '.install-strip', '.uid-chip', '.qr-chip', '.ref-code-box',
    ];

    const selector = SELECTORS.join(', ');

    /* Use a single delegated listener for performance */
    document.addEventListener('touchstart', e => {
      const el = e.target.closest(selector);
      if (!el) return;
      pressFeedback(el, true);
    }, { passive: true });

    document.addEventListener('touchend', e => {
      const el = e.target.closest(selector);
      if (!el) return;
      pressFeedback(el, false);
    }, { passive: true });

    document.addEventListener('touchcancel', e => {
      const el = e.target.closest(selector);
      if (!el) return;
      pressFeedback(el, false);
    }, { passive: true });

    function pressFeedback(el, isDown) {
      if (isDown) {
        el.style.transition = `transform ${CFG.HAPTIC_DUR * 0.4}ms cubic-bezier(0.34,1.56,0.64,1)`;
        el.style.transform  = `scale(${CFG.HAPTIC_SCALE})`;
        /* Subtle brightness dip */
        el.style.filter = 'brightness(0.92)';
        /* Vibrate 4ms if available */
        if (navigator.vibrate) navigator.vibrate(4);
      } else {
        el.style.transition = `transform ${CFG.HAPTIC_DUR}ms cubic-bezier(0.34,1.56,0.64,1), filter 0.18s ease`;
        el.style.transform  = 'scale(1)';
        el.style.filter     = '';
      }
    }

    /* Remove any conflicting :active CSS transforms that fight with JS */
    const styleOverride = document.createElement('style');
    styleOverride.textContent = `
      .feat-card:active, .act:active, .mkt-item:active,
      .challenge-card:active, .partner-card:active,
      .streak-card:active, .referral-card:active,
      .guest-card:active, .perk:active, .si:active,
      .mi-buy:active, .sh-btn:active, .locked-btn:active,
      .google-btn:active, .nav-scan:active,
      .hdr-btn:active, .lang-float-btn:active,
      .dsb-scan-btn:active, .dsb-nav-item:active,
      .install-strip:active, .uid-chip:active, .qr-chip:active,
      .lang-btn:active, .lang-quick-btn:active,
      .chip:active, .adm-btn:active, .adm-quick-chip:active {
        transform: none !important;   /* JS handles it */
      }
    `;
    document.head.appendChild(styleOverride);
  }

  /* ─────────────────────────────────────
     PTR CSS (injected)
  ───────────────────────────────────── */
  function injectPTRStyles() {
    const style = document.createElement('style');
    style.textContent = `
      #ptr-indicator {
        position: relative; z-index: 5;
        height: 0; overflow: hidden;
        display: flex; align-items: center; justify-content: center;
        transition: none;
        will-change: height, opacity;
        pointer-events: none;
      }
      .ptr-inner {
        display: flex; align-items: center; justify-content: center;
        width: 44px; height: 44px; position: relative;
        transform-origin: center;
        transition: transform 0.1s linear;
      }
      .ptr-spinner {
        width: 34px; height: 34px;
        position: absolute; top: 50%; left: 50%;
        transform: translate(-50%,-50%) rotate(-90deg);
      }
      .ptr-spinner circle {
        transition: stroke-dashoffset 0.1s linear;
      }
      .ptr-leaf {
        font-size: 18px; position: relative; z-index: 1;
        display: block; line-height: 1;
      }

      /* Spinning state while refreshing */
      #ptr-indicator.ptr-refreshing .ptr-inner {
        animation: ptrSpin 0.8s linear infinite;
      }
      @keyframes ptrSpin {
        to { transform: rotate(360deg); }
      }

      /* Ready state — glow pulse */
      #ptr-indicator.ptr-ready .ptr-spinner circle {
        stroke: var(--g1);
        filter: drop-shadow(0 0 4px rgba(0,255,122,0.6));
      }

      /* iOS-style page spring for content area on overscroll */
      .content {
        overscroll-behavior-y: none;   /* disable native rubber-band (we do it ourselves) */
        -webkit-overflow-scrolling: touch;
        scroll-behavior: smooth;
      }

      /* Smooth scrolling for all inner scrollables */
      .adm-user-list, .adm-activity-list, .user-search-results,
      .achievements-sheet, .notif-sheet, .lang-quick-sheet,
      .mkt-filters, .adm-tabs {
        -webkit-overflow-scrolling: touch;
        scroll-behavior: smooth;
      }

      /* Touch callout & selection disable for interactive cards */
      .feat-card, .act, .mkt-item, .challenge-card,
      .partner-card, .streak-card, .referral-card,
      .guest-card, .nav-scan, .hdr-btn {
        -webkit-touch-callout: none;
        -webkit-user-select: none;
        user-select: none;
      }
    `;
    document.head.appendChild(style);
  }

  /* ─────────────────────────────────────
     BOOT — wait for DOM
  ───────────────────────────────────── */
  function boot() {
    injectPTRStyles();
    initPullToRefresh();
    initElasticOverscroll();
    initMomentumScrolling();
    initTouchFeedback();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', boot);
  } else {
    boot();
  }

})();
