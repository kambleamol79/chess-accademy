import { Component, inject, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { CardComponent } from 'src/app/theme/shared/components/card/card.component';
import { BatchForm } from 'src/app/core/models/form.model';
import { FormService } from 'src/app/core/services/form.service';
import { AuthService } from 'src/app/core/services/auth.service';
import { BatchFormModalComponent } from './batch-form-modal.component';
import {
  BatchAssignCoachModalComponent,
  CoachSlot
} from './batch-assign-coach-modal.component';

@Component({
  selector: 'app-batches',
  imports: [CommonModule, CardComponent],
  templateUrl: './batches.component.html',
  styleUrl: './batches.component.scss'
})
export class BatchesComponent implements OnInit {
  private readonly forms = inject(FormService);
  private readonly modal = inject(NgbModal);
  readonly auth = inject(AuthService);

  loading = signal(true);
  error = signal('');
  rows = signal<BatchForm[]>([]);

  ngOnInit() {
    this.load();
  }

  canManageBatches(): boolean {
    return this.auth.hasRole(['admin', 'coach']);
  }

  canAssignCoach(): boolean {
    return this.auth.hasRole(['admin']);
  }

  load() {
    this.loading.set(true);
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

  openAddBatch() {
    const ref = this.modal.open(BatchFormModalComponent, {
      size: 'lg',
      centered: true,
      backdrop: 'static'
    });

    ref.closed.subscribe(() => this.load());
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
}
