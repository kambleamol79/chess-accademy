import { Component, inject, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { CardComponent } from 'src/app/theme/shared/components/card/card.component';
import { ChessArenaService } from 'src/app/core/services/chess-arena.service';
import { ChessTournament } from 'src/app/core/models/chess-arena.model';

@Component({
  selector: 'app-chess-tournaments',
  imports: [CommonModule, FormsModule, CardComponent],
  templateUrl: './chess-tournaments.component.html',
  styleUrl: './chess-tournaments.component.scss'
})
export class ChessTournamentsComponent implements OnInit {
  private readonly arena = inject(ChessArenaService);

  loading = signal(true);
  message = signal('');
  tournaments = signal<ChessTournament[]>([]);

  title = '';
  description = '';
  startsAt = '';
  timeControl = 10;

  ngOnInit(): void {
    this.reload();
  }

  reload(): void {
    this.loading.set(true);
    this.arena.listTournaments().subscribe({
      next: (t) => {
        this.tournaments.set(t);
        this.loading.set(false);
      },
      error: () => this.loading.set(false)
    });
  }

  create(): void {
    if (!this.title.trim() || !this.startsAt) {
      this.message.set('Title and start time are required');
      return;
    }
    this.arena
      .createTournament({
        title: this.title.trim(),
        description: this.description.trim() || undefined,
        starts_at: new Date(this.startsAt).toISOString().slice(0, 19).replace('T', ' '),
        time_control_minutes: this.timeControl,
        status: 'registration'
      })
      .subscribe({
        next: () => {
          this.message.set('Tournament created');
          this.title = '';
          this.description = '';
          this.reload();
        },
        error: () => this.message.set('Could not create tournament')
      });
  }

  setStatus(t: ChessTournament, status: string): void {
    this.arena.updateTournamentStatus(t.id, status).subscribe({
      next: () => this.reload(),
      error: () => this.message.set('Update failed')
    });
  }

  startRound(t: ChessTournament): void {
    this.arena.startTournamentRound(t.id).subscribe({
      next: (r) => this.message.set(`Started round — ${r.match_count} pairings created`),
      error: () => this.message.set('Could not start round (need at least 2 registered players)')
    });
  }
}
