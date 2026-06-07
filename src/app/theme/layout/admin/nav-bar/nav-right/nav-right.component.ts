import { Component, computed, inject } from '@angular/core';
import { RouterModule } from '@angular/router';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { SharedModule } from 'src/app/theme/shared/shared.module';
import { AuthService } from 'src/app/core/services/auth.service';
import { CoachProfileModalComponent } from 'src/app/features/coaches/coach-profile-modal.component';
import { environment } from 'src/environments/environment';

@Component({
  selector: 'app-nav-right',
  imports: [SharedModule, RouterModule],
  templateUrl: './nav-right.component.html',
  styleUrl: './nav-right.component.scss'
})
export class NavRightComponent {
  readonly auth = inject(AuthService);
  private readonly modal = inject(NgbModal);

  readonly isStudent = computed(() => this.auth.role() === 'student');
  readonly todayTournamentUrl = environment.todayTournamentUrl;

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
