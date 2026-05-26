import { ListFilterField } from 'src/app/core/models/list-filter.model';
import { mergeAdditionalReview } from 'src/app/core/utils/lead.util';

export const LEAD_FILTER_FIELDS: ListFilterField[] = [
  { key: 'child_name', label: 'Child name' },
  { key: 'parents_name', label: 'Parents' },
  { key: 'phone', label: 'Number' },
  { key: 'email', label: 'Mail' },
  { key: 'age', label: 'Age' },
  { key: 'std', label: 'Std' },
  { key: 'city', label: 'City' },
  { key: 'q1', label: 'Q1' },
  { key: 'q2', label: 'Q2' },
  { key: 'q3', label: 'Q3' },
  { key: 'time_slot', label: 'Time' },
  { key: 'attd_no', label: 'ATTD - NO' },
  { key: 'module', label: 'Module' },
  { key: 'status_int', label: 'INT' },
  { key: 'not_interested', label: 'Not interested' },
  { key: 'paid', label: 'Paid' },
  { key: 'dnp', label: 'DNP' },
  {
    key: 'additional_review',
    label: 'Additional review',
    getValue: (row) => mergeAdditionalReview(row['additional'], row['review'])
  },
  { key: 'captured_at', label: 'Date' }
];
