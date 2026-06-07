import { Component, Input } from '@angular/core';

const PIECE_FILES: Record<string, string> = {
  wp: 'wP.svg',
  wn: 'wN.svg',
  wb: 'wB.svg',
  wr: 'wR.svg',
  wq: 'wQ.svg',
  wk: 'wK.svg',
  bp: 'bP.svg',
  bn: 'bN.svg',
  bb: 'bB.svg',
  br: 'bR.svg',
  bq: 'bQ.svg',
  bk: 'bK.svg'
};

@Component({
  selector: 'app-chess-piece',
  template: `
    <div class="cp-piece" [class.cp-piece--white]="color === 'w'" [class.cp-piece--black]="color === 'b'">
      <span class="cp-piece__shadow" aria-hidden="true"></span>
      <img class="cp-piece__img" [src]="src" [alt]="alt" draggable="false" />
    </div>
  `,
  styleUrl: './chess-piece.component.scss'
})
export class ChessPieceComponent {
  @Input({ required: true }) type!: string;
  @Input({ required: true }) color!: 'w' | 'b';

  get src(): string {
    const file = PIECE_FILES[`${this.color}${this.type}`] ?? 'wP.svg';
    return `assets/chess-pieces/staunty/${file}`;
  }

  get alt(): string {
    const names: Record<string, string> = {
      p: 'pawn',
      n: 'knight',
      b: 'bishop',
      r: 'rook',
      q: 'queen',
      k: 'king'
    };
    const side = this.color === 'w' ? 'White' : 'Black';
    return `${side} ${names[this.type] ?? 'piece'}`;
  }
}
