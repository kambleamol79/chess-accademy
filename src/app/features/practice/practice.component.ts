import { Component, computed, inject, OnDestroy, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { NgbDropdownModule } from '@ng-bootstrap/ng-bootstrap';
import { Chess, Color, Move, Square } from 'chess.js';
import { CardComponent } from 'src/app/theme/shared/components/card/card.component';
import { ChessBoardComponent } from 'src/app/theme/shared/components/chess-board/chess-board.component';
import { AuthService } from 'src/app/core/services/auth.service';
import { applyMove, humanColorToChess } from 'src/app/core/services/chess-engine.service';
import { PracticeSessionService } from 'src/app/core/services/practice-session.service';
import { StockfishEngineService } from 'src/app/core/services/stockfish-engine.service';
import {
  formatPracticeSessionLabel,
  PracticeSessionResult,
  PracticeSessionSummary
} from 'src/app/core/models/practice-session.model';
import {
  BoardPlayerBar,
  COMPUTER_LEVELS,
  ComputerLevel,
  GameTimeControl,
  PlayerColor,
  PracticeGameMove,
  PracticeMode,
  TIME_CONTROLS
} from 'src/app/core/models/chess-practice.model';
import { practiceMoveNumber, practiceMovePlayerLabel } from 'src/app/core/utils/chess-history.util';

export type PracticeTab = 'board' | 'saved';

@Component({
  selector: 'app-practice',
  imports: [CommonModule, NgbDropdownModule, CardComponent, ChessBoardComponent],
  templateUrl: './practice.component.html',
  styleUrl: './practice.component.scss'
})
export class PracticeComponent implements OnInit, OnDestroy {
  private readonly engine = inject(StockfishEngineService);
  private readonly sessionApi = inject(PracticeSessionService);
  readonly auth = inject(AuthService);
  readonly isStudent = computed(() => this.auth.hasRole(['student']));
  readonly settingsSummary = computed(() => {
    const parts = [
      this.mode() === 'vsComputer' ? 'Vs Stockfish' : 'Free play',
      `${this.timeControl()} min`
    ];
    if (this.mode() === 'vsComputer') {
      const level = COMPUTER_LEVELS.find((l) => l.value === this.level());
      parts.push(level?.label ?? this.level());
      parts.push(this.playerColor() === 'white' ? 'White' : 'Black');
    }
    return parts.join(' · ');
  });

  readonly savedSessions = signal<PracticeSessionSummary[]>([]);
  readonly loadingSavedSessions = signal(false);
  readonly viewingSavedSessionId = signal<number | null>(null);
  readonly isViewingSavedSession = computed(() => this.viewingSavedSessionId() !== null);
  readonly formatSessionLabel = formatPracticeSessionLabel;

  practiceTab = signal<PracticeTab>('board');

  private dbSessionId: number | null = null;
  private pendingDbMoves: PracticeGameMove[] = [];

  readonly opponentName = this.engine.engineLabel;

  readonly computerLevels = COMPUTER_LEVELS;
  readonly timeControls = TIME_CONTROLS;

  mode = signal<PracticeMode>('vsComputer');
  level = signal<ComputerLevel>('beginner');
  playerColor = signal<PlayerColor>('white');
  timeControl = signal<GameTimeControl>(10);

  gameActive = signal(false);
  aiThinking = signal(false);
  statusMessage = signal('Choose settings and tap Start Game.');
  fen = signal('');
  selectedSquare = signal<string | null>(null);
  legalTargets = signal<string[]>([]);
  /** FEN after each ply: [start, after move 1, …]. */
  positionFens = signal<string[]>([]);
  gameHistory = signal<PracticeGameMove[]>([]);
  /** null = live game; 0 = start; n = position after ply n. */
  replayIndex = signal<number | null>(null);
  /** Bumps each clock tick so timer labels refresh. */
  clockTick = signal(0);

  readonly displayFen = computed(() => {
    const idx = this.replayIndex();
    if (idx === null) return this.fen();
    const fens = this.positionFens();
    return fens[idx] ?? this.fen();
  });

  readonly isReplayMode = computed(() => this.replayIndex() !== null);

  readonly canReplayPrevious = computed(() => {
    const idx = this.replayIndex();
    return idx !== null && idx > 0;
  });

  readonly canReplayNext = computed(() => {
    const idx = this.replayIndex();
    if (idx === null) return false;
    return idx < this.positionFens().length - 1;
  });

  readonly replayCaption = computed(() => {
    const idx = this.replayIndex();
    if (idx === null) return '';
    if (idx === 0) return 'Start position';
    const entry = this.gameHistory()[idx - 1];
    return entry ? `After ${idx}. ${entry.san}` : `Position ${idx}`;
  });

  readonly moveNumberFor = practiceMoveNumber;
  readonly movePlayerLabel = (entry: PracticeGameMove) =>
    practiceMovePlayerLabel(entry, this.opponentName());

  private game = new Chess();
  private whiteMs = 10 * 60 * 1000;
  private blackMs = 10 * 60 * 1000;
  private clockSide: Color | null = null;
  private clockSince: number | null = null;
  private clockInterval: ReturnType<typeof setInterval> | null = null;
  private flaggedOnTime = false;
  private timeWinner: Color | null = null;

  ngOnInit(): void {
    void this.engine.ensureReady();
    this.initPositionTrail();
    this.loadSavedSessions();
  }

  ngOnDestroy(): void {
    this.finalizeCurrentSession('ended');
    this.stopClockInterval();
    this.engine.dispose();
  }

  loadSavedSessions(): void {
    this.loadingSavedSessions.set(true);
    this.sessionApi.list(40).subscribe({
      next: (sessions) => {
        this.savedSessions.set(sessions);
        this.loadingSavedSessions.set(false);
      },
      error: () => this.loadingSavedSessions.set(false)
    });
  }

  setPracticeTab(tab: PracticeTab): void {
    this.practiceTab.set(tab);
  }

  openSavedSession(id: number): void {
    this.sessionApi.get(id).subscribe({
      next: (detail) => {
        this.clearLiveReview();
        this.viewingSavedSessionId.set(id);
        this.gameActive.set(false);
        this.gameHistory.set(detail.moves);
        this.positionFens.set([
          detail.session.start_fen,
          ...detail.moves.map((m) => m.fenAfter)
        ]);
        this.replayIndex.set(detail.moves.length);
        this.fen.set(detail.moves.length > 0 ? detail.moves[detail.moves.length - 1].fenAfter : detail.session.start_fen);
        this.statusMessage.set(`Saved game · ${formatPracticeSessionLabel(detail.session)}`);
        this.practiceTab.set('board');
      }
    });
  }

  exitSavedSessionView(): void {
    this.viewingSavedSessionId.set(null);
    this.clearLiveReview();
    this.initPositionTrail();
    this.fen.set(this.game.fen());
    this.updateStatus();
    this.practiceTab.set('board');
  }

  isVsComputer(): boolean {
    return this.mode() === 'vsComputer';
  }

  boardFlipped(): boolean {
    return this.isVsComputer() && this.playerColor() === 'black';
  }

  isGameOver(): boolean {
    return this.game.isGameOver() || this.flaggedOnTime;
  }

  canStartGame(): boolean {
    return this.isVsComputer() && !this.gameActive() && !this.aiThinking();
  }

  canEndGame(): boolean {
    return this.gameActive();
  }

  setMode(mode: PracticeMode): void {
    if (this.mode() === mode || this.gameActive()) return;
    this.mode.set(mode);
    this.resetBoard();
  }

  setLevel(level: ComputerLevel): void {
    this.level.set(level);
  }

  setPlayerColor(color: PlayerColor): void {
    if (this.playerColor() === color) return;
    this.playerColor.set(color);
    this.resetBoard();
  }

  setTimeControl(minutes: GameTimeControl): void {
    if (this.gameActive()) return;
    this.timeControl.set(minutes);
    this.resetClocks();
  }

  resetBoard(): void {
    this.finalizeCurrentSession('ended');
    this.viewingSavedSessionId.set(null);
    this.stopClock();
    this.game = new Chess();
    this.flaggedOnTime = false;
    this.timeWinner = null;
    this.fen.set(this.game.fen());
    this.selectedSquare.set(null);
    this.legalTargets.set([]);
    this.initPositionTrail();
    this.aiThinking.set(false);
    this.gameActive.set(this.mode() === 'freePlay');
    this.resetClocks();
    this.updateStatus();

    if (this.gameActive()) {
      this.startDbSession(() => {
        this.syncClock();
        if (this.isVsComputer() && this.game.turn() !== this.humanChessColor()) {
          void this.scheduleComputerMove();
        }
      });
    }
  }

  endGame(): void {
    if (!this.canEndGame()) return;
    this.finalizeCurrentSession('ended');
    this.stopClock();
    this.gameActive.set(false);
    this.aiThinking.set(false);
    this.returnToLive();
    this.selectedSquare.set(null);
    this.legalTargets.set([]);
    this.statusMessage.set(
      this.isVsComputer()
        ? 'Game ended. Tap Start game to play again.'
        : 'Game ended. Tap New game to play again.'
    );
  }

  startGame(): void {
    if (!this.canStartGame()) return;
    this.finalizeCurrentSession('ended');
    this.viewingSavedSessionId.set(null);
    this.game = new Chess();
    this.flaggedOnTime = false;
    this.timeWinner = null;
    this.fen.set(this.game.fen());
    this.initPositionTrail();
    this.gameActive.set(true);
    this.resetClocks();
    this.syncClock();
    this.updateStatus();

    this.startDbSession(() => {
      if (this.game.turn() !== this.humanChessColor()) {
        void this.scheduleComputerMove();
      }
    });
  }

  undoMove(): void {
    if (!this.gameActive() || this.aiThinking() || this.isReplayMode()) return;
    this.stopClock();

    if (this.isVsComputer()) {
      if (this.gameHistory().length === 0) return;
      this.game.undo();
      this.popLastRecordedMove();
      if (this.gameHistory().length > 0 && this.game.turn() !== this.humanChessColor()) {
        this.game.undo();
        this.popLastRecordedMove();
      }
    } else {
      if (!this.game.undo()) return;
      this.popLastRecordedMove();
    }

    this.flaggedOnTime = false;
    this.timeWinner = null;
    this.fen.set(this.game.fen());
    this.returnToLive();
    this.selectedSquare.set(null);
    this.legalTargets.set([]);
    if (!this.isGameOver()) this.syncClock();
    this.updateStatus();
  }

  goToReplayIndex(index: number): void {
    const max = this.positionFens().length - 1;
    const clamped = Math.max(0, Math.min(index, max));
    this.replayIndex.set(clamped);
    this.selectedSquare.set(null);
    this.legalTargets.set([]);
  }

  returnToLive(): void {
    this.replayIndex.set(null);
    this.selectedSquare.set(null);
    this.legalTargets.set([]);
  }

  replayPrevious(): void {
    const idx = this.replayIndex();
    if (idx === null) {
      this.goToReplayIndex(this.positionFens().length - 1);
      return;
    }
    if (idx > 0) this.goToReplayIndex(idx - 1);
  }

  replayNext(): void {
    const idx = this.replayIndex();
    if (idx !== null && idx < this.positionFens().length - 1) {
      this.goToReplayIndex(idx + 1);
    }
  }

  isHistoryMoveActive(ply: number): boolean {
    return this.replayIndex() === ply;
  }

  boardInteractionDisabled(): boolean {
    return (
      this.isViewingSavedSession() ||
      !this.gameActive() ||
      this.isGameOver() ||
      this.aiThinking() ||
      this.isReplayMode()
    );
  }

  onSquareTap(square: string): void {
    if (this.boardInteractionDisabled()) return;
    if (this.isVsComputer() && this.game.turn() !== this.humanChessColor()) return;

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
      this.makeMove(selected, square);
      return;
    }
    this.selectSquare(square);
  }

  private selectSquare(square: string): void {
    const piece = this.game.get(square as Square);
    if (!piece) {
      this.selectedSquare.set(null);
      this.legalTargets.set([]);
      return;
    }
    if (this.isVsComputer()) {
      if (piece.color !== this.humanChessColor() || this.game.turn() !== this.humanChessColor()) {
        this.selectedSquare.set(null);
        this.legalTargets.set([]);
        return;
      }
    } else if (piece.color !== this.game.turn()) {
      this.selectedSquare.set(null);
      this.legalTargets.set([]);
      return;
    }

    this.selectedSquare.set(square);
    const moves = this.game.moves({ square: square as Square, verbose: true }) as Move[];
    this.legalTargets.set(moves.map((m) => m.to));
  }

  private makeMove(from: string, to: string): void {
    const result = this.game.move({
      from: from as Square,
      to: to as Square,
      promotion: 'q'
    });
    if (!result) {
      this.statusMessage.set('Illegal move.');
      return;
    }

    this.fen.set(this.game.fen());
    this.recordMove(result, 'human');
    this.selectedSquare.set(null);
    this.legalTargets.set([]);
    this.afterMove();

    if (this.isVsComputer() && !this.isGameOver() && this.game.turn() !== this.humanChessColor()) {
      void this.scheduleComputerMove();
    }
  }

  private async scheduleComputerMove(): Promise<void> {
    this.aiThinking.set(true);
    this.statusMessage.set(`${this.opponentName()}'s turn…`);
    const fenSnapshot = this.game.fen();

    await new Promise((r) => setTimeout(r, 200));

    try {
      const move = await this.engine.pickMove(fenSnapshot, this.level());

      if (!this.gameActive() || this.game.fen() !== fenSnapshot) return;

      if (move && !this.game.isGameOver() && !this.flaggedOnTime) {
        if (applyMove(this.game, move)) {
          const verbose = this.game.history({ verbose: true }) as Move[];
          const last = verbose[verbose.length - 1];
          if (last) {
            this.fen.set(this.game.fen());
            this.recordMove(last, 'opponent');
            this.afterMove();
          }
        }
      }
    } finally {
      this.aiThinking.set(false);
      this.updateStatus();
    }
  }

  private afterMove(): void {
    if (this.flaggedOnTime || this.game.isGameOver()) {
      this.stopClock();
      this.finalizeCurrentSession(this.inferSessionResult());
    } else {
      this.syncClock();
    }
    this.updateStatus();
  }

  private humanChessColor(): Color {
    return humanColorToChess(this.playerColor());
  }

  private initPositionTrail(): void {
    const start = this.game.fen();
    this.positionFens.set([start]);
    this.gameHistory.set([]);
    this.replayIndex.set(null);
  }

  private recordMove(move: Move, player: 'human' | 'opponent'): void {
    const ply = this.gameHistory().length + 1;
    const entry: PracticeGameMove = {
      ply,
      san: move.san,
      uci: `${move.from}${move.to}`,
      color: move.color,
      player,
      fenAfter: this.game.fen()
    };
    this.gameHistory.update((h) => [...h, entry]);
    this.positionFens.update((f) => [...f, this.game.fen()]);
    this.returnToLive();
    this.persistMove(entry);
  }

  private popLastRecordedMove(): void {
    this.gameHistory.update((h) => (h.length ? h.slice(0, -1) : h));
    this.positionFens.update((f) => (f.length > 1 ? f.slice(0, -1) : f));
    this.persistUndo();
  }

  private clearLiveReview(): void {
    this.returnToLive();
    this.selectedSquare.set(null);
    this.legalTargets.set([]);
  }

  private startDbSession(onReady?: () => void): void {
    this.pendingDbMoves = [];
    this.sessionApi
      .create({
        mode: this.mode(),
        level: this.isVsComputer() ? this.level() : undefined,
        playerColor: this.playerColor(),
        timeControlMinutes: this.timeControl(),
        startFen: this.game.fen()
      })
      .subscribe({
        next: (session) => {
          this.dbSessionId = session.id;
          const pending = [...this.pendingDbMoves];
          this.pendingDbMoves = [];
          for (const move of pending) {
            this.persistMove(move);
          }
          onReady?.();
        },
        error: () => {
          this.dbSessionId = null;
          this.pendingDbMoves = [];
          onReady?.();
        }
      });
  }

  private finalizeCurrentSession(result: PracticeSessionResult): void {
    const id = this.dbSessionId;
    if (id == null) return;
    this.dbSessionId = null;
    this.sessionApi.finalize(id, result).subscribe({
      next: () => this.loadSavedSessions(),
      error: () => {}
    });
  }

  private persistMove(entry: PracticeGameMove): void {
    const id = this.dbSessionId;
    if (id == null) {
      this.pendingDbMoves.push(entry);
      return;
    }
    this.sessionApi.addMove(id, entry).subscribe({ error: () => {} });
  }

  private persistUndo(): void {
    const id = this.dbSessionId;
    if (id == null) return;
    this.sessionApi.deleteLastMove(id).subscribe({ error: () => {} });
  }

  private inferSessionResult(): PracticeSessionResult {
    if (this.flaggedOnTime && this.timeWinner) {
      return this.timeWinner === this.humanChessColor() ? 'timeout_win' : 'timeout_loss';
    }
    if (this.game.isDraw() || this.game.isStalemate()) {
      return 'draw';
    }
    if (this.game.isCheckmate() && this.isVsComputer()) {
      const youWin =
        (this.game.turn() === 'w' && this.playerColor() === 'black') ||
        (this.game.turn() === 'b' && this.playerColor() === 'white');
      return youWin ? 'win' : 'loss';
    }
    return 'ended';
  }

  private resetClocks(): void {
    const ms = this.timeControl() * 60 * 1000;
    this.whiteMs = ms;
    this.blackMs = ms;
  }

  private syncClock(): void {
    if (!this.gameActive() || this.isGameOver()) {
      this.stopClock();
      return;
    }
    this.startClockFor(this.game.turn());
  }

  private startClockFor(side: Color): void {
    this.stopClock();
    this.clockSide = side;
    this.clockSince = Date.now();
    if (!this.clockInterval) {
      this.clockInterval = setInterval(() => this.onClockTick(), 200);
    }
  }

  private stopClock(): void {
    if (this.clockSide && this.clockSince != null) {
      const elapsed = Date.now() - this.clockSince;
      if (this.clockSide === 'w') this.whiteMs = Math.max(0, this.whiteMs - elapsed);
      else this.blackMs = Math.max(0, this.blackMs - elapsed);
      this.checkTimeForfeit();
    }
    this.clockSide = null;
    this.clockSince = null;
  }

  private stopClockInterval(): void {
    this.stopClock();
    if (this.clockInterval) {
      clearInterval(this.clockInterval);
      this.clockInterval = null;
    }
  }

  private onClockTick(): void {
    if (!this.gameActive() || this.isGameOver() || !this.clockSide) return;
    const remaining = this.remainingMs(this.clockSide);
    if (remaining <= 0) {
      this.onTimeForfeit(this.clockSide === 'w' ? 'b' : 'w');
      return;
    }
    this.clockTick.update((n) => n + 1);
  }

  private checkTimeForfeit(): void {
    if (this.whiteMs <= 0) this.onTimeForfeit('b');
    else if (this.blackMs <= 0) this.onTimeForfeit('w');
  }

  private onTimeForfeit(winner: Color): void {
    this.stopClockInterval();
    this.flaggedOnTime = true;
    this.timeWinner = winner;
    this.updateStatus();
  }

  private remainingMs(side: Color): number {
    const base = side === 'w' ? this.whiteMs : this.blackMs;
    if (this.clockSide !== side || this.clockSince == null) return base;
    return Math.max(0, base - (Date.now() - this.clockSince));
  }

  private formatMs(ms: number): string {
    const totalSec = Math.max(0, Math.ceil(ms / 1000));
    const m = Math.floor(totalSec / 60);
    const s = totalSec % 60;
    return `${m}:${s.toString().padStart(2, '0')}`;
  }

  private displayMsForBar(bottom: boolean): number {
    const bottomIsWhite = !this.boardFlipped();
    const side: Color = bottom === bottomIsWhite ? 'w' : 'b';
    return this.remainingMs(side);
  }

  private isBarActive(bottom: boolean): boolean {
    if (this.isReplayMode() || !this.gameActive() || this.isGameOver() || !this.clockSide) return false;
    const bottomIsWhite = !this.boardFlipped();
    const side: Color = bottom === bottomIsWhite ? 'w' : 'b';
    return this.clockSide === side;
  }

  topPlayer(): BoardPlayerBar {
    const name = this.isVsComputer() ? this.opponentName() : 'Opponent';
    const ms = this.displayMsForBar(false);
    return {
      name,
      subtitle: this.isVsComputer() ? this.level() : 'Free play',
      avatarLabel: 'S',
      timerText: this.gameActive() ? this.formatMs(ms) : `${this.timeControl()}:00`,
      isActive: this.isBarActive(false),
      isLowTime: ms <= 20000
    };
  }

  bottomPlayer(): BoardPlayerBar {
    const user = this.auth.user();
    const name = user?.first_name || user?.email || 'You';
    const ms = this.displayMsForBar(true);
    return {
      name,
      subtitle: this.playerColor() === 'white' ? 'White' : 'Black',
      avatarLabel: name.charAt(0).toUpperCase(),
      timerText: this.gameActive() ? this.formatMs(ms) : `${this.timeControl()}:00`,
      isActive: this.isBarActive(true),
      isLowTime: ms <= 20000
    };
  }

  private updateStatus(): void {
    if (this.aiThinking()) return;

    if (this.flaggedOnTime && this.timeWinner) {
      const youWin = this.timeWinner === this.humanChessColor();
      this.statusMessage.set(
        youWin ? 'Time! You win on the clock.' : `Time! ${this.opponentName()} wins on the clock.`
      );
      return;
    }

    if (!this.gameActive()) {
      this.statusMessage.set(
        this.isVsComputer()
          ? `Tap Start Game — ${this.level()} · ${this.timeControl()} min.`
          : `Free play — ${this.timeControl()} min per side.`
      );
      return;
    }

    if (this.game.isCheckmate()) {
      const youWin =
        (this.game.turn() === 'w' && this.playerColor() === 'black') ||
        (this.game.turn() === 'b' && this.playerColor() === 'white');
      this.statusMessage.set(
        this.isVsComputer()
          ? youWin
            ? 'Checkmate! You win!'
            : `Checkmate! ${this.opponentName()} wins.`
          : `Checkmate! ${this.game.turn() === 'w' ? 'Black' : 'White'} wins.`
      );
    } else if (this.game.isDraw() || this.game.isStalemate()) {
      this.statusMessage.set('Draw.');
    } else if (this.game.inCheck()) {
      this.statusMessage.set(
        this.isVsComputer() && this.game.turn() === this.humanChessColor()
          ? 'Check! Your move.'
          : 'Check!'
      );
    } else if (this.isVsComputer()) {
      this.statusMessage.set(
        this.game.turn() === this.humanChessColor()
          ? `Your move (${this.playerColor()}).`
          : `${this.opponentName()}'s turn.`
      );
    } else {
      this.statusMessage.set(this.game.turn() === 'w' ? 'White to move.' : 'Black to move.');
    }
  }
}
