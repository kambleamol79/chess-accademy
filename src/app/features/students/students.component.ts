import { Component, inject, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { CardComponent } from 'src/app/theme/shared/components/card/card.component';
import { StudentService } from 'src/app/core/services/student.service';
import { AuthService } from 'src/app/core/services/auth.service';
import { HttpErrorResponse } from '@angular/common/http';
import { StudentFormModalComponent } from './student-form-modal.component';
import { confirmDelete } from 'src/app/core/utils/confirm.util';
import { getApiErrorMessage } from 'src/app/core/utils/http-error.util';

@Component({
  selector: 'app-students',
  imports: [CommonModule, CardComponent],
  templateUrl: './students.component.html',
  styleUrl: './students.component.scss'
})
export class StudentsComponent implements OnInit {
  private readonly students = inject(StudentService);
  private readonly modal = inject(NgbModal);
  readonly auth = inject(AuthService);

  loading = signal(true);
  error = signal('');
  deletingId = signal<number | null>(null);
  rows = signal<Record<string, unknown>[]>([]);

  ngOnInit() {
    this.load();
  }

  canAddStudent(): boolean {
    return this.auth.hasRole(['admin']);
  }

  canDelete(): boolean {
    return this.auth.hasRole(['admin']);
  }

  load() {
    this.loading.set(true);
    this.students.list().subscribe({
      next: (res) => {
        this.rows.set(res.data);
        this.loading.set(false);
        this.error.set('');
      },
      error: () => {
        this.error.set('Failed to load students');
        this.loading.set(false);
      }
    });
  }

  canEdit(): boolean {
    return this.auth.hasRole(['admin']);
  }

  openAddStudent() {
    this.openStudentModal('create');
  }

  openEditStudent(row: Record<string, unknown>) {
    this.openStudentModal('edit', row);
  }

  private openStudentModal(mode: 'create' | 'edit', student?: Record<string, unknown>) {
    const ref = this.modal.open(StudentFormModalComponent, {
      size: 'lg',
      centered: true,
      backdrop: 'static'
    });
    ref.componentInstance.mode = mode;
    if (student) {
      ref.componentInstance.student = student;
    }
    ref.closed.subscribe(() => this.load());
  }

  deleteStudent(row: Record<string, unknown>) {
    const id = Number(row['id']);
    const label = `${row['first_name']} ${row['last_name']}`.trim();
    if (!confirmDelete(label || `Student #${id}`)) {
      return;
    }

    this.deletingId.set(id);
    this.students.delete(id).subscribe({
      next: () => {
        this.deletingId.set(null);
        this.load();
      },
      error: (err: HttpErrorResponse) => {
        this.deletingId.set(null);
        this.error.set(getApiErrorMessage(err, 'Could not delete student'));
      }
    });
  }
}
