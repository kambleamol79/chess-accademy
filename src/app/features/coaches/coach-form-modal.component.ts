import { Component, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { NgbActiveModal } from '@ng-bootstrap/ng-bootstrap';
import { HttpErrorResponse } from '@angular/common/http';
import { CoachService } from 'src/app/core/services/coach.service';
import { getApiErrorMessage } from 'src/app/core/utils/http-error.util';

@Component({
  selector: 'app-coach-form-modal',
  imports: [CommonModule, FormsModule],
  templateUrl: './coach-form-modal.component.html',
  styleUrl: './coach-form-modal.component.scss'
})
export class CoachFormModalComponent {
  private readonly activeModal = inject(NgbActiveModal);
  private readonly coaches = inject(CoachService);

  saving = signal(false);
  error = signal('');

  first_name = '';
  last_name = '';
  email = '';
  password = '';
  phone = '';
  title = '';
  bio = '';
  rating: number | null = null;

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
    this.coaches
      .create({
        first_name: this.first_name.trim(),
        last_name: this.last_name.trim(),
        email: this.email.trim(),
        password: this.password,
        phone: this.phone.trim() || null,
        title: this.title.trim() || null,
        bio: this.bio.trim() || null,
        rating: this.rating !== null && this.rating !== undefined ? Number(this.rating) : null
      })
      .subscribe({
        next: (res) => {
          this.saving.set(false);
          if (!res.success) {
            this.error.set(res.message ?? 'Could not create coach');
            return;
          }
          this.activeModal.close(res.data);
        },
        error: (err: HttpErrorResponse) => {
          this.saving.set(false);
          this.error.set(getApiErrorMessage(err, 'Could not create coach'));
        }
      });
  }
}
