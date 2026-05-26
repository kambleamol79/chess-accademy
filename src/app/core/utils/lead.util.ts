import { formatTimeSlot, fromBatchTimePart, parseTimeSlot } from './batch.util';

/** Combine legacy additional + review columns for display/editing. */
export function mergeAdditionalReview(additional: unknown, review: unknown): string {
  const parts = [additional, review]
    .map((v) => (v === null || v === undefined ? '' : String(v).trim()))
    .filter((s) => s !== '');
  return parts.join('\n\n');
}

/** Parse stored time_slot into native time inputs (supports batch format and legacy text). */
export function parseLeadTimeSlot(slot: string): { start: string; end: string } {
  const trimmed = slot.trim();
  if (!trimmed) {
    return { start: '07:00', end: '08:00' };
  }

  if (/^\d{1,2}\.\d{2}-\d{1,2}\.\d{2}$/.test(trimmed)) {
    return parseTimeSlot(trimmed);
  }

  const colonRange = trimmed.match(/^(\d{1,2}:\d{2})\s*-\s*(\d{1,2}:\d{2})$/);
  if (colonRange) {
    return { start: colonRange[1], end: colonRange[2] };
  }

  const pmAm = trimmed.match(/(\d{1,2}):(\d{2})\s*(AM|PM)/i);
  if (pmAm) {
    let h = parseInt(pmAm[1], 10);
    const m = pmAm[2];
    const period = pmAm[3].toUpperCase();
    if (period === 'PM' && h < 12) {
      h += 12;
    }
    if (period === 'AM' && h === 12) {
      h = 0;
    }
    const start = `${String(h).padStart(2, '0')}:${m}`;
    const endH = (h + 1) % 24;
    const end = `${String(endH).padStart(2, '0')}:${m}`;
    return { start, end };
  }

  if (trimmed.includes('-')) {
    const [a, b] = trimmed.split('-').map((p) => p.trim());
    if (a.includes('.')) {
      return {
        start: fromBatchTimePart(a),
        end: fromBatchTimePart(b)
      };
    }
  }

  return { start: '07:00', end: '08:00' };
}

export function formatLeadTimeSlot(start: string, end: string): string {
  return formatTimeSlot(start, end);
}
