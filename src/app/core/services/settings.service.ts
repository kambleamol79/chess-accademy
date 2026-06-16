import { HttpClient } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable, map } from 'rxjs';
import { environment } from 'src/environments/environment';
import { ApiResponse } from '../models/api.model';

export interface TournamentCta {
  url: string;
  label: string;
  timezone: string;
  visible_from: string | null;
  visible_until: string | null;
  visible: boolean;
}

export const TOURNAMENT_SETTING_KEYS = {
  url: 'today_tournament_url',
  label: 'today_tournament_label',
  timezone: 'today_tournament_timezone',
  visibleFrom: 'today_tournament_visible_from',
  visibleUntil: 'today_tournament_visible_until'
} as const;

export const TOURNAMENT_TIMEZONE_OPTIONS = [
  'Asia/Kolkata',
  'Asia/Dubai',
  'Asia/Singapore',
  'Europe/London',
  'America/New_York',
  'America/Chicago',
  'America/Los_Angeles',
  'UTC'
] as const;

@Injectable({ providedIn: 'root' })
export class SettingsService {
  private readonly http = inject(HttpClient);

  getTournamentCta(): Observable<TournamentCta> {
    return this.http
      .get<ApiResponse<TournamentCta>>(`${environment.apiUrl}/settings/tournament-cta`)
      .pipe(map((res) => res.data ?? {
        url: '',
        label: '',
        timezone: 'Asia/Kolkata',
        visible_from: null,
        visible_until: null,
        visible: false
      }));
  }

  list(): Observable<Record<string, unknown>> {
    return this.http
      .get<ApiResponse<Record<string, unknown>>>(`${environment.apiUrl}/settings`)
      .pipe(map((res) => res.data ?? {}));
  }

  update(payload: Record<string, unknown>): Observable<Record<string, unknown>> {
    return this.http
      .patch<ApiResponse<Record<string, unknown>>>(`${environment.apiUrl}/settings`, payload)
      .pipe(map((res) => res.data ?? {}));
  }
}
