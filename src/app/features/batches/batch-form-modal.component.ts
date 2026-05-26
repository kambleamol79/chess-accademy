import { Component, inject, Input, OnInit, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { NgbActiveModal } from '@ng-bootstrap/ng-bootstrap';
import { HttpErrorResponse } from '@angular/common/http';
import { CommonModule } from '@angular/common';
import { BatchForm } from 'src/app/core/models/form.model';
import { FormService } from 'src/app/core/services/form.service';
import { CoachService } from 'src/app/core/services/coach.service';
import { getApiErrorMessage } from 'src/app/core/utils/http-error.util';
import {
  formatTimeSlot,
  isValidTimeSlotRange,
  nextBatchCode,
  parseTimeSlot
} from 'src/app/core/utils/batch.util';

export interface CoachOption {
  id: number;
  label: string;
}

@Component({
  selector: 'app-batch-form-modal',
  imports: [CommonModule, FormsModule],
  templateUrl: './batch-form-modal.component.html',
  styleUrl: './batch-form-modal.component.scss'
})
export class BatchFormModalComponent implements OnInit {
  private readonly activeModal = inject(NgbActiveModal);
  private readonly forms = inject(FormService);
  private readonly coachesApi = inject(CoachService);

  @Input() mode: 'create' | 'edit' = 'create';
  @Input() batchRecord: BatchForm | null = null;
  @Input() existingBatches: BatchForm[] = [];
  @Input() defaultTime = '';

  batchId = 0;
  saving = signal(false);
  error = signal('');
  coaches = signal<CoachOption[]>([]);

  readonly moduleLevels = ['Beginner', 'Intermediate', 'Advanced', 'Expert'];
  readonly weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
  readonly dayPresets = [
    { label: 'Mon / Tue', day1: 'MON', day2: 'TUE' },
    { label: 'Wed / Thu', day1: 'WED', day2: 'THU' },
    { label: 'Thu / Fri', day1: 'THU', day2: 'FRI' },
    { label: 'Sat / Sun', day1: 'SAT', day2: 'SUN' }
  ];

  batch = '';
  module = '';
  timeStart = '07:00';
  timeEnd = '08:00';
  day1 = 'MON';
  day2 = 'TUE';
  coach1 = '';
  coach2 = '';
  highlight: 'blue' | 'beige' = 'beige';
  notes = '';

  get isEdit(): boolean {
    return this.mode === 'edit';
  }

  get formattedTimeSlot(): string {
    return formatTimeSlot(this.timeStart, this.timeEnd);
  }

  ngOnInit() {
    if (this.batchRecord) {
      this.batchId = this.batchRecord.id;
      this.batch = this.batchRecord.batch;
      this.module = this.batchRecord.module ?? '';
      this.applyTimeSlot(this.batchRecord.time);
      this.day1 = this.batchRecord.day_1;
      this.day2 = this.batchRecord.day_2;
      this.coach1 = this.batchRecord.coach_1 ?? '';
      this.coach2 = this.batchRecord.coach_2 ?? '';
      this.highlight = (this.batchRecord.highlight === 'blue' ? 'blue' : 'beige') as 'blue' | 'beige';
      this.notes = this.batchRecord.notes ?? '';
    } else {
      if (this.defaultTime) {
        this.applyTimeSlot(this.defaultTime);
      }
      this.loadNextBatchCode();
    }

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

  private loadNextBatchCode() {
    this.forms.nextBatch().subscribe({
      next: (res) => {
        if (res.data?.batch) {
          this.batch = res.data.batch;
        }
      },
      error: () => {
        const codes = this.existingBatches.map((b) => b.batch);
        this.batch = nextBatchCode(codes);
      }
    });
  }

  applyTimeSlot(slot: string) {
    const { start, end } = parseTimeSlot(slot);
    this.timeStart = start;
    this.timeEnd = end;
  }

  applyDayPreset(day1: string, day2: string) {
    this.day1 = day1;
    this.day2 = day2;
  }

  get daysSummary(): string {
    return `${this.day1}/${this.day2}`;
  }

  dismiss() {
    this.activeModal.dismiss();
  }

  save() {
    this.error.set('');
    const batch = this.batch.trim();
    if (!batch) {
      this.error.set('Batch code is required');
      return;
    }
    if (!this.timeStart || !this.timeEnd) {
      this.error.set('Start and end time are required');
      return;
    }
    if (!isValidTimeSlotRange(this.timeStart, this.timeEnd)) {
      this.error.set('End time must be after start time');
      return;
    }

    this.saving.set(true);
    const payload = {
      highlight: this.highlight,
      batch,
      module: this.module.trim() || null,
      time: this.formattedTimeSlot,
      days_summary: this.daysSummary,
      day_1: this.day1,
      day_2: this.day2,
      coach_1: this.coach1.trim() || null,
      coach_2: this.coach2.trim() || null,
      notes: this.notes.trim() || null
    };

    const req = this.isEdit
      ? this.forms.update(this.batchId, payload)
      : this.forms.create(payload);

    req.subscribe({
      next: (res) => {
        this.saving.set(false);
        if (!res.success) {
          this.error.set(res.message ?? (this.isEdit ? 'Could not update batch' : 'Could not save batch'));
          return;
        }
        this.activeModal.close(res.data);
      },
      error: (err: HttpErrorResponse) => {
        this.saving.set(false);
        this.error.set(getApiErrorMessage(err, this.isEdit ? 'Could not update batch' : 'Could not save batch'));
      }
    });
  }
}
