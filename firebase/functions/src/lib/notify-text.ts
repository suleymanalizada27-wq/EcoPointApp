export type Lang = 'az' | 'en' | 'ru' | 'tr' | 'es' | 'de' | 'it' | 'zh' | 'ja' | 'ko' | 'ar' | 'fa' | 'hi' | 'pt' | 'vi' | 'fr';
export const LANGS: readonly Lang[] = ['az', 'en', 'ru', 'tr', 'es', 'de', 'it', 'zh', 'ja', 'ko', 'ar', 'fa', 'hi', 'pt', 'vi', 'fr'];

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
    case 'es':
      return {
        title: '🔥 Bonificación diaria',
        body: alive
          ? `Tu racha de ${streak} días sigue en marcha. ¡Regístrate hoy para mantenerla!`
          : '¡Regístrate hoy y empieza a ganar EP!',
      };
    case 'de':
      return {
        title: '🔥 Tagesbonus',
        body: alive
          ? `Deine ${streak}-Tage-Serie läuft. Check heute ein, um sie zu halten!`
          : 'Check heute ein und sammle EP!',
      };
    case 'it':
      return {
        title: '🔥 Bonus giornaliero',
        body: alive
          ? `La tua serie di ${streak} giorni continua. Fai il check-in oggi per non perderla!`
          : 'Fai il check-in oggi e inizia a guadagnare EP!',
      };
    case 'zh':
      return {
        title: '🔥 每日奖励',
        body: alive
          ? `您已连续打卡 ${streak} 天，今天也来打卡，保持连续记录！`
          : '今天来打卡，开始赚取 EP 吧！',
      };
    case 'ja':
      return {
        title: '🔥 デイリーボーナス',
        body: alive
          ? `${streak} 日連続中です。今日もチェックインして記録を守りましょう！`
          : '今日チェックインして EP を貯めはじめましょう！',
      };
    case 'ko':
      return {
        title: '🔥 일일 보너스',
        body: alive
          ? `${streak}일 연속 출석 중입니다. 오늘도 출석해서 기록을 이어가세요!`
          : '오늘 출석하고 EP를 적립해 보세요!',
      };
    case 'ar':
      return {
        title: '🔥 المكافأة اليومية',
        body: alive
          ? `سلسلتك المستمرة منذ ${streak} أيام ما زالت قائمة. سجّل حضورك اليوم للحفاظ عليها!`
          : 'سجّل حضورك اليوم وابدأ بكسب EP!',
      };
    case 'fa':
      return {
        title: '🔥 پاداش روزانه',
        body: alive
          ? `رشته ${streak} روزه‌ات ادامه دارد. امروز هم حضور بزن تا از دست نرود!`
          : 'امروز حضور بزن و کسب EP را شروع کن!',
      };
    case 'hi':
      return {
        title: '🔥 दैनिक बोनस',
        body: alive
          ? `आपकी ${streak} दिन की स्ट्रीक चल रही है। इसे बनाए रखने के लिए आज चेक-इन करें!`
          : 'आज चेक-इन करें और EP कमाना शुरू करें!',
      };
    case 'pt':
      return {
        title: '🔥 Bônus diário',
        body: alive
          ? `Sua sequência de ${streak} dias continua. Faça check-in hoje para mantê-la!`
          : 'Faça check-in hoje e comece a ganhar EP!',
      };
    case 'fr':
      return {
        title: '🔥 Bonus quotidien',
        body: alive
          ? `Votre série de ${streak} jours continue. Pointez aujourd’hui pour la garder !`
          : 'Pointez aujourd’hui et commencez à gagner des EP !',
      };
    case 'vi':
      return {
        title: '🔥 Thưởng hằng ngày',
        body: alive
          ? `Chuỗi ${streak} ngày của bạn vẫn đang tiếp diễn. Hãy điểm danh hôm nay để giữ chuỗi!`
          : 'Hãy điểm danh hôm nay và bắt đầu kiếm EP!',
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
    case 'es':
      return {
        title: '⏳ No pierdas tu racha',
        body: `Tu racha de ${streak} días se reinicia esta noche si no te registras.`,
      };
    case 'de':
      return {
        title: '⏳ Verliere deine Serie nicht',
        body: `Deine ${streak}-Tage-Serie wird heute Nacht zurückgesetzt, wenn du nicht eincheckst.`,
      };
    case 'it':
      return {
        title: '⏳ Non perdere la tua serie',
        body: `La tua serie di ${streak} giorni si azzera stanotte se non fai il check-in.`,
      };
    case 'zh':
      return {
        title: '⏳ 别丢了连续记录',
        body: `今晚如果不打卡，您 ${streak} 天的连续记录将会清零。`,
      };
    case 'ja':
      return {
        title: '⏳ 連続記録を守ろう',
        body: `今夜までにチェックインしないと、${streak} 日の連続記録がリセットされます。`,
      };
    case 'ko':
      return {
        title: '⏳ 연속 기록을 지키세요',
        body: `오늘 밤까지 출석하지 않으면 ${streak}일 연속 기록이 초기화됩니다.`,
      };
    case 'ar':
      return {
        title: '⏳ لا تفقد سلسلتك',
        body: `ستُعاد سلسلتك البالغة ${streak} أيام إلى الصفر الليلة ما لم تسجّل حضورك.`,
      };
    case 'fa':
      return {
        title: '⏳ رشته‌ات را از دست نده',
        body: `اگر امروز حضور نزنی، رشته ${streak} روزه‌ات امشب صفر می‌شود.`,
      };
    case 'hi':
      return {
        title: '⏳ अपनी स्ट्रीक न खोएँ',
        body: `अगर आज चेक-इन नहीं किया तो आपकी ${streak} दिन की स्ट्रीक आज रात रीसेट हो जाएगी।`,
      };
    case 'pt':
      return {
        title: '⏳ Não perca sua sequência',
        body: `Sua sequência de ${streak} dias será zerada esta noite se você não fizer check-in.`,
      };
    case 'fr':
      return {
        title: '⏳ Ne perdez pas votre série',
        body: `Votre série de ${streak} jours sera réinitialisée cette nuit si vous ne pointez pas.`,
      };
    case 'vi':
      return {
        title: '⏳ Đừng để mất chuỗi ngày',
        body: `Chuỗi ${streak} ngày của bạn sẽ về 0 vào tối nay nếu bạn không điểm danh.`,
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
    case 'es':
      return { title: '🏆 Premio semanal', body: `¡Quedaste en el puesto ${rank} la semana pasada! +${ep} EP ya están en tu cartera.` };
    case 'de':
      return { title: '🏆 Wochenpreis', body: `Du warst letzte Woche auf Platz ${rank}! +${ep} EP sind in deiner Wallet.` };
    case 'it':
      return { title: '🏆 Premio settimanale', body: `Sei arrivato ${rank}° la settimana scorsa! +${ep} EP sono nel tuo portafoglio.` };
    case 'zh':
      return { title: '🏆 每周奖励', body: `您上周排名第 ${rank}！+${ep} EP 已到账。` };
    case 'ja':
      return { title: '🏆 週間賞', body: `先週は ${rank} 位でした！+${ep} EP がウォレットに入りました。` };
    case 'ko':
      return { title: '🏆 주간 보상', body: `지난주 ${rank}위를 하셨어요! +${ep} EP가 지갑에 들어왔습니다.` };
    case 'ar':
      return { title: '🏆 جائزة الأسبوع', body: `حصلت على المركز ${rank} الأسبوع الماضي! أُضيفت +${ep} EP إلى محفظتك.` };
    case 'fa':
      return { title: '🏆 جایزه هفته', body: `هفته گذشته رتبه ${rank} را کسب کردی! +${ep} EP به کیف پولت اضافه شد.` };
    case 'hi':
      return { title: '🏆 साप्ताहिक इनाम', body: `पिछले सप्ताह आप ${rank} नंबर पर रहे! +${ep} EP आपके वॉलेट में आ गए हैं।` };
    case 'pt':
      return { title: '🏆 Prêmio semanal', body: `Você ficou em ${rank}º lugar na semana passada! +${ep} EP já estão na sua carteira.` };
    case 'fr':
      return { title: '🏆 Prix de la semaine', body: `Vous étiez ${rank}e la semaine dernière ! +${ep} EP sont dans votre portefeuille.` };
    case 'vi':
      return { title: '🏆 Giải thưởng tuần', body: `Tuần trước bạn xếp hạng ${rank}! +${ep} EP đã vào ví của bạn.` };
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
    case 'es':
      return {
        title: '📊 Resumen semanal',
        body: `La semana pasada ganaste ${ep} EP con ${scans} escaneos. ¡Sigue así!`,
      };
    case 'de':
      return {
        title: '📊 Wochenübersicht',
        body: `Letzte Woche hast du ${ep} EP mit ${scans} Scans verdient. Weiter so!`,
      };
    case 'it':
      return {
        title: '📊 Riepilogo settimanale',
        body: `La settimana scorsa hai guadagnato ${ep} EP con ${scans} scansioni. Continua così!`,
      };
    case 'zh':
      return {
        title: '📊 每周总结',
        body: `上周您扫描了 ${scans} 次，赚取了 ${ep} EP。继续加油！`,
      };
    case 'ja':
      return {
        title: '📊 週間まとめ',
        body: `先週は ${scans} 回のスキャンで ${ep} EP を獲得しました。この調子で！`,
      };
    case 'ko':
      return {
        title: '📊 주간 요약',
        body: `지난주 ${scans}번 스캔해서 ${ep} EP를 적립했어요. 계속 힘내세요!`,
      };
    case 'ar':
      return {
        title: '📊 ملخص الأسبوع',
        body: `الأسبوع الماضي كسبت ${ep} EP من ${scans} عملية مسح. واصل!`,
      };
    case 'fa':
      return {
        title: '📊 خلاصه هفته',
        body: `هفته گذشته با ${scans} اسکن، ${ep} EP کسب کردی. ادامه بده!`,
      };
    case 'hi':
      return {
        title: '📊 साप्ताहिक सारांश',
        body: `पिछले सप्ताह आपने ${scans} स्कैन से ${ep} EP कमाए। ऐसे ही जारी रखें!`,
      };
    case 'pt':
      return {
        title: '📊 Resumo semanal',
        body: `Na semana passada você ganhou ${ep} EP com ${scans} leituras. Continue assim!`,
      };
    case 'fr':
      return {
        title: '📊 Bilan de la semaine',
        body: `La semaine dernière, vous avez gagné ${ep} EP avec ${scans} scans. Continuez !`,
      };
    case 'vi':
      return {
        title: '📊 Tóm tắt tuần',
        body: `Tuần trước bạn kiếm được ${ep} EP với ${scans} lượt quét. Cố gắng phát huy nhé!`,
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
    es: {
      monthlyReady: () => ({ title: '🏅 Objetivo mensual cumplido', body: `${n}completaste el objetivo mensual de ${v.goal} escaneos. ¡Reclama tus ${v.ep} EP!` }),
      monthlyClose: () => ({ title: '🎯 Ya casi lo logras', body: `${n}te faltan solo ${v.left} escaneos para tu objetivo mensual de ${v.goal}. Quedan ${v.days} días de este mes.` }),
      rewardClose: () => ({ title: '🎁 Premio al alcance', body: `${n}solo te faltan ${v.gap} EP para «${v.reward}».` }),
      comeback: () => ({ title: '🌿 Te echamos de menos', body: `${n}llevas ${v.days} días sin escanear. Escanea un contenedor y gana EP: tus premios te esperan.` }),
      daily: () =>
        (v.streak ?? 0) > 0
          ? { title: '🔥 Mantén tu racha', body: `${n}llevas una racha de ${v.streak} días, regístrate también hoy.` }
          : { title: '🌱 EcoPoint hoy', body: `${n}entra y descubre las misiones de hoy.` },
    },
    de: {
      monthlyReady: () => ({ title: '🏅 Monatsziel erreicht', body: `${n}du hast das Monatsziel von ${v.goal} Scans geschafft. Hol dir deine ${v.ep} EP!` }),
      monthlyClose: () => ({ title: '🎯 Fast geschafft', body: `${n}dir fehlen nur noch ${v.left} Scans bis zum Monatsziel von ${v.goal}. Noch ${v.days} Tage in diesem Monat.` }),
      rewardClose: () => ({ title: '🎁 Prämie in Reichweite', body: `${n}dir fehlen nur ${v.gap} EP bis zu „${v.reward}“.` }),
      comeback: () => ({ title: '🌿 Wir vermissen dich', body: `${n}seit ${v.days} Tagen kein Scan. Scanne einen Behälter und sammle EP – deine Prämien warten.` }),
      daily: () =>
        (v.streak ?? 0) > 0
          ? { title: '🔥 Halte deine Serie', body: `${n}du hast eine ${v.streak}-Tage-Serie, check auch heute ein.` }
          : { title: '🌱 EcoPoint heute', body: `${n}check ein und sieh dir die heutigen Missionen an.` },
    },
    it: {
      monthlyReady: () => ({ title: '🏅 Obiettivo mensile raggiunto', body: `${n}hai completato l’obiettivo mensile di ${v.goal} scansioni. Ritira i tuoi ${v.ep} EP!` }),
      monthlyClose: () => ({ title: '🎯 Ci sei quasi', body: `${n}mancano solo ${v.left} scansioni al tuo obiettivo mensile di ${v.goal}. Restano ${v.days} giorni di questo mese.` }),
      rewardClose: () => ({ title: '🎁 Premio a portata di mano', body: `${n}ti mancano solo ${v.gap} EP per «${v.reward}».` }),
      comeback: () => ({ title: '🌿 Ci manchi', body: `${n}non scansioni da ${v.days} giorni. Scansiona un contenitore e guadagna EP: i tuoi premi ti aspettano.` }),
      daily: () =>
        (v.streak ?? 0) > 0
          ? { title: '🔥 Mantieni la serie', body: `${n}hai una serie di ${v.streak} giorni, fai il check-in anche oggi.` }
          : { title: '🌱 EcoPoint oggi', body: `${n}entra e scopri le missioni di oggi.` },
    },
    zh: {
      monthlyReady: () => ({ title: '🏅 已达成月度目标', body: `${n}您已完成每月 ${v.goal} 次扫描的目标，快来领取 ${v.ep} EP！` }),
      monthlyClose: () => ({ title: '🎯 就差一点了', body: `${n}距离每月 ${v.goal} 次扫描的目标只差 ${v.left} 次，本月还剩 ${v.days} 天。` }),
      rewardClose: () => ({ title: '🎁 奖励触手可及', body: `${n}距离「${v.reward}」只差 ${v.gap} EP。` }),
      comeback: () => ({ title: '🌿 我们想你了', body: `${n}您已经 ${v.days} 天没有扫描了。扫描一个回收箱赚取 EP，奖励在等您。` }),
      daily: () =>
        (v.streak ?? 0) > 0
          ? { title: '🔥 保持连续记录', body: `${n}您已连续打卡 ${v.streak} 天，今天也别忘了打卡。` }
          : { title: '🌱 今天的 EcoPoint', body: `${n}来打卡，看看今天的任务。` },
    },
    ja: {
      monthlyReady: () => ({ title: '🏅 月間目標を達成', body: `${n}月間 ${v.goal} 回のスキャン目標を達成しました。${v.ep} EP を受け取りましょう！` }),
      monthlyClose: () => ({ title: '🎯 あと少し', body: `${n}月間 ${v.goal} 回の目標まであと ${v.left} 回です。今月は残り ${v.days} 日。` }),
      rewardClose: () => ({ title: '🎁 特典まであと少し', body: `${n}「${v.reward}」まであと ${v.gap} EP です。` }),
      comeback: () => ({ title: '🌿 お待ちしています', body: `${n}${v.days} 日間スキャンしていません。ボックスをスキャンして EP を貯めましょう。特典が待っています。` }),
      daily: () =>
        (v.streak ?? 0) > 0
          ? { title: '🔥 連続記録を続けよう', body: `${n}${v.streak} 日連続中です。今日もチェックインしましょう。` }
          : { title: '🌱 今日の EcoPoint', body: `${n}チェックインして、今日のミッションを見てみましょう。` },
    },
    ko: {
      monthlyReady: () => ({ title: '🏅 월간 목표 달성', body: `${n}월간 ${v.goal}회 스캔 목표를 달성했어요. ${v.ep} EP를 받아 가세요!` }),
      monthlyClose: () => ({ title: '🎯 거의 다 왔어요', body: `${n}월간 ${v.goal}회 스캔 목표까지 ${v.left}회 남았어요. 이번 달은 ${v.days}일 남았습니다.` }),
      rewardClose: () => ({ title: '🎁 리워드가 코앞이에요', body: `${n}"${v.reward}"까지 ${v.gap} EP만 남았어요.` }),
      comeback: () => ({ title: '🌿 보고 싶었어요', body: `${n}${v.days}일 동안 스캔하지 않으셨어요. 수거함을 스캔하고 EP를 적립해 보세요. 리워드가 기다리고 있어요.` }),
      daily: () =>
        (v.streak ?? 0) > 0
          ? { title: '🔥 연속 기록을 이어가세요', body: `${n}${v.streak}일 연속 출석 중이에요. 오늘도 출석하세요.` }
          : { title: '🌱 오늘의 EcoPoint', body: `${n}출석하고 오늘의 미션을 확인해 보세요.` },
    },
    ar: {
      monthlyReady: () => ({ title: '🏅 بلغت الهدف الشهري', body: `${n}أكملت هدف ${v.goal} عملية مسح شهريًا. استلم ${v.ep} EP!` }),
      monthlyClose: () => ({ title: '🎯 اقتربت من الهدف', body: `${n}تبقّى ${v.left} عمليات مسح فقط لبلوغ هدفك الشهري (${v.goal}). تبقّى ${v.days} أيام من هذا الشهر.` }),
      rewardClose: () => ({ title: '🎁 المكافأة في متناولك', body: `${n}تبقّى لك ${v.gap} EP فقط للحصول على «${v.reward}».` }),
      comeback: () => ({ title: '🌿 اشتقنا إليك', body: `${n}لم تمسح أي حاوية منذ ${v.days} أيام. امسح حاوية واكسب EP — مكافآتك بانتظارك.` }),
      daily: () =>
        (v.streak ?? 0) > 0
          ? { title: '🔥 حافظ على سلسلتك', body: `${n}سلسلتك الحالية ${v.streak} أيام، سجّل حضورك اليوم أيضًا.` }
          : { title: '🌱 EcoPoint اليوم', body: `${n}ادخل وتعرّف على مهام اليوم.` },
    },
    fa: {
      monthlyReady: () => ({ title: '🏅 به هدف ماهانه رسیدی', body: `${n}هدف ماهانه ${v.goal} اسکن را کامل کردی. ${v.ep} EP خود را دریافت کن!` }),
      monthlyClose: () => ({ title: '🎯 کم مانده', body: `${n}فقط ${v.left} اسکن تا هدف ماهانه ${v.goal} اسکنی مانده است. ${v.days} روز از این ماه باقی است.` }),
      rewardClose: () => ({ title: '🎁 جایزه نزدیک است', body: `${n}فقط ${v.gap} EP تا «${v.reward}» مانده است.` }),
      comeback: () => ({ title: '🌿 دلمان برایت تنگ شده', body: `${n}${v.days} روز است که اسکن نکرده‌ای. یک سطل اسکن کن و EP بگیر — جایزه‌ها منتظرت هستند.` }),
      daily: () =>
        (v.streak ?? 0) > 0
          ? { title: '🔥 رشته‌ات را حفظ کن', body: `${n}رشته ${v.streak} روزه داری، امروز هم حضور بزن.` }
          : { title: '🌱 امروز در EcoPoint', body: `${n}وارد شو و مأموریت‌های امروز را ببین.` },
    },
    hi: {
      monthlyReady: () => ({ title: '🏅 मासिक लक्ष्य पूरा हुआ', body: `${n}आपने ${v.goal} स्कैन का मासिक लक्ष्य पूरा कर लिया। अपने ${v.ep} EP ले लें!` }),
      monthlyClose: () => ({ title: '🎯 बस थोड़ा और', body: `${n}${v.goal} स्कैन के मासिक लक्ष्य में सिर्फ़ ${v.left} स्कैन बाकी हैं। इस महीने ${v.days} दिन बचे हैं।` }),
      rewardClose: () => ({ title: '🎁 इनाम पास है', body: `${n}«${v.reward}» के लिए बस ${v.gap} EP बाकी हैं।` }),
      comeback: () => ({ title: '🌿 हमें आपकी याद आ रही है', body: `${n}आपने ${v.days} दिन से स्कैन नहीं किया। कोई डिब्बा स्कैन करें, EP कमाएँ — इनाम आपका इंतज़ार कर रहे हैं।` }),
      daily: () =>
        (v.streak ?? 0) > 0
          ? { title: '🔥 अपनी स्ट्रीक बनाए रखें', body: `${n}आपकी ${v.streak} दिन की स्ट्रीक है, आज भी चेक-इन करें।` }
          : { title: '🌱 आज EcoPoint पर', body: `${n}चेक-इन करें और आज के मिशन देखें।` },
    },
    pt: {
      monthlyReady: () => ({ title: '🏅 Meta mensal atingida', body: `${n}você concluiu a meta mensal de ${v.goal} leituras. Resgate seus ${v.ep} EP!` }),
      monthlyClose: () => ({ title: '🎯 Quase lá', body: `${n}faltam apenas ${v.left} leituras para a meta mensal de ${v.goal}. Restam ${v.days} dias neste mês.` }),
      rewardClose: () => ({ title: '🎁 Prêmio ao seu alcance', body: `${n}faltam só ${v.gap} EP para «${v.reward}».` }),
      comeback: () => ({ title: '🌿 Sentimos sua falta', body: `${n}você está há ${v.days} dias sem escanear. Escaneie uma lixeira e ganhe EP — seus prêmios esperam por você.` }),
      daily: () =>
        (v.streak ?? 0) > 0
          ? { title: '🔥 Mantenha sua sequência', body: `${n}você tem uma sequência de ${v.streak} dias, faça check-in hoje também.` }
          : { title: '🌱 EcoPoint hoje', body: `${n}entre e veja as missões de hoje.` },
    },
    fr: {
      monthlyReady: () => ({ title: '🏅 Objectif mensuel atteint', body: `${n}vous avez atteint l’objectif mensuel de ${v.goal} scans. Récupérez vos ${v.ep} EP !` }),
      monthlyClose: () => ({ title: '🎯 Presque là', body: `${n}il ne vous manque que ${v.left} scans pour l’objectif mensuel de ${v.goal}. Il reste ${v.days} jours ce mois-ci.` }),
      rewardClose: () => ({ title: '🎁 Récompense à portée de main', body: `${n}il ne vous manque que ${v.gap} EP pour « ${v.reward} ».` }),
      comeback: () => ({ title: '🌿 Vous nous manquez', body: `${n}aucun scan depuis ${v.days} jours. Scannez une borne et gagnez des EP : vos récompenses vous attendent.` }),
      daily: () =>
        (v.streak ?? 0) > 0
          ? { title: '🔥 Gardez votre série', body: `${n}vous avez une série de ${v.streak} jours, pointez aussi aujourd’hui.` }
          : { title: '🌱 EcoPoint aujourd’hui', body: `${n}pointez et découvrez les missions du jour.` },
    },
    vi: {
      monthlyReady: () => ({ title: '🏅 Đã đạt mục tiêu tháng', body: `${n}bạn đã hoàn thành mục tiêu ${v.goal} lượt quét trong tháng. Hãy nhận ${v.ep} EP của bạn!` }),
      monthlyClose: () => ({ title: '🎯 Sắp đạt rồi', body: `${n}chỉ còn ${v.left} lượt quét nữa là đạt mục tiêu ${v.goal} lượt trong tháng. Tháng này còn ${v.days} ngày.` }),
      rewardClose: () => ({ title: '🎁 Quà đã trong tầm tay', body: `${n}chỉ còn ${v.gap} EP nữa là đổi được «${v.reward}».` }),
      comeback: () => ({ title: '🌿 Chúng tôi nhớ bạn', body: `${n}bạn đã ${v.days} ngày chưa quét. Hãy quét một thùng rác và nhận EP — quà đang chờ bạn.` }),
      daily: () =>
        (v.streak ?? 0) > 0
          ? { title: '🔥 Giữ chuỗi ngày của bạn', body: `${n}bạn đang có chuỗi ${v.streak} ngày, hôm nay hãy điểm danh nhé.` }
          : { title: '🌱 EcoPoint hôm nay', body: `${n}hãy vào xem các nhiệm vụ của hôm nay.` },
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
