import { HttpClient } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable, map } from 'rxjs';
import { environment } from 'src/environments/environment';
import { ApiResponse } from '../models/api.model';
import {
  PracticeSessionDetail,
  PracticeSessionResult,
  PracticeSessionSummary,
  practiceMoveFromApi,
  practiceSessionFromApi
} from '../models/practice-session.model';
import { PracticeGameMove } from '../models/chess-practice.model';
import { ComputerLevel, GameTimeControl, PlayerColor, PracticeMode } from '../models/chess-practice.model';

@Injectable({ providedIn: 'root' })
export class PracticeSessionService {
  private readonly http = inject(HttpClient);
  private readonly base = `${environment.apiUrl}/practice-sessions`;

  list(limit = 30): Observable<PracticeSessionSummary[]> {
    return this.http
      .get<ApiResponse<{ sessions: Record<string, unknown>[] }>>(this.base, {
        params: { limit: String(limit) }
      })
      .pipe(map((res) => (res.data?.sessions ?? []).map(practiceSessionFromApi)));
  }

  get(id: number): Observable<PracticeSessionDetail> {
    return this.http.get<ApiResponse<Record<string, unknown>>>(`${this.base}/${id}`).pipe(
      map((res) => {
        const data = res.data ?? {};
        const session = practiceSessionFromApi((data['session'] as Record<string, unknown>) ?? data);
        const moves = ((data['moves'] as Record<string, unknown>[]) ?? []).map(practiceMoveFromApi);
        return { session, moves };
      })
    );
  }

  create(payload: {
    mode: PracticeMode;
    level?: ComputerLevel;
    playerColor: PlayerColor;
    timeControlMinutes: GameTimeControl;
    startFen: string;
  }): Observable<PracticeSessionSummary> {
    return this.http
      .post<ApiResponse<{ session: Record<string, unknown> }>>(this.base, {
        mode: payload.mode === 'vsComputer' ? 'vs_computer' : 'free_play',
        level: payload.level ?? null,
        player_color: payload.playerColor,
        time_control_minutes: payload.timeControlMinutes,
        start_fen: payload.startFen
      })
      .pipe(map((res) => practiceSessionFromApi(res.data?.session ?? {})));
  }

  addMove(sessionId: number, move: PracticeGameMove): Observable<void> {
    return this.http
      .post<ApiResponse<unknown>>(`${this.base}/${sessionId}/moves`, {
        ply: move.ply,
        san: move.san,
        uci: move.uci,
        color: move.color,
        player: move.player,
        fen_after: move.fenAfter
      })
      .pipe(map(() => undefined));
  }

  deleteLastMove(sessionId: number): Observable<void> {
    return this.http
      .delete<ApiResponse<unknown>>(`${this.base}/${sessionId}/moves/last`)
      .pipe(map(() => undefined));
  }

  finalize(sessionId: number, result: PracticeSessionResult): Observable<void> {
    return this.http
      .patch<ApiResponse<unknown>>(`${this.base}/${sessionId}`, { result })
      .pipe(map(() => undefined));
  }
}
