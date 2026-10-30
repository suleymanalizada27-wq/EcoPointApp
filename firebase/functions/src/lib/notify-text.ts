export type Lang = 'az' | 'en' | 'ru' | 'tr';
export const LANGS: readonly Lang[] = ['az', 'en', 'ru', 'tr'];

export function asLang(v: unknown): Lang {
  return typeof v === 'string' && (LANGS as readonly string[]).includes(v) ? (v as Lang) : 'az';
}

export interface Text {
  title: string;
  body: string;
}

/** Morning reminder for people who have not checked in yet today. */
export function dailyReminderText(lang: Lang, streak: number): Text {
  const alive = streak > 0;
  switch (lang) {
    case 'en':
      return {
        title: '🔥 Daily bonus',
        body: alive
          ? `Your ${streak}-day streak is going. Check in today to keep it!`
          : 'Check in today and start earning EP!',
      };
    case 'ru':
      return {
        title: '🔥 Ежедневный бонус',
        body: alive
          ? `Серия ${streak} дн. продолжается. Зайди сегодня, чтобы не потерять её!`
          : 'Зайди сегодня и начни зарабатывать EP!',
      };
    case 'tr':
      return {
        title: '🔥 Günlük bonus',
        body: alive
          ? `${streak} günlük serin devam ediyor. Bugün giriş yap, bozulmasın!`
          : 'Bugün giriş yap ve EP kazanmaya başla!',
      };
    default:
      return {
        title: '🔥 Gündəlik bonus',
        body: alive
          ? `Seriyan ${streak} gündür davam edir. Bu gün giriş et və davam et!`
          : 'Bu gün giriş et və EP qazanmağa başla!',
      };
  }
}

/** Evening warning: a long streak will reset tonight. */
export function streakRiskText(lang: Lang, streak: number): Text {
  switch (lang) {
    case 'en':
      return {
        title: "⏳ Don't lose your streak",
        body: `Your ${streak}-day streak resets tonight unless you check in.`,
      };
    case 'ru':
      return {
        title: '⏳ Не потеряй серию',
        body: `Серия ${streak} дн. сбросится сегодня, если не зайти.`,
      };
    case 'tr':
      return {
        title: '⏳ Serini kaybetme',
        body: `${streak} günlük serin bu gece sıfırlanacak, giriş yapmayı unutma.`,
      };
    default:
      return {
        title: '⏳ Seriyanı itirmə',
        body: `${streak} günlük seriyan bu gün giriş etməsən sıfırlanacaq.`,
      };
  }
}

/** Prize for a top-3 finish on last week's leaderboard. */
export function weeklyPrizeText(lang: Lang, rank: number, ep: number): Text {
  switch (lang) {
    case 'en':
      return { title: '🏆 Weekly prize', body: `You finished #${rank} last week! +${ep} EP is in your wallet.` };
    case 'ru':
      return { title: '🏆 Приз недели', body: `Ты занял ${rank}-е место на прошлой неделе! +${ep} EP уже на балансе.` };
    case 'tr':
      return { title: '🏆 Haftalık ödül', body: `Geçen hafta ${rank}. oldun! +${ep} EP cüzdanında.` };
    default:
      return { title: '🏆 Həftəlik mükafat', body: `Keçən həftə ${rank}-ci oldun! +${ep} EP balansındadır.` };
  }
}

/** Monday summary built from the user's real last-7-days totals. */
export function weeklySummaryText(lang: Lang, ep: number, scans: number): Text {
  switch (lang) {
    case 'en':
      return {
        title: '📊 Weekly summary',
        body: `Last week you earned ${ep} EP with ${scans} scans. Keep going!`,
      };
    case 'ru':
      return {
        title: '📊 Итоги недели',
        body: `На прошлой неделе ты заработал ${ep} EP, сканирований: ${scans}. Так держать!`,
      };
    case 'tr':
      return {
        title: '📊 Haftalık özet',
        body: `Geçen hafta ${ep} EP kazandın, ${scans} tarama yaptın. Devam!`,
      };
    default:
      return {
        title: '📊 Həftəlik xülasə',
        body: `Keçən həftə ${ep} EP qazandın, ${scans} skan etdin. Bu həftə də davam!`,
      };
  }
}

// ───────────────────────── personal ("smart") messages ─────────────────────────

export type SmartKind = 'monthlyReady' | 'monthlyClose' | 'rewardClose' | 'comeback' | 'daily';

export interface SmartVars {
  name: string;
  streak?: number;
  goal?: number;
  left?: number;
  days?: number;
  ep?: number;
  reward?: string;
  gap?: number;
}

