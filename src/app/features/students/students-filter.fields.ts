import { ListFilterField } from 'src/app/core/models/list-filter.model';
import { STUDENT_MONTH_FIELDS, STUDENT_MONTH_LABELS } from 'src/app/core/models/student-roster.model';

function studentName(row: Record<string, unknown>): string {
  return `${row['first_name'] ?? ''} ${row['last_name'] ?? ''}`.trim();
}

function batchDay(row: Record<string, unknown>): string {
  if (!row['batch_day']) {
    return '';
  }
  const time = row['batch_time'] ? ` · ${row['batch_time']}` : '';
  return `${row['batch_day']}${time}`;
}

const monthFields: ListFilterField[] = STUDENT_MONTH_FIELDS.map((field, i) => ({
  key: field,
  label: STUDENT_MONTH_LABELS[i] ?? field
}));

export const STUDENT_FILTER_FIELDS: ListFilterField[] = [
  { key: 'student_name', label: 'Student name', getValue: studentName },
  { key: 'email', label: 'Email' },
  {
    key: 'contact',
    label: 'Contact no.',
    getValue: (row) => row['phone'] ?? row['parent_phone']
  },
  { key: 'parent_name', label: 'Parent name' },
  { key: 'parent_phone', label: 'Parent phone' },
  { key: 'city', label: 'City' },
  { key: 'level', label: 'Level' },
  { key: 'batch', label: 'Batch' },
  { key: 'batch_day', label: 'Batch / day', getValue: batchDay },
  { key: 'payment_date', label: 'Payment date' },
  { key: 'w_app', label: 'W App' },
  { key: 'total_pay', label: 'Total pay' },
  { key: 'payment_received', label: 'Payment received' },
  ...monthFields
];
