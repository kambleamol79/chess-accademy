import { Component, inject, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { CardComponent } from 'src/app/theme/shared/components/card/card.component';
import { DashboardMetrics, DashboardService } from 'src/app/core/services/dashboard.service';

@Component({
  selector: 'app-dashboard',
  imports: [CommonModule, CardComponent],
  templateUrl: './dashboard.component.html',
  styleUrl: './dashboard.component.scss'
})
export class DashboardComponent implements OnInit {
  private readonly dashboard = inject(DashboardService);

  loading = signal(true);
  error = signal('');
  metrics = signal<DashboardMetrics | null>(null);

  ngOnInit() {
    this.dashboard.getMetrics().subscribe({
      next: (res) => {
        this.metrics.set(res.data);
        this.loading.set(false);
      },
      error: () => {
        this.error.set('Could not load dashboard. Is the API running?');
        this.loading.set(false);
      }
    });
  }
}
