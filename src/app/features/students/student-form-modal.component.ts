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
  city = '';
  level = '';
  payment_date = '';
  w_app = '';
  total_pay = '';
  payment_received = '';
  month_jan = '';
  month_feb = '';
  month_mar = '';
  month_apr = '';
  month_may = '';
  month_jun = '';
  month_jul = '';
  month_aug = '';
  month_sep = '';

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
    this.city = String(this.student['city'] ?? '');
    this.level = String(this.student['level'] ?? '');
    this.payment_date = this.student['payment_date']
      ? String(this.student['payment_date']).slice(0, 10)
      : '';
    this.w_app = String(this.student['w_app'] ?? '');
    this.total_pay = String(this.student['total_pay'] ?? '');
    this.payment_received = String(this.student['payment_received'] ?? '');
    this.month_jan = String(this.student['month_jan'] ?? '');
    this.month_feb = String(this.student['month_feb'] ?? '');
    this.month_mar = String(this.student['month_mar'] ?? '');
    this.month_apr = String(this.student['month_apr'] ?? '');
    this.month_may = String(this.student['month_may'] ?? '');
    this.month_jun = String(this.student['month_jun'] ?? '');
    this.month_jul = String(this.student['month_jul'] ?? '');
    this.month_aug = String(this.student['month_aug'] ?? '');
    this.month_sep = String(this.student['month_sep'] ?? '');
  }

  private rosterPayload(): Record<string, unknown> {
    return {
      city: this.city.trim() || null,
      level: this.level.trim() || null,
      payment_date: this.payment_date || null,
      w_app: this.w_app.trim() || null,
      total_pay: this.total_pay.trim() || null,
      payment_received: this.payment_received.trim() || null,
      month_jan: this.month_jan.trim() || null,
      month_feb: this.month_feb.trim() || null,
      month_mar: this.month_mar.trim() || null,
      month_apr: this.month_apr.trim() || null,
      month_may: this.month_may.trim() || null,
      month_jun: this.month_jun.trim() || null,
      month_jul: this.month_jul.trim() || null,
      month_aug: this.month_aug.trim() || null,
      month_sep: this.month_sep.trim() || null
    };
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
      const newPassword = this.password.trim();
      if (newPassword.length > 0 && newPassword.length < 8) {
        this.error.set('Password must be at least 8 characters');
        return;
      }

      const updatePayload: Record<string, unknown> = {
        first_name: this.first_name.trim(),
        last_name: this.last_name.trim(),
        email: this.email.trim() || undefined,
        phone: this.phone.trim() || null,
        parent_name: this.parent_name.trim() || null,
        parent_phone: this.parent_phone.trim() || null,
        date_of_birth: this.date_of_birth || null,
        chess_rating: Number(this.chess_rating) || 0,
        ...this.rosterPayload()
      };
      if (newPassword.length > 0) {
        updatePayload['password'] = newPassword;
      }

      this.saving.set(true);
      this.students
        .update(this.studentId, updatePayload)
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
        chess_rating: Number(this.chess_rating) || 0,
        ...this.rosterPayload()
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
