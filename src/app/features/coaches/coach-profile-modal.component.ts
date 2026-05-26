import { Component, inject, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { NgbActiveModal } from '@ng-bootstrap/ng-bootstrap';
import { HttpErrorResponse } from '@angular/common/http';
import { CoachService } from 'src/app/core/services/coach.service';
import { AuthService } from 'src/app/core/services/auth.service';
import { getApiErrorMessage } from 'src/app/core/utils/http-error.util';

@Component({
  selector: 'app-coach-profile-modal',
  imports: [CommonModule, FormsModule],
  templateUrl: './coach-profile-modal.component.html',
  styleUrl: './coach-profile-modal.component.scss'
})
export class CoachProfileModalComponent implements OnInit {
  private readonly activeModal = inject(NgbActiveModal);
  private readonly coaches = inject(CoachService);
  private readonly auth = inject(AuthService);

  loading = signal(true);
  saving = signal(false);
  error = signal('');

  email = '';
  first_name = '';
  last_name = '';
  phone = '';
  title = '';
  bio = '';
  rating: number | null = null;

  ngOnInit() {
    this.coaches.me().subscribe({
      next: (res) => {
        const coach = res.data ?? {};
        this.email = String(coach['email'] ?? '');
        this.first_name = String(coach['first_name'] ?? '');
        this.last_name = String(coach['last_name'] ?? '');
        this.phone = String(coach['phone'] ?? '');
        this.title = String(coach['title'] ?? '');
        this.bio = String(coach['bio'] ?? '');
        this.rating = coach['rating'] != null ? Number(coach['rating']) : null;
        this.loading.set(false);
        this.error.set('');
      },
      error: (err: HttpErrorResponse) => {
        this.loading.set(false);
        this.error.set(getApiErrorMessage(err, 'Could not load profile'));
      }
    });
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

    this.saving.set(true);
    this.coaches
      .updateMe({
        first_name: this.first_name.trim(),
        last_name: this.last_name.trim(),
        phone: this.phone.trim() || null,
        title: this.title.trim() || null,
        bio: this.bio.trim() || null,
        rating: this.rating !== null && this.rating !== undefined ? Number(this.rating) : null
      })
      .subscribe({
        next: (res) => {
          if (!res.success) {
            this.saving.set(false);
            this.error.set(res.message ?? 'Could not update profile');
            return;
          }
          this.auth.refreshUser().subscribe({
            next: () => {
              this.saving.set(false);
              this.activeModal.close(res.data);
            },
            error: () => {
              this.saving.set(false);
              this.activeModal.close(res.data);
            }
          });
        },
        error: (err: HttpErrorResponse) => {
          this.saving.set(false);
          this.error.set(getApiErrorMessage(err, 'Could not update profile'));
        }
      });
  }
}
