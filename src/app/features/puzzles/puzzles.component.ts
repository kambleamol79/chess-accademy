import { Component, inject, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { CardComponent } from 'src/app/theme/shared/components/card/card.component';
import { PuzzleService } from 'src/app/core/services/puzzle.service';

@Component({
  selector: 'app-puzzles',
  imports: [CommonModule, CardComponent],
  templateUrl: './puzzles.component.html',
  styleUrl: './puzzles.component.scss'
})
export class PuzzlesComponent implements OnInit {
  private readonly puzzles = inject(PuzzleService);

  loading = signal(true);
  error = signal('');
  rows = signal<Record<string, unknown>[]>([]);

  ngOnInit() {
    this.puzzles.list().subscribe({
      next: (res) => {
        this.rows.set(res.data);
        this.loading.set(false);
      },
      error: () => {
        this.error.set('Failed to load puzzles');
        this.loading.set(false);
      }
    });
  }
}
