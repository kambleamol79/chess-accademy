import { Component, inject, OnDestroy, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, RouterLink } from '@angular/router';
import { CardComponent } from 'src/app/theme/shared/components/card/card.component';
import { ChessArenaService } from 'src/app/core/services/chess-arena.service';
import { ChessTournament, LiveMatchSummary } from 'src/app/core/models/chess-arena.model';

@Component({
  selector: 'app-chess-arena',
  imports: [CommonModule, CardComponent, RouterLink],
  templateUrl: './chess-arena.component.html',
  styleUrl: './chess-arena.component.scss'
})
export class ChessArenaComponent implements OnInit, OnDestroy {
  private readonly arena = inject(ChessArenaService);
  private readonly router = inject(Router);

  loading = signal(true);
  error = signal('');
  tournaments = signal<ChessTournament[]>([]);
  matches = signal<LiveMatchSummary[]>([]);
  finding = signal(false);
  queueMessage = signal('');

  private pollTimer: ReturnType<typeof setInterval> | null = null;

  ngOnInit(): void {
    this.reload();
  }

  ngOnDestroy(): void {
    this.stopQueuePoll();
    void this.arena.leaveQueue().subscribe();
  }

  reload(): void {
    this.loading.set(true);
    this.arena.listTournaments().subscribe({
      next: (t) => {
        this.tournaments.set(t.filter((x) => x.status !== 'finished' && x.status !== 'cancelled'));
        this.arena.myMatches().subscribe({
          next: (m) => {
            this.matches.set(m.matches);
            if (m.active_match_id) {
              void this.router.navigate(['/chess-arena/match', m.active_match_id]);
            }
            this.loading.set(false);
          },
          error: () => this.loading.set(false)
        });
      },
      error: () => {
        this.error.set('Could not load tournaments');
        this.loading.set(false);
      }
    });
  }

  register(t: ChessTournament): void {
    this.arena.registerTournament(t.id).subscribe({
      next: () => this.queueMessage.set(`Registered for ${t.title}`),
      error: () => this.error.set('Registration failed')
    });
  }

  findGame(tournamentId?: number, timeControl = 10): void {
    this.finding.set(true);
    this.error.set('');
    this.queueMessage.set('Looking for an opponent…');
    this.arena.joinQueue(tournamentId, timeControl).subscribe({
      next: (res) => {
        if (res.status === 'matched' && res.match_id) {
          this.finding.set(false);
          void this.router.navigate(['/chess-arena/match', res.match_id]);
          return;
        }
        this.startQueuePoll(tournamentId, timeControl);
      },
      error: () => {
        this.finding.set(false);
        this.error.set('Could not join matchmaking');
      }
    });
  }

  cancelFind(): void {
    this.stopQueuePoll();
    this.finding.set(false);
    this.queueMessage.set('');
    this.arena.leaveQueue().subscribe();
  }

  private startQueuePoll(tournamentId?: number, timeControl = 10): void {
    this.stopQueuePoll();
    this.pollTimer = setInterval(() => {
      this.arena.joinQueue(tournamentId, timeControl).subscribe({
        next: (res) => {
          if (res.status === 'matched' && res.match_id) {
            this.stopQueuePoll();
            this.finding.set(false);
            void this.router.navigate(['/chess-arena/match', res.match_id]);
          }
        }
      });
    }, 2500);
  }

  private stopQueuePoll(): void {
    if (this.pollTimer) {
      clearInterval(this.pollTimer);
      this.pollTimer = null;
    }
  }
}
