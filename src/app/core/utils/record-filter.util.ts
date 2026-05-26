import { ListFilterField } from '../models/list-filter.model';

export function filterRecords(
  rows: Record<string, unknown>[],
  fieldKey: string,
  query: string,
  fields: ListFilterField[]
): Record<string, unknown>[] {
  const q = query.trim().toLowerCase();
  if (!q) {
    return rows;
  }

  const field = fields.find((f) => f.key === fieldKey) ?? fields[0];
  if (!field) {
    return rows;
  }

  return rows.filter((row) => filterableText(field, row).includes(q));
}

function filterableText(field: ListFilterField, row: Record<string, unknown>): string {
  const raw = field.getValue ? field.getValue(row) : row[field.key];
  if (raw === null || raw === undefined) {
    return '';
  }

  if (raw instanceof Date) {
    return raw.toLocaleString().toLowerCase();
  }

  const text = String(raw).trim();
  if (text === '') {
    return '';
  }

  const asDate = new Date(text);
  if (!Number.isNaN(asDate.getTime()) && /^\d{4}-\d{2}-\d{2}/.test(text)) {
    return `${text} ${asDate.toLocaleDateString()} ${asDate.toLocaleString()}`.toLowerCase();
  }

  return text.toLowerCase();
}
