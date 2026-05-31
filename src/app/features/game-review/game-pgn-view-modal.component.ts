import { Component, inject, Input, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { NgbActiveModal } from '@ng-bootstrap/ng-bootstrap';
import { Chess } from 'chess.js';
import { ChessBoardComponent } from 'src/app/theme/shared/components/chess-board/chess-board.component';
import { ReviewGame } from 'src/app/core/models/game.model';
import { parsePgn } from 'src/app/core/utils/pgn.util';

@Component({
  selector: 'app-game-pgn-view-modal',
  imports: [CommonModule, ChessBoardComponent],
  templateUrl: './game-pgn-view-modal.component.html',
  styleUrl: './game-pgn-view-modal.component.scss'
})
export class GamePgnViewModalComponent implements OnInit {
  private readonly activeModal = inject(NgbActiveModal);

  @Input() game!: ReviewGame;

  fen = signal('');
  replayIndex = signal(0);
  positionFens = signal<string[]>([]);
  moveSans = signal<string[]>([]);
  parseError = signal('');

  ngOnInit(): void {
    const parsed = parsePgn(this.game.pgn);
    if (!parsed.valid) {
      this.parseError.set(parsed.error ?? 'Could not load PGN');
      return;
    }

    this.positionFens.set(parsed.fens);
    this.replayIndex.set(0);
    this.fen.set(parsed.fens[0] ?? '');

    const end = new Chess();
    end.loadPgn(this.game.pgn, { strict: false });
    this.moveSans.set(end.history());
  }

  dismiss(): void {
    this.activeModal.dismiss();
  }

  goToIndex(index: number): void {
    const fens = this.positionFens();
    const i = Math.max(0, Math.min(index, fens.length - 1));
    this.replayIndex.set(i);
    this.fen.set(fens[i] ?? '');
  }

  previous(): void {
    this.goToIndex(this.replayIndex() - 1);
  }

  next(): void {
    this.goToIndex(this.replayIndex() + 1);
  }

  canPrevious(): boolean {
    return this.replayIndex() > 0;
  }

  canNext(): boolean {
    return this.replayIndex() < this.positionFens().length - 1;
  }

  caption(): string {
    const i = this.replayIndex();
    if (i === 0) return 'Start position';
    const san = this.moveSans()[i - 1];
    return san ? `After ${i}. ${san}` : `After move ${i}`;
  }
}
