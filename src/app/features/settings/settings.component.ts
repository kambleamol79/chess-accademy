import { Component, computed, inject, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { CardComponent } from 'src/app/theme/shared/components/card/card.component';
import { environment } from 'src/environments/environment';
import { User, UserRole } from 'src/app/core/models/api.model';
import { SettingsService, TOURNAMENT_SETTING_KEYS, TOURNAMENT_TIMEZONE_OPTIONS } from 'src/app/core/services/settings.service';
import { StaffUserService } from 'src/app/core/services/staff-user.service';
import { StaffUserFormModalComponent } from './staff-user-form-modal.component';
import { StaffPasswordModalComponent } from './staff-password-modal.component';
import { HttpErrorResponse } from '@angular/common/http';
import { getApiErrorMessage } from 'src/app/core/utils/http-error.util';
import { normalizeVisibleDate } from 'src/app/core/utils/tournament-visibility.util';

const ROLE_LABELS: Record<string, string> = {
  admin: 'Admin',
  coach: 'Coach',
  accountant: 'Accountant'
};

@Component({
  selector: 'app-settings',
  imports: [CommonModule, FormsModule, CardComponent],
  templateUrl: './settings.component.html',
  styleUrl: './settings.component.scss'
})
export class SettingsComponent implements OnInit {
  private readonly settingsService = inject(SettingsService);
  private readonly staffUsers = inject(StaffUserService);
  private readonly modal = inject(NgbModal);

  loading = signal(true);
  staffLoading = signal(true);
  settings = signal<Record<string, unknown>>({});
  staffRows = signal<User[]>([]);
  staffError = signal('');
  staffSuccess = signal('');
  tournamentUrl = '';
  tournamentLabel = '';
  tournamentTimezone = 'Asia/Kolkata';
  tournamentVisibleFrom = '';
  tournamentVisibleUntil = '';
  tournamentSaving = signal(false);
  tournamentMessage = signal('');
  tournamentError = signal('');

  readonly roleLabels = ROLE_LABELS;
  readonly timezoneOptions = TOURNAMENT_TIMEZONE_OPTIONS;
  readonly otherSettings = computed(() => {
    const hidden = new Set<string>(Object.values(TOURNAMENT_SETTING_KEYS));
    return Object.entries(this.settings()).filter(([key]) => !hidden.has(key));
  });

  ngOnInit() {
    this.loadSettings();
    this.loadStaff();
  }

  loadSettings() {
    this.settingsService.list().subscribe({
      next: (data) => {
        this.settings.set(data);
        this.tournamentUrl = String(data[TOURNAMENT_SETTING_KEYS.url] ?? environment.todayTournamentUrl);
        this.tournamentLabel = String(data[TOURNAMENT_SETTING_KEYS.label] ?? "Today's tournament");
        this.tournamentTimezone = String(
          data[TOURNAMENT_SETTING_KEYS.timezone] ?? data['timezone'] ?? 'Asia/Kolkata'
        );
        this.tournamentVisibleFrom = normalizeVisibleDate(data[TOURNAMENT_SETTING_KEYS.visibleFrom]);
        this.tournamentVisibleUntil = normalizeVisibleDate(data[TOURNAMENT_SETTING_KEYS.visibleUntil]);
        this.loading.set(false);
      },
      error: () => this.loading.set(false)
    });
  }

  saveTournamentCta(): void {
    this.tournamentSaving.set(true);
    this.tournamentMessage.set('');
    this.tournamentError.set('');

    this.settingsService
      .update({
        [TOURNAMENT_SETTING_KEYS.url]: this.tournamentUrl.trim(),
        [TOURNAMENT_SETTING_KEYS.label]: this.tournamentLabel.trim() || "Today's tournament",
        [TOURNAMENT_SETTING_KEYS.timezone]: this.tournamentTimezone,
        [TOURNAMENT_SETTING_KEYS.visibleFrom]: this.tournamentVisibleFrom.trim(),
        [TOURNAMENT_SETTING_KEYS.visibleUntil]: this.tournamentVisibleUntil.trim()
      })
      .subscribe({
        next: (data) => {
          this.settings.set(data);
          this.tournamentSaving.set(false);
          this.tournamentMessage.set('Student tournament link updated.');
        },
        error: (err: HttpErrorResponse) => {
          this.tournamentSaving.set(false);
          this.tournamentError.set(getApiErrorMessage(err, 'Could not save tournament settings'));
        }
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
