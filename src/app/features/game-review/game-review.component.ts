import { Component, inject, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpErrorResponse } from '@angular/common/http';
import { CardComponent } from 'src/app/theme/shared/components/card/card.component';
import { GameService } from 'src/app/core/services/game.service';
import { AuthService } from 'src/app/core/services/auth.service';
import { confirmDelete } from 'src/app/core/utils/confirm.util';
import { getApiErrorMessage } from 'src/app/core/utils/http-error.util';

@Component({
  selector: 'app-game-review',
  imports: [CommonModule, CardComponent],
  templateUrl: './game-review.component.html',
  styleUrl: './game-review.component.scss'
})
export class GameReviewComponent implements OnInit {
  private readonly games = inject(GameService);
  readonly auth = inject(AuthService);

  loading = signal(true);
  error = signal('');
  deletingId = signal<number | null>(null);
  rows = signal<Record<string, unknown>[]>([]);

  ngOnInit() {
    this.load();
  }

  canDelete(): boolean {
    return this.auth.hasRole(['admin', 'coach']);
  }

  load() {
    this.loading.set(true);
    this.games.list().subscribe({
      next: (res) => {
        this.rows.set(res.data);
        this.loading.set(false);
        this.error.set('');
      },
      error: () => {
        this.error.set('Failed to load games');
        this.loading.set(false);
      }
    });
  }

  deleteGame(row: Record<string, unknown>) {
    const id = Number(row['id']);
    const label = String(row['title'] ?? `Game #${id}`);
    if (!confirmDelete(label)) {
      return;
    }

    this.deletingId.set(id);
    this.games.delete(id).subscribe({
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
}
