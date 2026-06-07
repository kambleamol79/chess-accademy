import { Component, inject, Input, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { NgbActiveModal } from '@ng-bootstrap/ng-bootstrap';
import { HttpErrorResponse } from '@angular/common/http';
import { BatchForm } from 'src/app/core/models/form.model';
import { AuthService } from 'src/app/core/services/auth.service';
import { FormService } from 'src/app/core/services/form.service';
import { EnrollmentService } from 'src/app/core/services/enrollment.service';
import { getApiErrorMessage } from 'src/app/core/utils/http-error.util';
import { groupBatchesByTimeSlot } from 'src/app/core/utils/batch.util';

@Component({
  selector: 'app-student-assign-batch-modal',
  imports: [CommonModule, FormsModule],
  templateUrl: './student-assign-batch-modal.component.html',
  styleUrl: './student-assign-batch-modal.component.scss'
})
export class StudentAssignBatchModalComponent implements OnInit {
  private readonly activeModal = inject(NgbActiveModal);
  private readonly forms = inject(FormService);
  private readonly enrollments = inject(EnrollmentService);
  readonly auth = inject(AuthService);

  @Input({ required: true }) studentIds!: number[];
  @Input() studentNames: string[] = [];

  loading = signal(true);
  saving = signal(false);
  error = signal('');
  batches = signal<BatchForm[]>([]);
  selectedFormId = signal<number | null>(null);

  ngOnInit() {
    this.forms.list().subscribe({
      next: (res) => {
        this.batches.set(res.data ?? []);
        this.loading.set(false);
      },
      error: () => {
        this.error.set('Failed to load batches');
        this.loading.set(false);
      }
    });
  }

  timeSlotGroups() {
    return groupBatchesByTimeSlot(this.batches());
  }

  selectBatch(batch: BatchForm) {
    this.selectedFormId.set(batch.id);
    this.error.set('');
  }

  isSelected(batch: BatchForm): boolean {
    return this.selectedFormId() === batch.id;
  }

  dismiss() {
    this.activeModal.dismiss();
  }

  assign() {
    const formId = this.selectedFormId();
    if (!formId) {
      this.error.set('Select a batch to assign students');
      return;
    }

    this.saving.set(true);
    this.enrollments.bulkAssign(formId, this.studentIds).subscribe({
      next: (res) => {
        this.saving.set(false);
        if (!res.success) {
          this.error.set(res.message ?? 'Could not assign batch');
          return;
        }
        this.activeModal.close(res.data);
      },
      error: (err: HttpErrorResponse) => {
        this.saving.set(false);
        this.error.set(getApiErrorMessage(err, 'Could not assign batch'));
      }
    });
  }
}
