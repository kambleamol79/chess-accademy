import { Component, inject, signal } from '@angular/core';
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
export class StudentFormModalComponent {
  private readonly activeModal = inject(NgbActiveModal);
  private readonly students = inject(StudentService);

  saving = signal(false);
  error = signal('');

  first_name = '';
  last_name = '';
  email = '';
  password = '';
  phone = '';
  parent_name = '';
  parent_phone = '';
  date_of_birth = '';
  chess_rating = 0;

  dismiss() {
    this.activeModal.dismiss();
  }

  save() {
    this.error.set('');

    if (!this.first_name.trim() || !this.last_name.trim()) {
      this.error.set('First and last name are required');
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
        next: (res) => {
          this.saving.set(false);
          if (!res.success) {
            this.error.set(res.message ?? 'Could not create student');
            return;
          }
          this.activeModal.close(res.data);
        },
        error: (err: HttpErrorResponse) => {
          this.saving.set(false);
          this.error.set(getApiErrorMessage(err, 'Could not create student'));
        }
      });
  }
}
