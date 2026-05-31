import { Component, computed, inject, OnDestroy, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, RouterLink } from '@angular/router';
import { Chess, Move, Square } from 'chess.js';
import { CardComponent } from 'src/app/theme/shared/components/card/card.component';
import { ChessBoardComponent } from 'src/app/theme/shared/components/chess-board/chess-board.component';
import { ChessArenaService } from 'src/app/core/services/chess-arena.service';
import { LiveMatchVoiceService } from 'src/app/core/services/live-match-voice.service';
import { LiveMatchState } from 'src/app/core/models/chess-arena.model';
import { BoardPlayerBar } from 'src/app/core/models/chess-practice.model';

@Component({
  selector: 'app-live-match',
  imports: [CommonModule, CardComponent, ChessBoardComponent, RouterLink],
  templateUrl: './live-match.component.html',
  styleUrl: './live-match.component.scss'
})
export class LiveMatchComponent implements OnInit, OnDestroy {
  private readonly route = inject(ActivatedRoute);
  private readonly arena = inject(ChessArenaService);
  readonly voice = inject(LiveMatchVoiceService);

  loading = signal(true);
  voiceJoining = signal(false);
  error = signal('');
  state = signal<LiveMatchState | null>(null);
  fen = signal('');
  selectedSquare = signal<string | null>(null);
  legalTargets = signal<string[]>([]);
  submitting = signal(false);

  private game = new Chess();
  private matchId = 0;
  private lastPly = 0;
  private lastEventSeq = 0;
  private pollTimer: ReturnType<typeof setInterval> | null = null;

  readonly flipped = computed(() => this.state()?.your_color === 'black');

  readonly canUseVoice = computed(() => this.state()?.match.status === 'active');

  readonly boardDisabled = computed(() => {
    const s = this.state();
    if (!s || s.match.status !== 'active') return true;
    return !s.is_your_turn || this.submitting();
  });

  readonly topPlayer = computed((): BoardPlayerBar | null => {
    const s = this.state();
    if (!s) return null;
    const isYouBlack = s.your_color === 'black';
    const ms = isYouBlack ? s.white_ms_remaining : s.black_ms_remaining;
    return {
      name: isYouBlack ? s.match.white_name : s.match.black_name,
      avatarLabel: 'O',
      timerText: this.formatMs(ms),
      isActive: s.match.status === 'active' && !s.is_your_turn,
      isLowTime: ms <= 20_000
    };
  });

  readonly bottomPlayer = computed((): BoardPlayerBar | null => {
    const s = this.state();
    if (!s) return null;
    const isYouBlack = s.your_color === 'black';
    const ms = isYouBlack ? s.black_ms_remaining : s.white_ms_remaining;
    return {
      name: isYouBlack ? s.match.black_name : s.match.white_name,
      subtitle: 'You',
      avatarLabel: 'Y',
      timerText: this.formatMs(ms),
      isActive: s.match.status === 'active' && s.is_your_turn,
      isLowTime: ms <= 20_000
    };
  });

  readonly statusLine = computed(() => {
    const s = this.state();
    if (!s) return '';
    if (s.match.status === 'completed') {
      return `Game over — ${s.match.result}`;
    }
    if (s.match.status === 'waiting') {
      return 'Waiting for opponent…';
    }
    return s.is_your_turn ? 'Your turn' : "Opponent's turn";
  });

  ngOnInit(): void {
    const id = Number(this.route.snapshot.paramMap.get('id'));
    if (!id) {
      this.error.set('Invalid match');
      this.loading.set(false);
      return;
    }
    this.matchId = id;
    this.load(true);
    this.syncFromServer();
    this.pollTimer = setInterval(() => this.syncFromServer(), 400);
  }

  ngOnDestroy(): void {
    this.voice.leave();
    if (this.pollTimer) {
      clearInterval(this.pollTimer);
      this.pollTimer = null;
    }
  }

