import { Component, inject, Input, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { NgbActiveModal } from '@ng-bootstrap/ng-bootstrap';
import { HttpErrorResponse } from '@angular/common/http';
import { CoachService } from 'src/app/core/services/coach.service';
import { AuthService } from 'src/app/core/services/auth.service';
import { getApiErrorMessage } from 'src/app/core/utils/http-error.util';

@Component({
  selector: 'app-coach-form-modal',
  imports: [CommonModule, FormsModule],
  templateUrl: './coach-form-modal.component.html',
  styleUrl: './coach-form-modal.component.scss'
})
export class CoachFormModalComponent implements OnInit {
  private readonly activeModal = inject(NgbActiveModal);
  private readonly coaches = inject(CoachService);
  private readonly auth = inject(AuthService);

  @Input() mode: 'create' | 'edit' = 'create';
  @Input() coach: Record<string, unknown> | null = null;

  saving = signal(false);
  error = signal('');

  coachId = 0;
  first_name = '';
  last_name = '';
  email = '';
  password = '';
  phone = '';
  title = '';
  bio = '';
  rating: number | null = null;

  get isEdit(): boolean {
    return this.mode === 'edit';
  }

  canSetPassword(): boolean {
    return this.auth.hasRole(['admin']);
  }

  ngOnInit() {
    if (!this.coach) {
      return;
    }
    this.coachId = Number(this.coach['id']);
    this.first_name = String(this.coach['first_name'] ?? '');
    this.last_name = String(this.coach['last_name'] ?? '');
    this.email = String(this.coach['email'] ?? '');
    this.phone = String(this.coach['phone'] ?? '');
    this.title = String(this.coach['title'] ?? '');
    this.bio = String(this.coach['bio'] ?? '');
    this.rating = this.coach['rating'] != null ? Number(this.coach['rating']) : null;
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
      const payload: Record<string, unknown> = {
        first_name: this.first_name.trim(),
        last_name: this.last_name.trim(),
        email: this.email.trim() || undefined,
        phone: this.phone.trim() || null,
        title: this.title.trim() || null,
        bio: this.bio.trim() || null,
        rating: this.rating !== null && this.rating !== undefined ? Number(this.rating) : null
      };

      if (this.canSetPassword()) {
        const pwd = this.password.trim();
        if (pwd !== '') {
          if (pwd.length < 8) {
            this.saving.set(false);
            this.error.set('Password must be at least 8 characters');
            return;
          }
          payload['password'] = pwd;
        }
      }

      this.coaches.update(this.coachId, payload).subscribe({
        next: (res) => this.finishSave(res, 'Could not update coach'),
        error: (err: HttpErrorResponse) => this.failSave(err, 'Could not update coach')
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
        next: (res) => this.finishSave(res, 'Could not create coach'),
        error: (err: HttpErrorResponse) => this.failSave(err, 'Could not create coach')
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
