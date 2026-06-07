import { Component, inject, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { CardComponent } from 'src/app/theme/shared/components/card/card.component';
import { environment } from 'src/environments/environment';
import { ApiResponse, User, UserRole } from 'src/app/core/models/api.model';
import { StaffUserService } from 'src/app/core/services/staff-user.service';
import { StaffUserFormModalComponent } from './staff-user-form-modal.component';
import { StaffPasswordModalComponent } from './staff-password-modal.component';
import { HttpErrorResponse } from '@angular/common/http';
import { getApiErrorMessage } from 'src/app/core/utils/http-error.util';

const ROLE_LABELS: Record<string, string> = {
  admin: 'Admin',
  coach: 'Coach',
  accountant: 'Accountant'
};

@Component({
  selector: 'app-settings',
  imports: [CommonModule, CardComponent],
  templateUrl: './settings.component.html',
  styleUrl: './settings.component.scss'
})
export class SettingsComponent implements OnInit {
  private readonly http = inject(HttpClient);
  private readonly staffUsers = inject(StaffUserService);
  private readonly modal = inject(NgbModal);

  loading = signal(true);
  staffLoading = signal(true);
  settings = signal<Record<string, unknown>>({});
  staffRows = signal<User[]>([]);
  staffError = signal('');
  staffSuccess = signal('');

  readonly roleLabels = ROLE_LABELS;

  ngOnInit() {
    this.loadSettings();
    this.loadStaff();
  }

  loadSettings() {
    this.http.get<ApiResponse<Record<string, unknown>>>(`${environment.apiUrl}/settings`).subscribe({
      next: (res) => {
        this.settings.set(res.data ?? {});
        this.loading.set(false);
      },
      error: () => this.loading.set(false)
    });
  }

  loadStaff() {
    this.staffLoading.set(true);
    this.staffUsers.list().subscribe({
      next: (res) => {
        this.staffRows.set(res.data ?? []);
        this.staffLoading.set(false);
        this.staffError.set('');
      },
      error: (err: HttpErrorResponse) => {
        this.staffLoading.set(false);
        this.staffError.set(getApiErrorMessage(err, 'Failed to load staff accounts'));
      }
    });
  }

  staffName(row: User): string {
    return `${row.first_name} ${row.last_name}`.trim();
  }

  roleLabel(role: UserRole): string {
    return ROLE_LABELS[role] ?? role;
  }

  roleBadgeClass(role: UserRole): string {
    switch (role) {
      case 'admin':
        return 'bg-primary';
      case 'coach':
        return 'bg-success';
      case 'accountant':
        return 'bg-info text-dark';
      default:
        return 'bg-secondary';
    }
  }

  openAddStaff() {
    const ref = this.modal.open(StaffUserFormModalComponent, {
      size: 'lg',
      centered: true,
      backdrop: 'static'
    });
    ref.closed.subscribe(() => {
      this.staffSuccess.set('Staff account created.');
      this.loadStaff();
    });
  }

  openChangePassword(row: User) {
    const ref = this.modal.open(StaffPasswordModalComponent, {
      size: 'md',
      centered: true,
      backdrop: 'static'
    });
    ref.componentInstance.staff = row;
    ref.closed.subscribe(() => {
      this.staffSuccess.set(`Password updated for ${this.staffName(row)}.`);
    });
  }
}
