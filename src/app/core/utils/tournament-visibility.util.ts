import { TournamentCta } from '../services/settings.service';

function parseDate(value: string): string | null {
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(value.trim());
  if (!match) {
    return null;
  }

  return `${match[1]}-${match[2]}-${match[3]}`;
}

function currentDateInTimezone(timezone: string): string | null {
  try {
    return new Intl.DateTimeFormat('en-CA', { timeZone: timezone }).format(new Date());
  } catch {
    return null;
  }
}

export function isTournamentVisibleNow(cta: Pick<TournamentCta, 'timezone' | 'visible_from' | 'visible_until'>): boolean {
  const from = parseDate(cta.visible_from?.trim() ?? '');
  const until = parseDate(cta.visible_until?.trim() ?? '');
  if (!from && !until) {
    return true;
  }

  const today = currentDateInTimezone(cta.timezone);
  if (!today) {
    return true;
  }

  if (from && today < from) {
    return false;
  }

  if (until && today > until) {
    return false;
  }

  return true;
}

export function normalizeVisibleDate(value: unknown): string {
  const raw = String(value ?? '').trim();
  return parseDate(raw) ?? '';
}
