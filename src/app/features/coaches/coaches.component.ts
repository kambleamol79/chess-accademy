import { Component, inject, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { CardComponent } from 'src/app/theme/shared/components/card/card.component';
import { CoachService } from 'src/app/core/services/coach.service';

@Component({
  selector: 'app-coaches',
  imports: [CommonModule, CardComponent],
  templateUrl: './coaches.component.html',
  styleUrl: './coaches.component.scss'
})
export class CoachesComponent implements OnInit {
  private readonly coaches = inject(CoachService);

  loading = signal(true);
  error = signal('');
  rows = signal<Record<string, unknown>[]>([]);

  ngOnInit() {
    this.coaches.list().subscribe({
      next: (res) => {
        this.rows.set(res.data);
        this.loading.set(false);
      },
      error: () => {
        this.error.set('Failed to load coaches');
        this.loading.set(false);
      }
    });
  }
}
