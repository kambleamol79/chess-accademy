import { Component, computed, inject, OnDestroy, OnInit, signal } from '@angular/core';
import { RouterModule } from '@angular/router';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { SharedModule } from 'src/app/theme/shared/shared.module';
import { AuthService } from 'src/app/core/services/auth.service';
import { SettingsService, TournamentCta } from 'src/app/core/services/settings.service';
import { isTournamentVisibleNow } from 'src/app/core/utils/tournament-visibility.util';
import { CoachProfileModalComponent } from 'src/app/features/coaches/coach-profile-modal.component';
import { environment } from 'src/environments/environment';

@Component({
  selector: 'app-nav-right',
  imports: [SharedModule, RouterModule],
  templateUrl: './nav-right.component.html',
  styleUrl: './nav-right.component.scss'
})
export class NavRightComponent implements OnInit, OnDestroy {
  readonly auth = inject(AuthService);
  private readonly modal = inject(NgbModal);
  private readonly settings = inject(SettingsService);

  readonly isStudent = computed(() => this.auth.role() === 'student');
  private readonly tournamentConfig = signal<TournamentCta | null>(null);
  private readonly visibilityTick = signal(0);
  private visibilityTimer?: ReturnType<typeof setInterval>;

  readonly tournamentCta = computed(() => {
    this.visibilityTick();
    const config = this.tournamentConfig();
    if (!config?.url?.trim()) {
      return null;
    }
    if (!isTournamentVisibleNow(config)) {
      return null;
    }
    return config;
  });

  ngOnInit(): void {
    if (!this.isStudent()) {
      return;
    }

    this.loadTournamentCta();
    this.visibilityTimer = setInterval(() => this.visibilityTick.update((n) => n + 1), 30_000);
  }

  ngOnDestroy(): void {
    if (this.visibilityTimer) {
      clearInterval(this.visibilityTimer);
    }
  }

  private loadTournamentCta(): void {
    this.settings.getTournamentCta().subscribe({
      next: (cta) => {
        const url = cta.url.trim();
        if (!url) {
          return;
        }
        this.tournamentConfig.set({
          ...cta,
          url,
          label: cta.label.trim() || "Today's tournament"
        });
      },
      error: () => {
        this.tournamentConfig.set({
          url: environment.todayTournamentUrl,
          label: "Today's tournament",
          timezone: 'Asia/Kolkata',
          visible_from: null,
          visible_until: null,
          visible: true
        });
      }
    });
  }

  canEditProfile(): boolean {
    return this.auth.hasRole(['coach']);
  }

  openProfile() {
    this.modal.open(CoachProfileModalComponent, {
      size: 'lg',
      centered: true,
      backdrop: 'static'
    });
  }

  logout(): void {
    this.auth.logout();
  }
}