  async toggleVoice(remoteAudio: HTMLAudioElement): Promise<void> {
    const s = this.state();
    if (!s || !this.canUseVoice()) return;

    if (this.voice.active()) {
      this.voice.leave();
      return;
    }

    if (this.voiceJoining()) return;

    remoteAudio.volume = 1;
    remoteAudio.muted = false;
    try {
      await remoteAudio.play();
    } catch {
      /* unlock on user click */
    }

    this.voiceJoining.set(true);
    try {
      await this.voice.join(this.matchId, s, remoteAudio);
      void remoteAudio.play().catch(() => undefined);
    } finally {
      this.voiceJoining.set(false);
    }
  }

  toggleMute(): void {
    this.voice.toggleMute();
  }

  private syncFromServer(): void {
    if (this.submitting()) return;
    this.arena.getRevision(this.matchId, this.lastEventSeq).subscribe({
      next: (rev) => {
        if (!rev.changed) return;
        if (rev.state) {
          this.applyState(rev.state);
          return;
        }
        this.arena.getMatch(this.matchId).subscribe({
          next: (st) => this.applyState(st),
          error: () => undefined
        });
      },
      error: () => undefined
    });
  }

  resign(): void {
    if (!confirm('Resign this game?')) return;
    this.arena.resign(this.matchId).subscribe({
      next: (st) => this.applyState(st),
      error: () => this.error.set('Could not resign')
    });
  }

  onSquareTap(square: string): void {
    if (this.boardDisabled()) return;

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
      this.playLocalMove(selected, square);
      return;
    }
    this.selectSquare(square);
  }

  private load(showSpinner: boolean): void {
    if (showSpinner) this.loading.set(true);
    this.arena.getMatch(this.matchId).subscribe({
      next: (st) => {
        this.applyState(st);
        this.loading.set(false);
      },
      error: () => {
        this.error.set('Could not load match');
        this.loading.set(false);
      }
    });
  }

  private applyState(st: LiveMatchState): void {
    if (st.event_seq != null) {
      this.lastEventSeq = st.event_seq;
    }
    this.state.set(st);
    const ply = st.moves.length;
    if (ply !== this.lastPly) {
      this.lastPly = ply;
      try {
        this.game = new Chess(st.match.current_fen);
        this.fen.set(st.match.current_fen);
      } catch {
        this.game = new Chess();
        this.fen.set(this.game.fen());
      }
    }
    this.selectedSquare.set(null);
    this.legalTargets.set([]);
  }

  private selectSquare(square: string): void {
    const s = this.state();
    if (!s) return;
    const yourColor = s.your_color === 'white' ? 'w' : 'b';
    const piece = this.game.get(square as Square);
    if (!piece || piece.color !== yourColor || this.game.turn() !== yourColor) {
      this.selectedSquare.set(null);
      this.legalTargets.set([]);
      return;
    }
    this.selectedSquare.set(square);
    const moves = this.game.moves({ square: square as Square, verbose: true }) as Move[];
    this.legalTargets.set(moves.map((m) => m.to));
  }

  private playLocalMove(from: string, to: string): void {
    const result = this.game.move({
      from: from as Square,
      to: to as Square,
      promotion: 'q'
    });
    if (!result) return;

    this.submitting.set(true);
    this.selectedSquare.set(null);
    this.legalTargets.set([]);

    this.arena
      .playMove(this.matchId, {
        uci: `${from}${to}${result.promotion ?? ''}`,
        san: result.san,
        fen_after: this.game.fen()
      })
      .subscribe({
        next: (st) => {
          this.applyState(st);
          this.submitting.set(false);
        },
        error: () => {
          this.submitting.set(false);
          this.error.set('Move rejected — syncing board…');
          this.load(false);
        }
      });
  }

  private formatMs(ms: number): string {
    const total = Math.max(0, Math.floor(ms / 1000));
    const m = Math.floor(total / 60);
    const s = total % 60;
    return `${m}:${s.toString().padStart(2, '0')}`;
  }
}
