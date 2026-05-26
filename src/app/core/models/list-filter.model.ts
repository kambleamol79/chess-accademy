export interface ListFilterField {
  key: string;
  label: string;
  getValue?: (row: Record<string, unknown>) => unknown;
}
