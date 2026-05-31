import { Injectable } from '@angular/core';
import { Chess, Color, Move, Square } from 'chess.js';
import { ChessMove, ComputerLevel } from '../models/chess-practice.model';

@Injectable({ providedIn: 'root' })
export class ChessEngineService {
  pickMove(game: Chess, level: ComputerLevel): ChessMove | null {
    const verbose = game.moves({ verbose: true }) as Move[];
    if (verbose.length === 0) return null;

    if (level === 'beginner') {
      return this.beginnerMove(verbose, game);
    }

    const depth = level === 'intermediate' ? 2 : 3;
    return this.bestMove(game, depth);
  }

  private beginnerMove(moves: Move[], game: Chess): ChessMove {
    const captures = moves.filter((m) => m.captured);
    if (captures.length > 0 && Math.random() < 0.45) {
      const pick = captures[Math.floor(Math.random() * captures.length)];
      return { from: pick.from, to: pick.to, promotion: pick.promotion };
    }
    const pick = moves[Math.floor(Math.random() * moves.length)];
    return { from: pick.from, to: pick.to, promotion: pick.promotion };
  }

  private bestMove(game: Chess, depth: number): ChessMove | null {
    const moves = game.moves({ verbose: true }) as Move[];
    if (moves.length === 0) return null;

    let best: Move | null = null;
    let bestScore = -999999;

    for (const move of moves) {
      const clone = new Chess(game.fen());
      clone.move(move);
      const score = -this.negamax(clone, depth - 1, -999999, 999999);
      if (score > bestScore) {
        bestScore = score;
        best = move;
      }
    }

    if (!best) return null;
    return { from: best.from, to: best.to, promotion: best.promotion };
  }

  private negamax(game: Chess, depth: number, alpha: number, beta: number): number {
    if (depth === 0 || game.isGameOver()) {
      return this.evaluate(game);
    }

    const moves = game.moves({ verbose: true }) as Move[];
    if (moves.length === 0) {
      if (game.isCheckmate()) {
        return -99999 + (10 - depth);
      }
      return 0;
    }

    let best = -999999;
    for (const move of moves) {
      game.move(move);
      const score = -this.negamax(game, depth - 1, -beta, -alpha);
      game.undo();
      if (score > best) best = score;
      if (score > alpha) alpha = score;
      if (alpha >= beta) break;
    }
    return best;
  }

  private evaluate(game: Chess): number {
    if (game.isCheckmate()) {
      return game.turn() === 'w' ? -99999 : 99999;
    }
    if (game.isDraw() || game.isStalemate()) {
      return 0;
    }

    const values: Record<string, number> = { p: 100, n: 320, b: 330, r: 500, q: 900, k: 20000 };
    let score = 0;
    const board = game.board();

    for (const row of board) {
      for (const piece of row) {
        if (!piece) continue;
        const v = values[piece.type] ?? 0;
        score += piece.color === 'w' ? v : -v;
      }
    }

    score += game.moves().length * 4;
    return game.turn() === 'w' ? score : -score;
  }
}

export function applyMove(game: Chess, move: ChessMove): boolean {
  const result = game.move({
    from: move.from as Square,
    to: move.to as Square,
    promotion: (move.promotion ?? 'q') as 'q' | 'r' | 'b' | 'n'
  });
  return result != null;
}

export function humanColorToChess(color: 'white' | 'black'): Color {
  return color === 'white' ? 'w' : 'b';
}
