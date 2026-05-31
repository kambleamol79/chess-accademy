import { Component, EventEmitter, Input, OnChanges, Output } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Chess, Square } from 'chess.js';
import { BoardPlayerBar } from 'src/app/core/models/chess-practice.model';

const FILES = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
const LIGHT = '#f0debb';
const DARK = '#b58863';

@Component({
  selector: 'app-chess-board',
  imports: [CommonModule],
  templateUrl: './chess-board.component.html',
  styleUrl: './chess-board.component.scss'
})
export class ChessBoardComponent implements OnChanges {
  @Input({ required: true }) fen = '';
  @Input() flipped = false;
  @Input() selectedSquare: string | null = null;
  @Input() legalTargets: string[] = [];
  @Input() hintFrom: string | null = null;
  @Input() hintTo: string | null = null;
  @Input() disabled = false;
  @Input() topPlayer: BoardPlayerBar | null = null;
  @Input() bottomPlayer: BoardPlayerBar | null = null;

  @Output() squareClick = new EventEmitter<string>();

  readonly files = FILES;

  private _game = new Chess();

  get rows(): number[] {
    return [0, 1, 2, 3, 4, 5, 6, 7];
  }

  ngOnChanges(): void {
    try {
      this._game = new Chess(this.fen || undefined);
    } catch {
      this._game = new Chess();
    }
  }

  rankForRow(displayRow: number): number {
    const rowIndex = this.flipped ? 7 - displayRow : displayRow;
    return 8 - rowIndex;
  }

  fileForCol(displayCol: number): string {
    const colIndex = this.flipped ? 7 - displayCol : displayCol;
    return FILES[colIndex];
  }

  square(displayRow: number, displayCol: number): string {
    return `${this.fileForCol(displayCol)}${this.rankForRow(displayRow)}`;
  }

  isLight(displayRow: number, displayCol: number): boolean {
    const rank = this.rankForRow(displayRow);
    const fileIndex = this.flipped ? 7 - displayCol : displayCol;
    return (rank + fileIndex) % 2 === 1;
  }

  pieceAt(displayRow: number, displayCol: number): { type: string; color: 'w' | 'b' } | null {
    const sq = this.square(displayRow, displayCol);
    const piece = this._game.get(sq as Square);
    if (!piece) return null;
    return { type: piece.type, color: piece.color };
  }

  pieceSymbol(type: string, color: 'w' | 'b'): string {
    const white: Record<string, string> = {
      p: '♙',
      n: '♘',
      b: '♗',
      r: '♖',
      q: '♕',
      k: '♔'
    };
    const black: Record<string, string> = {
      p: '♟',
      n: '♞',
      b: '♝',
      r: '♜',
      q: '♛',
      k: '♚'
    };
    return color === 'w' ? white[type] : black[type];
  }

  squareClasses(displayRow: number, displayCol: number): Record<string, boolean> {
    const sq = this.square(displayRow, displayCol);
    return {
      'cb-square--light': this.isLight(displayRow, displayCol),
      'cb-square--dark': !this.isLight(displayRow, displayCol),
      'cb-square--selected': this.selectedSquare === sq,
      'cb-square--target': this.legalTargets.includes(sq),
      'cb-square--hint': this.hintFrom === sq || this.hintTo === sq
    };
  }

  onSquare(displayRow: number, displayCol: number): void {
    if (this.disabled) return;
    this.squareClick.emit(this.square(displayRow, displayCol));
  }
}
