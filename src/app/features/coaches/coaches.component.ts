import { Component, inject, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { CardComponent } from 'src/app/theme/shared/components/card/card.component';
import { CoachService } from 'src/app/core/services/coach.service';
import { AuthService } from 'src/app/core/services/auth.service';
import { HttpErrorResponse } from '@angular/common/http';
import { CoachFormModalComponent } from './coach-form-modal.component';
import { confirmDelete } from 'src/app/core/utils/confirm.util';
import { getApiErrorMessage } from 'src/app/core/utils/http-error.util';

@Component({
  selector: 'app-coaches',
  imports: [CommonModule, CardComponent],
  templateUrl: './coaches.component.html',
  styleUrl: './coaches.component.scss'
})
export class CoachesComponent implements OnInit {
  private readonly coaches = inject(CoachService);
  private readonly modal = inject(NgbModal);
  readonly auth = inject(AuthService);

  loading = signal(true);
  error = signal('');
  deletingId = signal<number | null>(null);
  rows = signal<Record<string, unknown>[]>([]);

  ngOnInit() {
    this.load();
  }

  canAddCoach(): boolean {
    return this.auth.hasRole(['admin']);
  }

  canDelete(): boolean {
    return this.auth.hasRole(['admin']);
  }

  load() {
    this.loading.set(true);
    this.coaches.list().subscribe({
      next: (res) => {
        this.rows.set(res.data);
        this.loading.set(false);
        this.error.set('');
      },
      error: () => {
        this.error.set('Failed to load coaches');
        this.loading.set(false);
      }
    });
  }

  canEdit(): boolean {
    return this.auth.hasRole(['admin']);
  }

  openAddCoach() {
    this.openCoachModal('create');
  }

  openEditCoach(row: Record<string, unknown>) {
    this.openCoachModal('edit', row);
  }

  private openCoachModal(mode: 'create' | 'edit', coach?: Record<string, unknown>) {
    const ref = this.modal.open(CoachFormModalComponent, {
      size: 'lg',
      centered: true,
      backdrop: 'static'
    });
    ref.componentInstance.mode = mode;
    if (coach) {
      ref.componentInstance.coach = coach;
    }
    ref.closed.subscribe(() => this.load());
  }

  deleteCoach(row: Record<string, unknown>) {
    const id = Number(row['id']);
    const label = `${row['first_name']} ${row['last_name']}`.trim();
    if (!confirmDelete(label || `Coach #${id}`)) {
      return;
    }

    this.deletingId.set(id);
    this.coaches.delete(id).subscribe({
      next: () => {
        this.deletingId.set(null);
        this.load();
      },
      error: (err: HttpErrorResponse) => {
        this.deletingId.set(null);
        this.error.set(getApiErrorMessage(err, 'Could not delete coach'));
      }
    });
  }
}
