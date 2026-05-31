import { ComputerLevel, GameTimeControl, PlayerColor, PracticeGameMove, PracticeMode } from './chess-practice.model';

export type PracticeSessionResult =
  | 'ongoing'
  | 'win'
  | 'loss'
  | 'draw'
  | 'ended'
  | 'timeout_win'
  | 'timeout_loss';

export interface PracticeSessionSummary {
  id: number;
  mode: PracticeMode;
  level: ComputerLevel | string | null;
  player_color: PlayerColor;
  time_control_minutes: GameTimeControl;
  start_fen: string;
  result: PracticeSessionResult;
  ended_at: string | null;
  created_at: string;
  updated_at: string;
  move_count: number | null;
}

export interface PracticeSessionDetail {
  session: PracticeSessionSummary;
  moves: PracticeGameMove[];
}

export function practiceSessionFromApi(row: Record<string, unknown>): PracticeSessionSummary {
  const mode = row['mode'] === 'freePlay' || row['mode'] === 'free_play' ? 'freePlay' : 'vsComputer';
  return {
    id: Number(row['id']),
    mode,
    level: (row['level'] as ComputerLevel) ?? null,
    player_color: (row['player_color'] as PlayerColor) ?? 'white',
    time_control_minutes: Number(row['time_control_minutes'] ?? 10) as GameTimeControl,
    start_fen: String(row['start_fen'] ?? ''),
    result: (row['result'] as PracticeSessionResult) ?? 'ended',
    ended_at: row['ended_at'] != null ? String(row['ended_at']) : null,
    created_at: String(row['created_at'] ?? ''),
    updated_at: String(row['updated_at'] ?? ''),
    move_count: row['move_count'] != null ? Number(row['move_count']) : null
  };
}

export function practiceMoveFromApi(row: Record<string, unknown>): PracticeGameMove {
  return {
    ply: Number(row['ply']),
    san: String(row['san']),
    uci: String(row['uci']),
    color: row['color'] === 'b' ? 'b' : 'w',
    player: row['player'] === 'opponent' ? 'opponent' : 'human',
    fenAfter: String(row['fen_after'] ?? row['fenAfter'] ?? '')
  };
}

export function formatPracticeSessionLabel(s: PracticeSessionSummary): string {
  const d = new Date(s.created_at);
  const date = d.toLocaleDateString(undefined, { month: 'short', day: 'numeric', year: 'numeric' });
  const mode = s.mode === 'vsComputer' ? 'Vs Stockfish' : 'Free play';
  const moves = s.move_count ?? 0;
  return `${date} · ${mode} · ${moves} move${moves === 1 ? '' : 's'}`;
}
