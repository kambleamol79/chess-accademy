import { BatchForm } from '../models/form.model';
import { compareTimeSlots } from './batch.util';

export const BATCH_WEEKDAYS = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'] as const;
export type BatchWeekday = (typeof BATCH_WEEKDAYS)[number];

export const BATCH_CALENDAR_HEADERS = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

export interface BatchCalendarOccurrence {
  batch: BatchForm;
  dayField: 'day_1' | 'day_2';
  coach: string | null;
}

export interface BatchCalendarMonthDay {
  date: Date;
  dayOfMonth: number;
  inCurrentMonth: boolean;
  isToday: boolean;
  weekday: BatchWeekday;
  occurrences: BatchCalendarOccurrence[];
}

const DAY_ALIASES: Record<string, BatchWeekday> = {
  MON: 'MON',
  MONDAY: 'MON',
  TUE: 'TUE',
  TUESDAY: 'TUE',
  WED: 'WED',
  WEDNESDAY: 'WED',
  THU: 'THU',
  THUR: 'THU',
  THURS: 'THU',
  THURSDAY: 'THU',
  FRI: 'FRI',
  FRIDAY: 'FRI',
  SAT: 'SAT',
  SATURDAY: 'SAT',
  SUN: 'SUN',
  SUNDAY: 'SUN'
};

const JS_DAY_TO_WEEKDAY: BatchWeekday[] = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];

export function normalizeWeekday(day: string): BatchWeekday | null {
  return DAY_ALIASES[day.trim().toUpperCase()] ?? null;
}

export function weekdayFromDate(date: Date): BatchWeekday {
  return JS_DAY_TO_WEEKDAY[date.getDay()];
}

export function isSameCalendarDay(a: Date, b: Date): boolean {
  return (
    a.getFullYear() === b.getFullYear() &&
    a.getMonth() === b.getMonth() &&
    a.getDate() === b.getDate()
  );
}

export function startOfMonth(date: Date): Date {
  return new Date(date.getFullYear(), date.getMonth(), 1);
}

export function addDays(date: Date, days: number): Date {
  const next = new Date(date);
  next.setDate(next.getDate() + days);
  return next;
}

/** Monday-based start of week containing `date`. */
export function startOfWeekMonday(date: Date): Date {
  const d = new Date(date.getFullYear(), date.getMonth(), date.getDate());
  const day = d.getDay();
  const diff = day === 0 ? -6 : 1 - day;
  d.setDate(d.getDate() + diff);
  return d;
}

export function monthYearLabel(date: Date): string {
  return date.toLocaleDateString(undefined, { month: 'long', year: 'numeric' });
}

export function weekRangeLabel(weekStart: Date): string {
  const weekEnd = addDays(weekStart, 6);
  const opts: Intl.DateTimeFormatOptions = { month: 'short', day: 'numeric' };
  const start = weekStart.toLocaleDateString(undefined, opts);
  const end = weekEnd.toLocaleDateString(undefined, {
    ...opts,
    year: weekStart.getFullYear() !== weekEnd.getFullYear() ? 'numeric' : undefined
  });
  return `${start} – ${end}, ${weekEnd.getFullYear()}`;
}

export function occurrencesForWeekday(
  batches: BatchForm[],
  weekday: BatchWeekday
): BatchCalendarOccurrence[] {
  const list: BatchCalendarOccurrence[] = [];

  for (const batch of batches) {
    const d1 = normalizeWeekday(batch.day_1);
    if (d1 === weekday) {
      list.push({ batch, dayField: 'day_1', coach: batch.coach_1 });
    }
    const d2 = normalizeWeekday(batch.day_2);
    if (d2 === weekday) {
      list.push({ batch, dayField: 'day_2', coach: batch.coach_2 });
    }
  }

  return list.sort((a, b) => {
    const t = compareTimeSlots(a.batch.time, b.batch.time);
    if (t !== 0) {
      return t;
    }
    return a.batch.batch.localeCompare(b.batch.batch, undefined, { numeric: true });
  });
}

export function buildMonthCalendar(batches: BatchForm[], monthAnchor: Date): BatchCalendarMonthDay[][] {
  const today = new Date();
  const month = monthAnchor.getMonth();
  const year = monthAnchor.getFullYear();
  const gridStart = startOfWeekMonday(startOfMonth(monthAnchor));
  const weeks: BatchCalendarMonthDay[][] = [];

  for (let w = 0; w < 6; w++) {
    const week: BatchCalendarMonthDay[] = [];
    for (let d = 0; d < 7; d++) {
      const date = addDays(gridStart, w * 7 + d);
      const weekday = weekdayFromDate(date);
      week.push({
        date,
        dayOfMonth: date.getDate(),
        inCurrentMonth: date.getMonth() === month && date.getFullYear() === year,
        isToday: isSameCalendarDay(date, today),
        weekday,
        occurrences: occurrencesForWeekday(batches, weekday)
      });
    }
    weeks.push(week);
    const last = week[6];
    if (w >= 4 && last.date.getMonth() !== month && last.date.getDate() < 8) {
      break;
    }
  }

  return weeks;
}

export function buildWeekDays(batches: BatchForm[], weekStart: Date): BatchCalendarMonthDay[] {
  return Array.from({ length: 7 }, (_, i) => {
    const date = addDays(weekStart, i);
    const weekday = weekdayFromDate(date);
    return {
      date,
      dayOfMonth: date.getDate(),
      inCurrentMonth: true,
      isToday: isSameCalendarDay(date, new Date()),
      weekday,
      occurrences: occurrencesForWeekday(batches, weekday)
    };
  });
}

export function buildWeekTimeGrid(batches: BatchForm[]): {
  timeSlots: string[];
  cells: Map<string, BatchCalendarOccurrence[]>;
} {
  const cells = new Map<string, BatchCalendarOccurrence[]>();
  const timeSet = new Set<string>();

  for (const batch of batches) {
    const time = batch.time?.trim() || 'Unscheduled';
    timeSet.add(time);

    const d1 = normalizeWeekday(batch.day_1);
    if (d1) {
      const key = `${time}|${d1}`;
      const list = cells.get(key) ?? [];
      list.push({ batch, dayField: 'day_1', coach: batch.coach_1 });
      cells.set(key, list);
    }

    const d2 = normalizeWeekday(batch.day_2);
    if (d2) {
      const key = `${time}|${d2}`;
      const list = cells.get(key) ?? [];
      list.push({ batch, dayField: 'day_2', coach: batch.coach_2 });
      cells.set(key, list);
    }
  }

  return {
    timeSlots: Array.from(timeSet).sort(compareTimeSlots),
    cells
  };
}

export function weekGridCellKey(time: string, weekday: BatchWeekday): string {
  return `${time}|${weekday}`;
}

export function occurrenceTrack(o: BatchCalendarOccurrence): string {
  return `${o.batch.id}-${o.dayField}`;
}

export function occurrenceTone(o: BatchCalendarOccurrence): 'blue' | 'beige' | 'practice' {
  const notes = (o.batch.notes ?? '').trim();
  if (notes !== '' && notes.toLowerCase().includes('practice')) {
    return 'practice';
  }
  return o.batch.highlight === 'blue' ? 'blue' : 'beige';
}

export function occurrenceTitle(o: BatchCalendarOccurrence): string {
  const notes = (o.batch.notes ?? '').trim();
  if (notes !== '' && notes.toLowerCase().includes('practice')) {
    return notes;
  }
  return o.batch.batch;
}
