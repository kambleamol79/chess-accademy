import { Component, inject, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpErrorResponse } from '@angular/common/http';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { CardComponent } from 'src/app/theme/shared/components/card/card.component';
import { GameService } from 'src/app/core/services/game.service';
import { AuthService } from 'src/app/core/services/auth.service';
import { ReviewGame } from 'src/app/core/models/game.model';
import { confirmDelete } from 'src/app/core/utils/confirm.util';
import { getApiErrorMessage } from 'src/app/core/utils/http-error.util';
import { GamePgnUploadModalComponent } from './game-pgn-upload-modal.component';
import { GamePgnViewModalComponent } from './game-pgn-view-modal.component';

@Component({
  selector: 'app-game-review',
  imports: [CommonModule, CardComponent],
  templateUrl: './game-review.component.html',
  styleUrl: './game-review.component.scss'
})
export class GameReviewComponent implements OnInit {
  private readonly games = inject(GameService);
  private readonly modal = inject(NgbModal);
  readonly auth = inject(AuthService);

  loading = signal(true);
  error = signal('');
  deletingId = signal<number | null>(null);
  rows = signal<ReviewGame[]>([]);

  ngOnInit() {
    this.load();
  }

  canUpload(): boolean {
    return this.auth.hasRole(['admin']);
  }

  canDelete(): boolean {
    return this.auth.hasRole(['admin', 'coach']);
  }

  load() {
    this.loading.set(true);
    this.games.list().subscribe({
      next: (res) => {
        this.rows.set(res.data ?? []);
        this.loading.set(false);
        this.error.set('');
      },
      error: () => {
        this.error.set('Failed to load games');
        this.loading.set(false);
      }
    });
  }

  openUploadModal() {
    const ref = this.modal.open(GamePgnUploadModalComponent, { size: 'lg', backdrop: 'static' });
    ref.closed.subscribe((saved) => {
      if (saved) {
        this.load();
      }
    });
  }

  viewGame(game: ReviewGame) {
    const ref = this.modal.open(GamePgnViewModalComponent, { size: 'lg' });
    ref.componentInstance.game = game;
  }

  deleteGame(game: ReviewGame) {
    const label = game.title ?? `Game #${game.id}`;
    if (!confirmDelete(label)) {
      return;
    }

    this.deletingId.set(game.id);
    this.games.delete(game.id).subscribe({
      next: () => {
        this.deletingId.set(null);
        this.load();
      },
      error: (err: HttpErrorResponse) => {
        this.deletingId.set(null);
        this.error.set(getApiErrorMessage(err, 'Could not delete game'));
      }
    });
  }

  studentName(game: ReviewGame): string {
    return `${game.first_name ?? ''} ${game.last_name ?? ''}`.trim() || `Student #${game.student_id}`;
  }
}
