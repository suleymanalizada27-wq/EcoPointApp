/* ═══════════════════════════════════════════════════════
   ECOPOINT PRO — MARKETPLACE MODULE v6
   Coupon + Transport — overlay .open class sistemi
   ═══════════════════════════════════════════════════════ */

const MarketplaceModule = (() => {

  const PARTNERS = {
    bravo:   { name:'Bravo',   rate:'1 AZN = 500 EP', minEP:500,  commission:5  },
    bolmart: { name:'Bolmart', rate:'1 AZN = 500 EP', minEP:300,  commission:5  },
  };

  // ── Kupon Modalını Aç ──
  function openCouponModal(partnerId) {
    const p = PARTNERS[partnerId];
    if(!p) return;
    document.getElementById('coupon-partner-id').value   = partnerId;
    document.getElementById('coupon-partner-name').textContent = p.name;
    document.getElementById('coupon-partner-rate').textContent = p.rate;
    document.getElementById('coupon-min-ep').textContent       = p.minEP;
    document.getElementById('coupon-commission').textContent   = p.commission;
    document.getElementById('coupon-preview').textContent      = 'EP miqdarı daxil edin';
    document.getElementById('coupon-ep-input').value           = '';
    const s2 = document.getElementById('s-bal2');
    if(s2) s2.textContent = (typeof myBal !== 'undefined' ? myBal : 0);
    // .open class ilə aç
    document.getElementById('ov-coupon').classList.add('open');
  }

  // ── Kupon önizləmə ──
  function updateCouponPreview() {
    const ep = parseInt(document.getElementById('coupon-ep-input').value) || 0;
    const partnerId = document.getElementById('coupon-partner-id').value;
    const p = PARTNERS[partnerId] || { commission:5 };
    const preview = document.getElementById('coupon-preview');
    if(!ep) { preview.textContent = 'EP miqdarı daxil edin'; return; }
    const commission = Math.round(ep * p.commission / 100);
    const net = ep - commission;
    const azn = (net / 500).toFixed(2);
    preview.textContent = `${ep} EP → ${azn} AZN (komisyon: ${commission} EP)`;
  }

  // ── Kupon Yarat ──
  function submitCoupon() {
    const ep = parseInt(document.getElementById('coupon-ep-input').value) || 0;
    const partnerId = document.getElementById('coupon-partner-id').value;
    const p = PARTNERS[partnerId];
    if(!p) return;
    if(!window.UID) { showToast('Əvvəlcə daxil olun','err'); return; }
    if(ep < p.minEP) { showToast(`Min: ${p.minEP} EP`,'err'); return; }
    if(ep > (typeof myBal !== 'undefined' ? myBal : 0)) { showToast('Balans kifayət etmir','err'); return; }

    const commission = Math.round(ep * p.commission / 100);
    const net = ep - commission;
    const azn = (net / 500).toFixed(2);

    window.db.ref('users/'+window.UID+'/balance').transaction(cur => {
      if((cur||0) < ep) return undefined;
      return (cur||0) - ep;
    }, (err, committed) => {
      if(err||!committed) { showToast('Balans kifayət etmir','err'); return; }
      const code = p.name.toUpperCase() + '-' + Math.random().toString(36).slice(2,8).toUpperCase();

      // Nəticəni göstər
      document.getElementById('cr-partner').textContent = p.name;
      document.getElementById('cr-value').textContent   = azn + ' AZN';
      document.getElementById('cr-code').textContent    = code;

      // Coupon overlay-i bağla, result-ı aç
      document.getElementById('ov-coupon').classList.remove('open');
      document.getElementById('ov-coupon-result').classList.add('open');

      // Tx yaz
      if(typeof addTx === 'function') addTx('buy', '-'+ep, `🎟️ ${p.name} kuponu: ${azn} AZN`);

      // Firebase-ə qeyd et
      window.db.ref('users/'+window.UID+'/coupons').push({
        partner: p.name, ep, azn, code, ts: Date.now()
      });
    });
  }

  // ── Transport ──
  function submitTransport() {
    const cardNum = (document.getElementById('bakikart-number')?.value||'').replace(/\s/g,'');
    const ep = parseInt(document.getElementById('bakikart-ep')?.value) || 0;
    if(!window.UID) { showToast('Əvvəlcə daxil olun','err'); return; }
    if(cardNum.length !== 16) { showToast('BakıKart nömrəsini düzgün daxil edin','err'); return; }
    if(ep < 100) { showToast('Min: 100 EP','err'); return; }
    if(ep > (typeof myBal !== 'undefined' ? myBal : 0)) { showToast('Balans kifayət etmir','err'); return; }

    const fee = Math.round(ep * 0.02);
    const net = ep - fee;
    const azn = (net / 1000).toFixed(2);

    window.db.ref('users/'+window.UID+'/balance').transaction(cur => {
      if((cur||0) < ep) return undefined;
      return (cur||0) - ep;
    }, (err, committed) => {
      if(err||!committed) { showToast('Balans kifayət etmir','err'); return; }
      showToast(`✅ BakıKart-a ${azn} AZN köçürüldü!`,'ok');
      document.getElementById('ov-transport').classList.remove('open');
      if(typeof addTx === 'function') addTx('buy', '-'+ep, `🚌 BakıKart (****${cardNum.slice(-4)}): ${azn} AZN`);
    });
  }

  return { openCouponModal, updateCouponPreview, submitCoupon, submitTransport };
})();
