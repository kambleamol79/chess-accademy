export const STUDENT_MONTH_FIELDS = [
  'month_jan',
  'month_feb',
  'month_mar',
  'month_apr',
  'month_may',
  'month_jun',
  'month_jul',
  'month_aug',
  'month_sep'
] as const;

export const STUDENT_MONTH_LABELS = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP'] as const;

export type StudentMonthField = (typeof STUDENT_MONTH_FIELDS)[number];
