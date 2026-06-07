import { Component, computed, inject, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { CardComponent } from 'src/app/theme/shared/components/card/card.component';
import { BatchForm } from 'src/app/core/models/form.model';
import { FormService } from 'src/app/core/services/form.service';
import { StudentPortalService } from 'src/app/core/services/student-portal.service';
import { AuthService } from 'src/app/core/services/auth.service';
import { studentBatchToBatchForm } from 'src/app/core/utils/student-batch.util';
import { BatchFormModalComponent } from './batch-form-modal.component';
import {
  BatchAssignCoachModalComponent,
  CoachSlot
} from './batch-assign-coach-modal.component';
import { HttpErrorResponse } from '@angular/common/http';
import { confirmDelete } from 'src/app/core/utils/confirm.util';
import { getApiErrorMessage } from 'src/app/core/utils/http-error.util';
import { groupBatchesByTimeSlot, hasBatchZoom } from 'src/app/core/utils/batch.util';
import { BatchCalendarComponent } from './batch-calendar.component';
import { BatchMessagesModalComponent } from './batch-messages-modal.component';
import { openZoomExternalFullscreen } from 'src/app/core/utils/zoom-open.util';

export type BatchesPageView = 'calendar' | 'list';

@Component({
  selector: 'app-batches',
  imports: [CommonModule, CardComponent, BatchCalendarComponent],
  templateUrl: './batches.component.html',
  styleUrl: './batches.component.scss'
})
export class BatchesComponent implements OnInit {
  private readonly forms = inject(FormService);
  private readonly studentPortal = inject(StudentPortalService);
  private readonly modal = inject(NgbModal);
  readonly auth = inject(AuthService);

  loading = signal(true);
  error = signal('');
  deletingId = signal<number | null>(null);
  rows = signal<BatchForm[]>([]);
  pageView = signal<BatchesPageView>('calendar');
  timeSlotGroups = computed(() => groupBatchesByTimeSlot(this.rows()));

  readonly hasBatchZoom = hasBatchZoom;
  readonly isStudent = computed(() => this.auth.hasRole(['student']));

  setPageView(view: BatchesPageView) {
    if (this.isStudent()) {
      return;
    }
    this.pageView.set(view);
  }

  ngOnInit() {
    if (this.isStudent()) {
      this.pageView.set('list');
    }
    this.load();
  }

  canManageBatches(): boolean {
    return this.auth.hasRole(['admin']);
  }

  canAssignCoach(): boolean {
    return this.auth.hasRole(['admin']);
  }

  canDelete(): boolean {
    return this.auth.hasRole(['admin']);
  }

  load() {
    this.loading.set(true);

    if (this.isStudent()) {
      this.studentPortal.getMyBatch().subscribe({
        next: (res) => {
          const batch = res.data?.batch;
          this.rows.set(batch ? [studentBatchToBatchForm(batch)] : []);
          this.loading.set(false);
          this.error.set('');
        },
        error: (err: HttpErrorResponse) => {
          this.error.set(getApiErrorMessage(err, 'Could not load your batch'));
          this.loading.set(false);
        }
      });
      return;
    }

    this.forms.list().subscribe({
      next: (res) => {
        this.rows.set(res.data);
        this.loading.set(false);
        this.error.set('');
      },
      error: () => {
        this.error.set('Failed to load batches');
        this.loading.set(false);
      }
    });
  }

  canEdit(): boolean {
    return this.canManageBatches();
  }

  openAddBatch(timeSlot?: string) {
    this.openBatchModal('create', undefined, timeSlot);
  }

  openEditBatch(row: BatchForm) {
    this.openBatchModal('edit', row);
  }

  private openBatchModal(mode: 'create' | 'edit', batch?: BatchForm, defaultTime?: string) {
    const ref = this.modal.open(BatchFormModalComponent, {
      size: 'lg',
      centered: true,
      backdrop: 'static'
    });
    ref.componentInstance.mode = mode;
    ref.componentInstance.existingBatches = this.rows();
    if (batch) {
      ref.componentInstance.batchRecord = batch;
    }
    if (defaultTime) {
      ref.componentInstance.defaultTime = defaultTime;
    }
    ref.closed.subscribe(() => {
      this.load();
    });
  }

  openJoinZoom(row: BatchForm) {
    const url = row.zoom_join_url?.trim();
    if (url) {
      openZoomExternalFullscreen(url);
    }
  }

  openBatchMessages(row: BatchForm) {
    if (!this.canManageBatches()) {
      return;
    }

    const ref = this.modal.open(BatchMessagesModalComponent, {
      size: 'lg',
      scrollable: true,
      centered: true
    });
    ref.componentInstance.formId = row.id;
    ref.componentInstance.batchName = row.batch;
  }

  openAssignCoach(row: BatchForm, slot: CoachSlot) {
    if (!this.canAssignCoach()) {
      return;
    }

    const ref = this.modal.open(BatchAssignCoachModalComponent, {
      size: 'md',
      centered: true
    });

    ref.componentInstance.batch = row;
    ref.componentInstance.slot = slot;

    ref.closed.subscribe(() => this.load());
  }

  rowClass(highlight: string): string {
    return highlight === 'blue' ? 'table-primary' : '';
  }

  deleteBatch(row: BatchForm) {
    const label = row.batch || `Batch #${row.id}`;
    if (!confirmDelete(label)) {
      return;
    }

    this.deletingId.set(row.id);
    this.forms.delete(row.id).subscribe({
      next: () => {
        this.deletingId.set(null);
        this.load();
      },
      error: (err: HttpErrorResponse) => {
        this.deletingId.set(null);
        this.error.set(getApiErrorMessage(err, 'Could not delete batch'));
      }
    });
  }
}
