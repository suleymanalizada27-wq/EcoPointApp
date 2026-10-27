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
