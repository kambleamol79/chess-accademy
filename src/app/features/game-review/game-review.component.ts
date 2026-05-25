import { Component, inject, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { CardComponent } from 'src/app/theme/shared/components/card/card.component';
import { GameService } from 'src/app/core/services/game.service';

@Component({
  selector: 'app-game-review',
  imports: [CommonModule, CardComponent],
  templateUrl: './game-review.component.html',
  styleUrl: './game-review.component.scss'
})
export class GameReviewComponent implements OnInit {
  private readonly games = inject(GameService);

  loading = signal(true);
  error = signal('');
  rows = signal<Record<string, unknown>[]>([]);

  ngOnInit() {
    this.games.list().subscribe({
      next: (res) => {
        this.rows.set(res.data);
        this.loading.set(false);
      },
      error: () => {
        this.error.set('Failed to load games');
        this.loading.set(false);
      }
    });
  }
}
