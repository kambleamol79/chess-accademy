import { Component, inject, Input, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { NgbActiveModal } from '@ng-bootstrap/ng-bootstrap';
import { HttpErrorResponse } from '@angular/common/http';
import { StudentService } from 'src/app/core/services/student.service';
import { getApiErrorMessage } from 'src/app/core/utils/http-error.util';

@Component({
  selector: 'app-student-form-modal',
  imports: [CommonModule, FormsModule],
  templateUrl: './student-form-modal.component.html',
  styleUrl: './student-form-modal.component.scss'
})
export class StudentFormModalComponent implements OnInit {
  private readonly activeModal = inject(NgbActiveModal);
  private readonly students = inject(StudentService);

  @Input() mode: 'create' | 'edit' = 'create';
  @Input() student: Record<string, unknown> | null = null;

  saving = signal(false);
  error = signal('');

  studentId = 0;
  first_name = '';
  last_name = '';
  email = '';
  password = '';
  phone = '';
  parent_name = '';
  parent_phone = '';
  date_of_birth = '';
  chess_rating = 0;

  get isEdit(): boolean {
    return this.mode === 'edit';
  }

  ngOnInit() {
    if (!this.student) {
      return;
    }
    this.studentId = Number(this.student['id']);
    this.first_name = String(this.student['first_name'] ?? '');
    this.last_name = String(this.student['last_name'] ?? '');
    this.email = String(this.student['email'] ?? '');
    this.phone = String(this.student['phone'] ?? '');
    this.parent_name = String(this.student['parent_name'] ?? '');
    this.parent_phone = String(this.student['parent_phone'] ?? '');
    this.date_of_birth = this.student['date_of_birth']
      ? String(this.student['date_of_birth']).slice(0, 10)
      : '';
    this.chess_rating = Number(this.student['chess_rating']) || 0;
  }

  dismiss() {
    this.activeModal.dismiss();
  }

  save() {
    this.error.set('');

    if (!this.first_name.trim() || !this.last_name.trim()) {
      this.error.set('First and last name are required');
      return;
    }

    if (this.isEdit) {
      this.saving.set(true);
      this.students
        .update(this.studentId, {
          first_name: this.first_name.trim(),
          last_name: this.last_name.trim(),
          email: this.email.trim() || undefined,
          phone: this.phone.trim() || null,
          parent_name: this.parent_name.trim() || null,
          parent_phone: this.parent_phone.trim() || null,
          date_of_birth: this.date_of_birth || null,
          chess_rating: Number(this.chess_rating) || 0
        })
        .subscribe({
          next: (res) => this.finishSave(res, 'Could not update student'),
          error: (err: HttpErrorResponse) => this.failSave(err, 'Could not update student')
        });
      return;
    }

    if (!this.email.trim()) {
      this.error.set('Email is required');
      return;
    }
    if (this.password.length < 8) {
      this.error.set('Password must be at least 8 characters');
      return;
    }

    this.saving.set(true);
    this.students
      .create({
        first_name: this.first_name.trim(),
        last_name: this.last_name.trim(),
        email: this.email.trim(),
        password: this.password,
        phone: this.phone.trim() || null,
        parent_name: this.parent_name.trim() || null,
        parent_phone: this.parent_phone.trim() || null,
        date_of_birth: this.date_of_birth || null,
        chess_rating: Number(this.chess_rating) || 0
      })
      .subscribe({
        next: (res) => this.finishSave(res, 'Could not create student'),
        error: (err: HttpErrorResponse) => this.failSave(err, 'Could not create student')
      });
  }

  private finishSave(res: { success: boolean; message?: string; data?: unknown }, fallback: string) {
    this.saving.set(false);
    if (!res.success) {
      this.error.set(res.message ?? fallback);
      return;
    }
    this.activeModal.close(res.data);
  }

  private failSave(err: HttpErrorResponse, fallback: string) {
    this.saving.set(false);
    this.error.set(getApiErrorMessage(err, fallback));
  }
}