/** Personal text built only from the user's real numbers. */
export function smartText(lang: Lang, kind: SmartKind, v: SmartVars): Text {
  const n = v.name ? `${v.name}, ` : '';
  const T: Record<Lang, Record<SmartKind, () => Text>> = {
    az: {
      monthlyReady: () => ({ title: '🏅 Aylıq hədəfə çatdın', body: `${n}aylıq ${v.goal} skan hədəfini tamamladın. ${v.ep} EP mükafatını götür!` }),
      monthlyClose: () => ({ title: '🎯 Hədəfə az qaldı', body: `${n}aylıq ${v.goal} skan hədəfinə ${v.left} skan qalıb. Ayın bitməsinə ${v.days} gün var.` }),
      rewardClose: () => ({ title: '🎁 Mükafata az qaldı', body: `${n}«${v.reward}» mükafatına cəmi ${v.gap} EP qalıb.` }),
      comeback: () => ({ title: '🌿 Səni darıxdıq', body: `${n}${v.days} gündür skan etməmisən. Bir qutu skan et, EP qazan — mükafatlar səni gözləyir.` }),
      daily: () =>
        (v.streak ?? 0) > 0
          ? { title: '🔥 Seriyanı davam et', body: `${n}${v.streak} günlük seriyan var, bu gün də giriş et.` }
          : { title: '🌱 Bu gün EcoPoint-də', body: `${n}giriş et və gündəlik tapşırıqlara bax.` },
    },
    en: {
      monthlyReady: () => ({ title: '🏅 Monthly goal reached', body: `${n}you completed the ${v.goal}-scan monthly goal. Claim your ${v.ep} EP!` }),
      monthlyClose: () => ({ title: '🎯 Almost there', body: `${n}only ${v.left} scans left for your ${v.goal}-scan monthly goal. ${v.days} days left this month.` }),
      rewardClose: () => ({ title: '🎁 Reward within reach', body: `${n}you are only ${v.gap} EP away from “${v.reward}”.` }),
      comeback: () => ({ title: '🌿 We miss you', body: `${n}no scans for ${v.days} days. Scan a bin, earn EP — your rewards are waiting.` }),
      daily: () =>
        (v.streak ?? 0) > 0
          ? { title: '🔥 Keep your streak', body: `${n}you have a ${v.streak}-day streak, check in today too.` }
          : { title: '🌱 EcoPoint today', body: `${n}check in and see today's challenges.` },
    },
    ru: {
      monthlyReady: () => ({ title: '🏅 Цель месяца достигнута', body: `${n}ты выполнил месячную цель (${v.goal} сканирований). Забери ${v.ep} EP!` }),
      monthlyClose: () => ({ title: '🎯 Совсем немного', body: `${n}до месячной цели (${v.goal}) осталось сканирований: ${v.left}. До конца месяца дней: ${v.days}.` }),
      rewardClose: () => ({ title: '🎁 Награда близко', body: `${n}до награды «${v.reward}» осталось всего ${v.gap} EP.` }),
      comeback: () => ({ title: '🌿 Мы скучаем', body: `${n}ты не сканировал уже ${v.days} дн. Отсканируй контейнер и получи EP — награды ждут.` }),
      daily: () =>
        (v.streak ?? 0) > 0
          ? { title: '🔥 Не прерывай серию', body: `${n}твоя серия — ${v.streak} дн. Зайди и сегодня.` }
          : { title: '🌱 EcoPoint сегодня', body: `${n}зайди и посмотри задания дня.` },
    },
    tr: {
      monthlyReady: () => ({ title: '🏅 Aylık hedefe ulaştın', body: `${n}aylık ${v.goal} tarama hedefini tamamladın. ${v.ep} EP ödülünü al!` }),
      monthlyClose: () => ({ title: '🎯 Çok az kaldı', body: `${n}aylık ${v.goal} tarama hedefine ${v.left} tarama kaldı. Ayın bitmesine ${v.days} gün var.` }),
      rewardClose: () => ({ title: '🎁 Ödül çok yakın', body: `${n}«${v.reward}» ödülüne sadece ${v.gap} EP kaldı.` }),
      comeback: () => ({ title: '🌿 Seni özledik', body: `${n}${v.days} gündür tarama yapmadın. Bir kutu tara, EP kazan — ödüller seni bekliyor.` }),
      daily: () =>
        (v.streak ?? 0) > 0
          ? { title: '🔥 Serini sürdür', body: `${n}${v.streak} günlük serin var, bugün de giriş yap.` }
          : { title: '🌱 Bugün EcoPoint', body: `${n}giriş yap ve günlük görevlere bak.` },
    },
  };
  return T[lang][kind]();
}
