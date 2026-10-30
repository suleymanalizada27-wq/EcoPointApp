/** Business constants. Keep in sync with `AppConstants` in the Flutter app. */
export const CONFIG = {
  scanBaseEp: 50,
  proMultiplier: 2,

  // Anti-abuse (carried over from the legacy security module).
  maxScansPerHour: 10,
  minScanIntervalMs: 3_000,
  maxEpPerDay: 5_000,
  maxWeightPerDayG: 5_000,

  // Weight (smart bin scale): 100 g = 10 EP.
  gramsPerBlock: 100,
  epPerBlock: 10,
  minWeightG: 100,
  maxSingleWeightG: 10_000,
  weightCooldownMs: 30_000,
  deviceFreshnessMs: 5 * 60_000,

  minTransferEp: 1,
  maxTransferEp: 10_000,
  maxTransfersPerHour: 20,

  streakBonusEp: 50,
  streakBonusEveryDays: 7,
  referralBonusEp: 200,
  maxReferralsPerUser: 25,
  referralWindowDays: 14,

  couponCommissionPercent: 5,
  couponMaxEp: 100_000,
  transportMinEp: 100,
  transportFeePercent: 2,
  transportMaxEp: 50_000,

  timeZone: 'Asia/Baku',
  nameMin: 2,
  nameMax: 40,
  bioMax: 120,
} as const;

export const MISSIONS = {
  scan3: { ep: 30, kind: 'scansToday', goal: 3 },
  scan5: { ep: 50, kind: 'scansToday', goal: 5 },
  streak2: { ep: 20, kind: 'streak', goal: 2 },
} as const;

export type MissionId = keyof typeof MISSIONS;

/** Monthly goals: number of scans in the current Baku calendar month. */
export const MONTHLY = {
  m_scan30: { ep: 300, goal: 30 },
  m_scan60: { ep: 700, goal: 60 },
} as const;

export type MonthlyId = keyof typeof MONTHLY;

/** Prizes for the top 3 of the previous week's leaderboard. */
export const WEEKLY_PRIZES = [200, 100, 50] as const;

export const COUPON_PARTNERS = {
  bravo: { id: 'bravo', name: 'Bravo', minEp: 500, epPerAzn: 500 },
  bolmart: { id: 'bolmart', name: 'Bolmart', minEp: 300, epPerAzn: 500 },
} as const;

export type PartnerId = keyof typeof COUPON_PARTNERS;
