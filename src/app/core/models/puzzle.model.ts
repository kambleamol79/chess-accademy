export type PuzzleDifficulty = 'easy' | 'medium' | 'hard';

export const PUZZLE_DIFFICULTIES: { value: PuzzleDifficulty; label: string }[] = [
  { value: 'easy', label: 'Easy' },
  { value: 'medium', label: 'Medium' },
  { value: 'hard', label: 'Hard' }
];

export interface ChessPuzzle {
  id: number;
  fen: string;
  solution_moves: string;
  difficulty: PuzzleDifficulty;
  title?: string | null;
}

export function parseSolutionUci(solutionMoves: string): string[] {
  return solutionMoves
    .trim()
    .split(/\s+/)
    .filter(Boolean)
    .map((m) => m.toLowerCase());
}

export function puzzleFromApi(row: Record<string, unknown>): ChessPuzzle {
  return {
    id: Number(row['id']),
    fen: String(row['fen'] ?? ''),
    solution_moves: String(row['solution_moves'] ?? ''),
    difficulty: (row['difficulty'] as PuzzleDifficulty) ?? 'medium',
    title: row['title'] != null ? String(row['title']) : null
  };
}
