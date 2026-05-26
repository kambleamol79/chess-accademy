import { Component, inject, Input, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { NgbActiveModal } from '@ng-bootstrap/ng-bootstrap';
import { HttpErrorResponse } from '@angular/common/http';
import { CoachSchedulePayload, CoachService } from 'src/app/core/services/coach.service';
import { getApiErrorMessage } from 'src/app/core/utils/http-error.util';

export interface ScheduleCell {
  label: string;
  tone: 'blue' | 'beige' | 'practice' | 'empty';
}

@Component({
  selector: 'app-coach-schedule-modal',
  imports: [CommonModule],
  templateUrl: './coach-schedule-modal.component.html',
  styleUrl: './coach-schedule-modal.component.scss'
})
export class CoachScheduleModalComponent implements OnInit {
  private readonly activeModal = inject(NgbActiveModal);
  private readonly coachesApi = inject(CoachService);

  @Input({ required: true }) coachId!: number;
  @Input() coachName = '';

  loading = signal(true);
  error = signal('');
  schedule = signal<CoachSchedulePayload | null>(null);

  ngOnInit() {
    this.coachesApi.schedule(this.coachId).subscribe({
      next: (res) => {
        this.schedule.set(res.data);
        this.loading.set(false);
        this.error.set('');
      },
      error: (err: HttpErrorResponse) => {
        this.loading.set(false);
        this.error.set(getApiErrorMessage(err, 'Failed to load assigned batches'));
      }
    });
  }

  dismiss() {
    this.activeModal.dismiss();
  }

  headerName(): string {
    const s = this.schedule();
    if (s?.coach.display_name) {
      return `${s.coach.display_name} SIR`;
    }
    return this.coachName.toUpperCase() || 'COACH';
  }

  days(): string[] {
    return this.schedule()?.days ?? ['MON', 'TUE', 'WED', 'THUR', 'FRI', 'SAT'];
  }

  timeSlots(): string[] {
    return this.schedule()?.time_slots ?? [];
  }

  cell(time: string, day: string): ScheduleCell {
    const assignments = this.schedule()?.assignments ?? [];
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
