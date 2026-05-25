import { Component, inject, Input, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { NgbActiveModal } from '@ng-bootstrap/ng-bootstrap';
import { HttpErrorResponse } from '@angular/common/http';
import { BatchForm } from 'src/app/core/models/form.model';
import { FormService } from 'src/app/core/services/form.service';
import { CoachService } from 'src/app/core/services/coach.service';
import { getApiErrorMessage } from 'src/app/core/utils/http-error.util';

export type CoachSlot = 'coach_1' | 'coach_2';

export interface CoachOption {
  id: number;
  label: string;
}

@Component({
  selector: 'app-batch-assign-coach-modal',
  imports: [CommonModule, FormsModule],
  templateUrl: './batch-assign-coach-modal.component.html',
  styleUrl: './batch-assign-coach-modal.component.scss'
})
export class BatchAssignCoachModalComponent implements OnInit {
  private readonly activeModal = inject(NgbActiveModal);
  private readonly forms = inject(FormService);
  private readonly coachesApi = inject(CoachService);

  @Input({ required: true }) batch!: BatchForm;
  @Input({ required: true }) slot!: CoachSlot;

  saving = signal(false);
  error = signal('');
  coaches = signal<CoachOption[]>([]);

  selectedCoach = '';

  get dayLabel(): string {
    return this.slot === 'coach_1' ? this.batch.day_1 : this.batch.day_2;
  }

  get slotLabel(): string {
    return this.slot === 'coach_1' ? 'Coach (day 1)' : 'Coach (day 2)';
  }

  ngOnInit() {
    this.selectedCoach = this.batch[this.slot] ?? '';

    this.coachesApi.list().subscribe({
      next: (res) => {
        const options = (res.data ?? []).map((c) => ({
          id: Number(c['id']),
          label: `${c['first_name'] ?? ''} ${c['last_name'] ?? ''}`.trim()
        }));
        this.coaches.set(options);
      }
    });
  }

  dismiss() {
    this.activeModal.dismiss();
  }

  clearCoach() {
    this.selectedCoach = '';
    this.save();
  }

  save() {
    this.error.set('');
    this.saving.set(true);

    const payload: Partial<BatchForm> = {
      [this.slot]: this.selectedCoach.trim() || null
    };

    this.forms.update(this.batch.id, payload).subscribe({
      next: (res) => {
        this.saving.set(false);
        if (!res.success) {
          this.error.set(res.message ?? 'Could not assign coach');
          return;
        }
        this.activeModal.close(res.data);
      },
      error: (err: HttpErrorResponse) => {
        this.saving.set(false);
        this.error.set(getApiErrorMessage(err, 'Could not assign coach'));
      }
    });
  }
}
