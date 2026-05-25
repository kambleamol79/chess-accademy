import { Component, inject, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { CardComponent } from 'src/app/theme/shared/components/card/card.component';
import { CoachService } from 'src/app/core/services/coach.service';
import { AuthService } from 'src/app/core/services/auth.service';
import { CoachFormModalComponent } from './coach-form-modal.component';

@Component({
  selector: 'app-coaches',
  imports: [CommonModule, CardComponent],
  templateUrl: './coaches.component.html',
  styleUrl: './coaches.component.scss'
})
export class CoachesComponent implements OnInit {
  private readonly coaches = inject(CoachService);
  private readonly modal = inject(NgbModal);
  readonly auth = inject(AuthService);

  loading = signal(true);
  error = signal('');
  rows = signal<Record<string, unknown>[]>([]);

  ngOnInit() {
    this.load();
  }

  canAddCoach(): boolean {
    return this.auth.hasRole(['admin']);
  }

  load() {
    this.loading.set(true);
    this.coaches.list().subscribe({
      next: (res) => {
        this.rows.set(res.data);
        this.loading.set(false);
        this.error.set('');
      },
      error: () => {
        this.error.set('Failed to load coaches');
        this.loading.set(false);
      }
    });
  }

  openAddCoach() {
    const ref = this.modal.open(CoachFormModalComponent, {
      size: 'lg',
      centered: true,
      backdrop: 'static'
    });

    ref.closed.subscribe(() => this.load());
  }
}
