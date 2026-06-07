import { Component, inject, Input, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { NgbActiveModal } from '@ng-bootstrap/ng-bootstrap';
import { HttpErrorResponse } from '@angular/common/http';
import { User } from 'src/app/core/models/api.model';
import { StaffUserService } from 'src/app/core/services/staff-user.service';
import { getApiErrorMessage } from 'src/app/core/utils/http-error.util';

@Component({
  selector: 'app-staff-password-modal',
  imports: [CommonModule, FormsModule],
  templateUrl: './staff-password-modal.component.html',
  styleUrl: './staff-password-modal.component.scss'
})
export class StaffPasswordModalComponent {
  private readonly activeModal = inject(NgbActiveModal);
  private readonly staffUsers = inject(StaffUserService);

  @Input({ required: true }) staff!: User;

  saving = signal(false);
  error = signal('');
  password = '';
  passwordConfirm = '';

  staffLabel(): string {
    return `${this.staff.first_name} ${this.staff.last_name}`.trim() || this.staff.email;
  }

  dismiss() {
    this.activeModal.dismiss();
  }

  save() {
    this.error.set('');

    if (this.password.length < 8) {
      this.error.set('Password must be at least 8 characters');
      return;
    }
    if (this.password !== this.passwordConfirm) {
      this.error.set('Passwords do not match');
      return;
    }

    this.saving.set(true);
    this.staffUsers.updatePassword(this.staff.id, this.password).subscribe({
      next: (res) => {
        this.saving.set(false);
        if (!res.success) {
          this.error.set(res.message ?? 'Could not update password');
          return;
        }
        this.activeModal.close(true);
      },
      error: (err: HttpErrorResponse) => {
        this.saving.set(false);
        this.error.set(getApiErrorMessage(err, 'Could not update password'));
      }
    });
  }
}
