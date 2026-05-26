export const LEAD_CSV_TEMPLATE_HEADERS = [
  'DATE',
  'CHILD NA',
  'PARENTS',
  'NUMBER',
  'MAIL',
  'AGE',
  'STD',
  'CITY',
  'Q1',
  'Q2',
  'Q3',
  'TIME',
  'ATTD - NO',
  'MODULE',
  'INT',
  'NOT INT',
  'PAID',
  'DNP',
  'ADDITIONAL REVIEW'
] as const;

/** Example rows for the downloadable template (matches spreadsheet layout). */
export const LEAD_CSV_TEMPLATE_SAMPLE_ROWS: string[][] = [
  [
    '6/5/2025 13:00',
    'Vedansh',
    'Avantika sari',
    '9876543210',
    'parent@example.com',
    '12',
    '6th',
    'Kanpur',
    'Yes',
    'No',
    'Yes',
    '19.00-20.00',
    '',
    'IB - 1',
    'INT',
    '',
    '',
    '',
    'Follow-up note'
  ],
  [
    '6/9/2025 10:30',
    'Sahiba kaur',
    'Puja Gope',
    '9123456789',
    'puja25.gope@gmail.com',
    '7',
    '4th',
    'Navi Mumbai',
    'No',
    'Yes',
    'No',
    '20.00-21.00',
    '',
    'IB - 2',
    '',
    '',
    '',
    '',
    ''
  ]
];

/** Path served from app assets after build. */
export const LEAD_CSV_TEMPLATE_ASSET_PATH = 'assets/templates/leads-upload-template.csv';

function csvCell(value: string): string {
  if (/[",\n\r]/.test(value)) {
    return `"${value.replace(/"/g, '""')}"`;
  }
  return value;
}

function csvRow(cells: string[]): string {
  return cells.map(csvCell).join(',');
}

const HEADER_MAP: Record<string, string> = {
  DATE: 'captured_at',
  'CHILD NA': 'child_name',
  'CHILD NAME': 'child_name',
  PARENTS: 'parents_name',
  'PARENTS NAME': 'parents_name',
  NUMBER: 'phone',
  PHONE: 'phone',
  MAIL: 'email',
  EMAIL: 'email',
  AGE: 'age',
  STD: 'std',
  STANDARD: 'std',
  CITY: 'city',
  Q1: 'q1',
  Q2: 'q2',
  Q3: 'q3',
  TIME: 'time_slot',
  'TIME SLOT': 'time_slot',
  'ATTD - NO': 'attd_no',
  'ATTD-NO': 'attd_no',
  ATTD: 'attd_no',
  MODULE: 'module',
  INT: 'status_int',
  INTERESTED: 'status_int',
  'NOT INT': 'not_interested',
  PAID: 'paid',
  DNP: 'dnp',
  'ADDITIONAL REVIEW': 'review',
  ADDITIONAL: 'additional',
  REVIEW: 'review'
};

export interface LeadCsvParseResult {
  leads: Record<string, unknown>[];
  errors: { row: number; message: string }[];
}

function normalizeHeader(cell: string): string {
  return cell.trim().toUpperCase().replace(/\s+/g, ' ');
}

function parseCsvLine(line: string): string[] {
  const out: string[] = [];
  let cur = '';
  let inQuotes = false;

  for (let i = 0; i < line.length; i++) {
    const ch = line[i];
    if (ch === '"') {
      if (inQuotes && line[i + 1] === '"') {
        cur += '"';
        i++;
      } else {
        inQuotes = !inQuotes;
      }
      continue;
    }
    if (ch === ',' && !inQuotes) {
      out.push(cur.trim());
      cur = '';
      continue;
    }
    cur += ch;
  }
  out.push(cur.trim());

  return out;
}

function normalizeYesNo(value: string): string | null {
  const v = value.trim().toLowerCase();
  if (['yes', 'y', '1'].includes(v)) {
    return 'Yes';
  }
  if (['no', 'n', '0'].includes(v)) {
    return 'No';
  }
  if (v === 'yes' || v === 'no') {
    return v.charAt(0).toUpperCase() + v.slice(1);
  }
  return null;
}

function normalizeField(field: string, value: string): unknown {
  const v = value.trim();
  if (!v) {
    return null;
  }

  switch (field) {
    case 'captured_at': {
      const d = new Date(v);
      if (Number.isNaN(d.getTime())) {
        return null;
      }
      const pad = (n: number) => String(n).padStart(2, '0');
      return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())} ${pad(d.getHours())}:${pad(d.getMinutes())}:00`;
    }
    case 'q1':
    case 'q2':
    case 'q3':
      return normalizeYesNo(v);
    case 'status_int':
      return v.toUpperCase() === 'INT' || v.toLowerCase() === 'yes' ? 'INT' : v;
    case 'paid':
      return v.toUpperCase() === 'PAID' || v.toLowerCase() === 'yes' ? 'PAID' : v;
    default:
      return v;
  }
}

export function buildLeadCsvTemplate(): string {
  const lines = [
    csvRow([...LEAD_CSV_TEMPLATE_HEADERS]),
    ...LEAD_CSV_TEMPLATE_SAMPLE_ROWS.map((row) => csvRow(row))
  ];
  return `${lines.join('\n')}\n`;
}

export function downloadLeadCsvTemplate(): void {
  const blob = new Blob(['\uFEFF', buildLeadCsvTemplate()], { type: 'text/csv;charset=utf-8' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = 'leads-upload-template.csv';
  a.click();
  URL.revokeObjectURL(url);
}

export function parseLeadCsv(text: string): LeadCsvParseResult {
  const lines = text.replace(/^\uFEFF/, '').split(/\r?\n/).filter((l) => l.trim() !== '');
  const leads: Record<string, unknown>[] = [];
  const errors: { row: number; message: string }[] = [];

  if (lines.length === 0) {
    return { leads, errors: [{ row: 1, message: 'File is empty' }] };
  }

  const headerCells = parseCsvLine(lines[0]);
  const fields = headerCells.map((h) => HEADER_MAP[normalizeHeader(h)] ?? null);

  if (!fields.some((f) => f === 'child_name')) {
    return {
      leads,
      errors: [{ row: 1, message: 'Missing CHILD NA column in header row' }]
    };
  }

  for (let i = 1; i < lines.length; i++) {
    const rowNum = i + 1;
    const values = parseCsvLine(lines[i]);
    const row: Record<string, unknown> = {};
    let hasData = false;

    fields.forEach((field, idx) => {
      if (!field || values[idx] === undefined) {
        return;
      }
      const raw = values[idx].trim();
      if (!raw) {
        return;
      }
      hasData = true;
      const normalized = normalizeField(field, raw);
      if (normalized !== null && normalized !== '') {
        row[field] = normalized;
      }
    });

    if (!hasData) {
      continue;
    }

    const child = String(row['child_name'] ?? '').trim();
    if (!child) {
      errors.push({ row: rowNum, message: 'Child name is required' });
      continue;
    }

    if (!row['captured_at']) {
      const now = new Date();
      const pad = (n: number) => String(n).padStart(2, '0');
      row['captured_at'] =
        `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())} ` +
        `${pad(now.getHours())}:${pad(now.getMinutes())}:00`;
    }

    if (row['additional'] || row['review']) {
      const extra = String(row['additional'] ?? '').trim();
      const rev = String(row['review'] ?? '').trim();
      row['review'] = [extra, rev].filter(Boolean).join('\n\n');
      row['additional'] = null;
    }

    leads.push(row);
  }

  return { leads, errors };
}
