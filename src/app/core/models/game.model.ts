export interface ReviewGame {
  id: number;
  student_id: number;
  coach_id: number | null;
  title: string | null;
  pgn: string;
  notes: string | null;
  reviewed_at: string | null;
  created_at: string;
  updated_at: string;
  first_name?: string;
  last_name?: string;
}

export interface CreateGamePayload {
  student_id: number;
  pgn: string;
  title?: string;
  notes?: string;
  coach_id?: number | null;
}

export function reviewGameFromApi(row: Record<string, unknown>): ReviewGame {
  return {
    id: Number(row['id']),
    student_id: Number(row['student_id']),
    coach_id: row['coach_id'] != null ? Number(row['coach_id']) : null,
    title: row['title'] != null ? String(row['title']) : null,
    pgn: String(row['pgn'] ?? ''),
    notes: row['notes'] != null ? String(row['notes']) : null,
    reviewed_at: row['reviewed_at'] != null ? String(row['reviewed_at']) : null,
    created_at: String(row['created_at'] ?? ''),
    updated_at: String(row['updated_at'] ?? ''),
    first_name: row['first_name'] != null ? String(row['first_name']) : undefined,
    last_name: row['last_name'] != null ? String(row['last_name']) : undefined
  };
}

export function studentDisplayName(row: Record<string, unknown>): string {
  const first = String(row['first_name'] ?? row['user_first_name'] ?? '').trim();
  const last = String(row['last_name'] ?? row['user_last_name'] ?? '').trim();
  const email = String(row['email'] ?? row['user_email'] ?? '').trim();
  const name = `${first} ${last}`.trim();
  return name || email || `Student #${row['id']}`;
}
