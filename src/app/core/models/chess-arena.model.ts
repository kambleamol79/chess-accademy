export type TournamentStatus = 'scheduled' | 'registration' | 'active' | 'finished' | 'cancelled';
export type LiveMatchStatus = 'waiting' | 'active' | 'completed' | 'abandoned';

export interface ChessTournament {
  id: number;
  title: string;
  description: string | null;
  starts_at: string;
  time_control_minutes: number;
  status: TournamentStatus;
  entry_count?: number;
}

export interface LiveMatchSummary {
  id: number;
  tournament_id: number | null;
  white_student_id: number;
  black_student_id: number;
  white_name: string;
  black_name: string;
  status: LiveMatchStatus;
  result: string;
  time_control_minutes: number;
  current_fen: string;
}

export interface LiveMatchMove {
  ply: number;
  uci: string;
  san: string;
  color: 'w' | 'b';
  student_id: number;
  fen_after: string;
}

export interface LiveMatchRevision {
  event_seq: number;
  status: string;
  ply_count: number;
  changed: boolean;
  state?: LiveMatchState;
}

export interface LiveMatchState {
  match: LiveMatchSummary;
  moves: LiveMatchMove[];
  your_color: 'white' | 'black';
  is_your_turn: boolean;
  white_ms_remaining: number;
  black_ms_remaining: number;
  event_seq?: number;
}
