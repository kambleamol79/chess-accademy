import { HttpClient } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable, map } from 'rxjs';
import { environment } from 'src/environments/environment';
import { ApiResponse } from '../models/api.model';
import {
  ChessTournament,
  LiveMatchRevision,
  LiveMatchState,
  LiveMatchSummary
} from '../models/chess-arena.model';

@Injectable({ providedIn: 'root' })
export class ChessArenaService {
  private readonly http = inject(HttpClient);

  listTournaments(): Observable<ChessTournament[]> {
    return this.http
      .get<ApiResponse<{ tournaments: ChessTournament[] }>>(`${environment.apiUrl}/chess-tournaments`)
      .pipe(map((r) => r.data?.tournaments ?? []));
  }

  registerTournament(id: number): Observable<void> {
    return this.http
      .post<ApiResponse<unknown>>(`${environment.apiUrl}/chess-tournaments/${id}/register`, {})
      .pipe(map(() => undefined));
  }

  createTournament(payload: {
    title: string;
    description?: string;
    starts_at: string;
    time_control_minutes: number;
    status?: string;
  }): Observable<ChessTournament> {
    return this.http
      .post<ApiResponse<{ tournament: ChessTournament }>>(`${environment.apiUrl}/chess-tournaments`, payload)
      .pipe(map((r) => r.data!.tournament));
  }

  updateTournamentStatus(id: number, status: string): Observable<void> {
    return this.http
      .patch<ApiResponse<unknown>>(`${environment.apiUrl}/chess-tournaments/${id}`, { status })
      .pipe(map(() => undefined));
  }

  startTournamentRound(id: number): Observable<{ match_count: number }> {
    return this.http
      .post<ApiResponse<{ match_count: number }>>(`${environment.apiUrl}/chess-tournaments/${id}/start-round`, {})
      .pipe(map((r) => ({ match_count: r.data?.match_count ?? 0 })));
  }

  myMatches(): Observable<{ matches: LiveMatchSummary[]; active_match_id: number | null }> {
    return this.http
      .get<ApiResponse<{ matches: LiveMatchSummary[]; active_match_id: number | null }>>(
        `${environment.apiUrl}/live-matches/mine`
      )
      .pipe(map((r) => r.data ?? { matches: [], active_match_id: null }));
  }

  getMatch(id: number): Observable<LiveMatchState> {
    return this.http
      .get<ApiResponse<LiveMatchState>>(`${environment.apiUrl}/live-matches/${id}`)
      .pipe(map((r) => r.data!));
  }

  getRevision(id: number, sinceSeq: number): Observable<LiveMatchRevision> {
    return this.http
      .get<ApiResponse<LiveMatchRevision>>(`${environment.apiUrl}/live-matches/${id}/revision`, {
        params: { since: String(sinceSeq) }
      })
      .pipe(map((r) => r.data!));
  }

  playMove(
    matchId: number,
    payload: { uci: string; san: string; fen_after: string }
  ): Observable<LiveMatchState> {
    return this.http
      .post<ApiResponse<LiveMatchState>>(`${environment.apiUrl}/live-matches/${matchId}/moves`, payload)
      .pipe(map((r) => r.data!));
  }

  resign(matchId: number): Observable<LiveMatchState> {
    return this.http
      .post<ApiResponse<LiveMatchState>>(`${environment.apiUrl}/live-matches/${matchId}/resign`, {})
      .pipe(map((r) => r.data!));
  }

  joinQueue(tournamentId?: number, timeControlMinutes = 10): Observable<{ status: string; match_id?: number }> {
    const body: Record<string, unknown> = { time_control_minutes: timeControlMinutes };
    if (tournamentId != null) {
      body['tournament_id'] = tournamentId;
    }
    return this.http
      .post<ApiResponse<{ status: string; match_id?: number; match?: LiveMatchSummary }>>(
        `${environment.apiUrl}/live-matches/queue`,
        body
      )
      .pipe(
        map((r) => ({
          status: r.data?.status ?? 'waiting',
          match_id: r.data?.match_id ?? r.data?.match?.id
        }))
      );
  }

  leaveQueue(tournamentId?: number): Observable<void> {
    const body = tournamentId != null ? { tournament_id: tournamentId } : {};
    return this.http
      .delete<ApiResponse<unknown>>(`${environment.apiUrl}/live-matches/queue`, { body })
      .pipe(map(() => undefined));
  }
}
