import { Component, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { NgbActiveModal } from '@ng-bootstrap/ng-bootstrap';
import { HttpErrorResponse } from '@angular/common/http';
import { CreateStaffUserPayload, StaffRole, StaffUserService } from 'src/app/core/services/staff-user.service';
import { getApiErrorMessage } from 'src/app/core/utils/http-error.util';

const ROLE_OPTIONS: { value: StaffRole; label: string; hint: string }[] = [
  { value: 'admin', label: 'Admin', hint: 'Full access — settings, batches, billing, all students' },
  { value: 'coach', label: 'Coach', hint: 'Add students and assign to own batches only' },
  { value: 'accountant', label: 'Accountant', hint: 'Billing and payment receipts' }
];

@Component({
  selector: 'app-staff-user-form-modal',
  imports: [CommonModule, FormsModule],
  templateUrl: './staff-user-form-modal.component.html',
  styleUrl: './staff-user-form-modal.component.scss'
})
export class StaffUserFormModalComponent {
  private readonly activeModal = inject(NgbActiveModal);
  private readonly staffUsers = inject(StaffUserService);

  readonly roleOptions = ROLE_OPTIONS;

  saving = signal(false);
  error = signal('');

  first_name = '';
  last_name = '';
  email = '';
  password = '';
  phone = '';
  role: StaffRole = 'admin';
  title = '';

  get isCoach(): boolean {
    return this.role === 'coach';
  }

  roleHint(): string {
    return ROLE_OPTIONS.find((o) => o.value === this.role)?.hint ?? '';
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
    if (!this.email.trim()) {
      this.error.set('Email is required');
      return;
    }
    if (this.password.length < 8) {
      this.error.set('Password must be at least 8 characters');
      return;
    }

    const payload: CreateStaffUserPayload = {
      first_name: this.first_name.trim(),
      last_name: this.last_name.trim(),
      email: this.email.trim(),
      password: this.password,
      role: this.role,
      phone: this.phone.trim() || null
    };

    if (this.isCoach) {
      payload.title = this.title.trim() || null;
    }

    this.saving.set(true);
    this.staffUsers.create(payload).subscribe({
      next: (res) => {
        this.saving.set(false);
        if (!res.success) {
          this.error.set(res.message ?? 'Could not create account');
          return;
        }
        this.activeModal.close(res.data);
      },
      error: (err: HttpErrorResponse) => {
        this.saving.set(false);
        this.error.set(getApiErrorMessage(err, 'Could not create account'));
      }
    });
  }
}
