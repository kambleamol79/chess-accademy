export type DateRangeValueGetter = (row: Record<string, unknown>) => unknown;

export function filterByDateRange(
  rows: Record<string, unknown>[],
  getDateValue: string | DateRangeValueGetter,
  from: string,
  to: string
): Record<string, unknown>[] {
  const fromKey = from.trim();
  const toKey = to.trim();
  if (!fromKey && !toKey) {
    return rows;
  }

  if (fromKey && toKey && fromKey > toKey) {
    return [];
  }

  const readDate =
    typeof getDateValue === 'string'
      ? (row: Record<string, unknown>) => row[getDateValue]
      : getDateValue;

  return rows.filter((row) => {
    const rowKey = toDateKey(readDate(row));
    if (rowKey === null) {
      return false;
    }
    if (fromKey && rowKey < fromKey) {
      return false;
    }
    if (toKey && rowKey > toKey) {
      return false;
    }
    return true;
  });
}

function toDateKey(value: unknown): string | null {
  if (value === null || value === undefined || value === '') {
    return null;
  }

  const d = new Date(String(value));
  if (Number.isNaN(d.getTime())) {
    return null;
  }

  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');

  return `${y}-${m}-${day}`;
}
