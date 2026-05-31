import { Component, computed, inject, OnDestroy, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpErrorResponse } from '@angular/common/http';
import { Chess, Color, Move, Square } from 'chess.js';
import { CardComponent } from 'src/app/theme/shared/components/card/card.component';
import { ChessBoardComponent } from 'src/app/theme/shared/components/chess-board/chess-board.component';
import { PuzzleService } from 'src/app/core/services/puzzle.service';
import { AuthService } from 'src/app/core/services/auth.service';
import {
  ChessPuzzle,
  parseSolutionUci,
  PUZZLE_DIFFICULTIES,
  PuzzleDifficulty
} from 'src/app/core/models/puzzle.model';
import { BoardPlayerBar } from 'src/app/core/models/chess-practice.model';
import { getApiErrorMessage } from 'src/app/core/utils/http-error.util';

type PuzzleStatus = 'idle' | 'loading' | 'playing' | 'wrong' | 'solved' | 'error';

@Component({
  selector: 'app-puzzle-play',
  imports: [CommonModule, CardComponent, ChessBoardComponent],
  templateUrl: './puzzle-play.component.html',
  styleUrl: './puzzle-play.component.scss'
})
export class PuzzlePlayComponent implements OnInit, OnDestroy {
  private readonly puzzles = inject(PuzzleService);
  readonly auth = inject(AuthService);
  readonly isStudent = computed(() => this.auth.hasRole(['student']));

  readonly difficulties = PUZZLE_DIFFICULTIES;

  level = signal<PuzzleDifficulty>('easy');
  status = signal<PuzzleStatus>('idle');
  puzzle = signal<ChessPuzzle | null>(null);
  error = signal('');
  message = signal('Choose a level and tap Load puzzle.');
  solvedCount = signal(0);

  fen = signal('');
  selectedSquare = signal<string | null>(null);
  legalTargets = signal<string[]>([]);
  boardFlipped = signal(false);

  private game = new Chess();
  private solution: string[] = [];
  private solutionIndex = 0;
  private playerColor: Color = 'w';

  ngOnInit(): void {
    this.loadPuzzle();
  }

  ngOnDestroy(): void {}

  setLevel(level: PuzzleDifficulty): void {
    if (this.level() === level) return;
    this.level.set(level);
  }

  loadPuzzle(forceNew = false): void {
    this.status.set('loading');
    this.error.set('');
    const excludeId = forceNew ? this.puzzle()?.id : undefined;

    this.puzzles.next(this.level(), excludeId).subscribe({
      next: (res) => {
        this.startPuzzle(res.data.puzzle);
      },
      error: (err: HttpErrorResponse) => {
        this.status.set('error');
        this.error.set(getApiErrorMessage(err, 'No puzzles available'));
      }
    });
  }

  private startPuzzle(p: ChessPuzzle): void {
    this.puzzle.set(p);
    this.solution = parseSolutionUci(p.solution_moves);
    this.solutionIndex = 0;
    this.game = new Chess(p.fen);
    this.fen.set(this.game.fen());
    this.playerColor = this.game.turn();
    this.boardFlipped.set(this.playerColor === 'b');
    this.selectedSquare.set(null);
    this.legalTargets.set([]);
    this.status.set('playing');
    this.message.set(
      this.playerColor === 'w'
        ? 'White to move. Find the best continuation.'
        : 'Black to move. Find the best continuation.'
    );
  }

  onSquareTap(square: string): void {
    if (this.status() !== 'playing') return;

    const selected = this.selectedSquare();
    if (!selected) {
      this.selectSquare(square);
      return;
    }
    if (selected === square) {
      this.selectedSquare.set(null);
      this.legalTargets.set([]);
      return;
    }
    if (this.legalTargets().includes(square)) {
      this.tryMove(selected, square);
      return;
    }
    this.selectSquare(square);
  }

  private selectSquare(square: string): void {
    const piece = this.game.get(square as Square);
    if (!piece || piece.color !== this.game.turn()) {
      this.selectedSquare.set(null);
      this.legalTargets.set([]);
      return;
    }
    this.selectedSquare.set(square);
    const moves = this.game.moves({ square: square as Square, verbose: true }) as Move[];
    this.legalTargets.set(moves.map((m) => m.to));
  }

  private tryMove(from: string, to: string): void {
    const uci = this.toUci(from, to);
    const expected = this.solution[this.solutionIndex];
    if (!expected || !this.uciMatches(expected, uci)) {
      this.status.set('wrong');
      this.message.set('Not the best move. Reset and try again!');
      this.selectedSquare.set(null);
      this.legalTargets.set([]);
      return;
    }

    this.game.move({ from: from as Square, to: to as Square, promotion: 'q' });
    this.fen.set(this.game.fen());
    this.solutionIndex++;
    this.selectedSquare.set(null);
    this.legalTargets.set([]);

    if (this.solutionIndex >= this.solution.length) {
      this.onSolved();
      return;
    }

    this.autoPlayReplies();
    this.message.set('Good! Keep going…');
  }

  private autoPlayReplies(): void {
    while (this.solutionIndex < this.solution.length && this.game.turn() !== this.playerColor) {
      this.applyUci(this.solution[this.solutionIndex]);
      this.solutionIndex++;
      if (this.solutionIndex >= this.solution.length) {
        this.onSolved();
        return;
      }
    }
    this.fen.set(this.game.fen());
  }

  private applyUci(uci: string): void {
    if (uci.length < 4) return;
    const from = uci.slice(0, 2);
    const to = uci.slice(2, 4);
    const promo = uci.length > 4 ? uci[4] : 'q';
    this.game.move({
      from: from as Square,
      to: to as Square,
      promotion: promo as 'q'
    });
  }

  private onSolved(): void {
    this.status.set('solved');
    this.solvedCount.update((n) => n + 1);
    this.message.set('Excellent! Puzzle solved.');
    this.fen.set(this.game.fen());

    const p = this.puzzle();
    if (p && this.auth.hasRole(['student'])) {
      this.puzzles.attempt(p.id, true).subscribe({ error: () => {} });
    }
  }

  resetPuzzle(): void {
    const p = this.puzzle();
    if (p) this.startPuzzle(p);
  }

  topPlayer(): BoardPlayerBar {
    return {
      name: 'Puzzle',
      subtitle: 'Find the best move',
      avatarLabel: '?',
      timerText: '—',
      isActive: false,
      isLowTime: false
    };
  }

  bottomPlayer(): BoardPlayerBar {
    const name = this.auth.user()?.first_name || this.auth.user()?.email || 'You';
    return {
      name,
      subtitle: this.game.turn() === 'w' ? 'White to move' : 'Black to move',
      avatarLabel: name.charAt(0),
      timerText: '—',
      isActive: this.status() === 'playing',
      isLowTime: false
    };
  }

  private toUci(from: string, to: string): string {
    const moves = this.game.moves({ verbose: true }) as Move[];
    for (const m of moves) {
      if (m.from === from && m.to === to) {
        if (m.flags?.includes('p')) return `${from}${to}q`;
        return `${from}${to}`;
      }
    }
    return `${from}${to}`;
  }

  private uciMatches(expected: string, played: string): boolean {
    if (expected === played) return true;
    return expected.slice(0, 4) === played.slice(0, 4);
  }
}
