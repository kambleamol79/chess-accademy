import { PracticeGameMove } from '../models/chess-practice.model';

/** Full-move number shown beside white's SAN (1, 2, 3…). */
export function practiceMoveNumber(entry: PracticeGameMove): number {
  return entry.color === 'w' ? Math.ceil(entry.ply / 2) : Math.floor(entry.ply / 2);
}

export function practiceMovePlayerLabel(entry: PracticeGameMove, opponentName: string): string {
  return entry.player === 'human' ? 'You' : opponentName;
}
