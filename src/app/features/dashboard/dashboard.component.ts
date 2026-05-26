import { Component, inject, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { CardComponent } from 'src/app/theme/shared/components/card/card.component';
import { DashboardMetrics, DashboardService } from 'src/app/core/services/dashboard.service';
import { AuthService } from 'src/app/core/services/auth.service';
import { CoachSchedulePayload } from 'src/app/core/services/coach.service';
import { HttpErrorResponse } from '@angular/common/http';
import { getApiErrorMessage } from 'src/app/core/utils/http-error.util';

export interface ScheduleCell {
  label: string;
  tone: 'blue' | 'beige' | 'practice' | 'empty';
}

@Component({
  selector: 'app-dashboard',
  imports: [CommonModule, CardComponent],
  templateUrl: './dashboard.component.html',
  styleUrl: './dashboard.component.scss'
})
export class DashboardComponent implements OnInit {
  private readonly dashboard = inject(DashboardService);
  private readonly auth = inject(AuthService);

  metrics = signal<DashboardMetrics | null>(null);
  coachSchedule = signal<CoachSchedulePayload | null>(null);

  loading = signal(true);
  error = signal('');

  ngOnInit() {
    if (this.auth.hasRole(['coach'])) {
      this.dashboard.getCoachSchedule().subscribe({
        next: (res) => {
          this.coachSchedule.set(res.data);
          this.loading.set(false);
          this.error.set('');
        },
        error: (err: HttpErrorResponse) => {
          this.error.set(getApiErrorMessage(err, 'Could not load assigned batches. Is the API running?'));
          this.loading.set(false);
        }
      });
      return;
    }

    this.dashboard.getMetrics().subscribe({
      next: (res) => {
        this.metrics.set(res.data);
        this.loading.set(false);
        this.error.set('');
      },
      error: () => {
        this.error.set('Could not load dashboard. Is the API running?');
        this.loading.set(false);
      }
    });
  }

  headerName(): string {
    const s = this.coachSchedule();
    if (s?.coach.display_name) {
      return `${s.coach.display_name} SIR`;
    }
    return 'COACH';
  }

  days(): string[] {
    return this.coachSchedule()?.days ?? ['MON', 'TUE', 'WED', 'THUR', 'FRI', 'SAT'];
  }

  timeSlots(): string[] {
    return this.coachSchedule()?.time_slots ?? [];
  }

  cell(time: string, day: string): ScheduleCell {
    const assignments = this.coachSchedule()?.assignments ?? [];
    const match = assignments.find((a) => a.time === time && a.day === day);
    if (!match) {
      return { label: '', tone: 'empty' };
    }
    return {
      label: match.label,
      tone: match.is_practice ? 'practice' : match.highlight
    };
  }

  cellClass(cell: ScheduleCell): string {
    if (cell.tone === 'empty') {
      return 'coach-schedule__cell--empty';
    }
    if (cell.tone === 'practice') {
      return 'coach-schedule__cell--practice';
    }
    if (cell.tone === 'blue') {
      return 'coach-schedule__cell--blue';
    }
    return 'coach-schedule__cell--beige';
  }
}
