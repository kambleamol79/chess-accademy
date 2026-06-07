import { BatchForm } from '../models/form.model';

export interface BatchTimeSlotGroup {
  time: string;
  batches: BatchForm[];
}

/** Convert native time input value (HH:mm) to batch display part (HH.mm). */
export function toBatchTimePart(hhmm: string): string {
  const [h = '00', m = '00'] = hhmm.trim().split(':');
  return `${h.padStart(2, '0')}.${m.padStart(2, '0')}`;
}

/** Convert batch display part (HH.mm) to native time input value (HH:mm). */
export function fromBatchTimePart(part: string): string {
  const match = part.trim().match(/^(\d{1,2})\.(\d{2})$/);
  if (!match) {
    return '07:00';
  }
  return `${match[1].padStart(2, '0')}:${match[2]}`;
}

/** Parse stored slot "07.00-08.00" into start/end for time inputs. */
export function parseTimeSlot(slot: string): { start: string; end: string } {
  const [startPart = '07.00', endPart = '08.00'] = slot.trim().split('-');
  return {
    start: fromBatchTimePart(startPart),
    end: fromBatchTimePart(endPart)
  };
}

/** Build stored slot from time picker values. */
export function formatTimeSlot(start: string, end: string): string {
  return `${toBatchTimePart(start)}-${toBatchTimePart(end)}`;
}

export function timeInputToMinutes(hhmm: string): number {
  const [h = '0', m = '0'] = hhmm.split(':');
  return parseInt(h, 10) * 60 + parseInt(m, 10);
}

export function isValidTimeSlotRange(start: string, end: string): boolean {
  return timeInputToMinutes(end) > timeInputToMinutes(start);
}

/** Parse start minutes from slots like "07.00-08.00" for sorting. */
export function timeSlotSortKey(slot: string): number {
  const match = slot.trim().match(/^(\d{1,2})\.(\d{2})/);
  if (!match) {
    return Number.MAX_SAFE_INTEGER;
  }
  return parseInt(match[1], 10) * 60 + parseInt(match[2], 10);
}

export function compareTimeSlots(a: string, b: string): number {
  const diff = timeSlotSortKey(a) - timeSlotSortKey(b);
  return diff !== 0 ? diff : a.localeCompare(b);
}

export function groupBatchesByTimeSlot(rows: BatchForm[]): BatchTimeSlotGroup[] {
  const map = new Map<string, BatchForm[]>();
  for (const row of rows) {
    const time = row.time?.trim() || 'Unscheduled';
    const list = map.get(time) ?? [];
    list.push(row);
    map.set(time, list);
  }

  return Array.from(map.entries())
    .sort(([a], [b]) => compareTimeSlots(a, b))
    .map(([time, batches]) => ({
      time,
      batches: [...batches].sort((a, b) => a.batch.localeCompare(b.batch, undefined, { numeric: true }))
    }));
}

/** Derive next batch code (e.g. IB - 8 → IB - 9). */
export function nextBatchCode(existing: string[]): string {
  let maxNum = 0;
  let prefix = 'IB - ';

  for (const raw of existing) {
    const batch = raw.trim();
    const match = batch.match(/^(.+?)\s*-\s*(\d+)$/);
    if (!match) {
      continue;
    }
    const num = parseInt(match[2], 10);
    if (num > maxNum) {
      maxNum = num;
      prefix = `${match[1].trim()} - `;
    }
  }

  return `${prefix}${maxNum + 1}`;
}

export function hasBatchZoom(batch: BatchForm): boolean {
  return !!batch.zoom_join_url?.trim();
}
