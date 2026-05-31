import { ComputerLevel } from '../models/chess-practice.model';

export interface StockfishLevelConfig {
  elo: number;
  skill: number;
  movetimeMs: number;
  limitStrength: boolean;
}

export function stockfishLevelConfig(level: ComputerLevel): StockfishLevelConfig {
  switch (level) {
    case 'beginner':
      return { elo: 1000, skill: 3, movetimeMs: 300, limitStrength: true };
    case 'intermediate':
      return { elo: 1600, skill: 10, movetimeMs: 600, limitStrength: true };
    case 'advanced':
      return { elo: 2200, skill: 20, movetimeMs: 1200, limitStrength: false };
  }
}
