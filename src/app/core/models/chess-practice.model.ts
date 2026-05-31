export type PracticeMode = 'freePlay' | 'vsComputer';

export type PlayerColor = 'white' | 'black';

export type ComputerLevel = 'beginner' | 'intermediate' | 'advanced';

export type GameTimeControl = 5 | 10 | 15;

export const COMPUTER_LEVELS: { value: ComputerLevel; label: string; description: string }[] = [
  { value: 'beginner', label: 'Beginner', description: 'Stockfish ~1000 Elo' },
  { value: 'intermediate', label: 'Intermediate', description: 'Stockfish ~1600 Elo' },
  { value: 'advanced', label: 'Advanced', description: 'Full-strength Stockfish' }
];

export const TIME_CONTROLS: { value: GameTimeControl; label: string }[] = [
  { value: 5, label: '5 min' },
  { value: 10, label: '10 min' },
  { value: 15, label: '15 min' }
];

export interface ChessMove {
  from: string;
  to: string;
  promotion?: string;
}

export interface BoardPlayerBar {
  name: string;
  subtitle?: string;
  avatarLabel?: string;
  timerText: string;
  isActive: boolean;
  isLowTime: boolean;
}

/** One half-move stored for practice game review (session). */
export interface PracticeGameMove {
  /** 1-based ply (half-move index). */
  ply: number;
  san: string;
  uci: string;
  color: 'w' | 'b';
  player: 'human' | 'opponent';
  fenAfter: string;
}
