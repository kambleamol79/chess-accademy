import { HttpClient } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { environment } from 'src/environments/environment';
import { ApiResponse } from '../models/api.model';

@Injectable({ providedIn: 'root' })
export class CoachService {
  private readonly http = inject(HttpClient);

  list(): Observable<ApiResponse<Record<string, unknown>[]>> {
    return this.http.get<ApiResponse<Record<string, unknown>[]>>(`${environment.apiUrl}/coaches`);
  }

  create(payload: Record<string, unknown>): Observable<ApiResponse<unknown>> {
    return this.http.post<ApiResponse<unknown>>(`${environment.apiUrl}/coaches`, payload);
  }

  update(id: number, payload: Record<string, unknown>): Observable<ApiResponse<unknown>> {
    return this.http.patch<ApiResponse<unknown>>(`${environment.apiUrl}/coaches/${id}`, payload);
  }

  delete(id: number): Observable<ApiResponse<unknown>> {
    return this.http.delete<ApiResponse<unknown>>(`${environment.apiUrl}/coaches/${id}`);
  }

  schedule(id: number): Observable<ApiResponse<CoachSchedulePayload>> {
    return this.http.get<ApiResponse<CoachSchedulePayload>>(`${environment.apiUrl}/coaches/${id}/schedule`);
  }

  me(): Observable<ApiResponse<Record<string, unknown>>> {
    return this.http.get<ApiResponse<Record<string, unknown>>>(`${environment.apiUrl}/coaches/me`);
  }

  updateMe(payload: Record<string, unknown>): Observable<ApiResponse<Record<string, unknown>>> {
    return this.http.patch<ApiResponse<Record<string, unknown>>>(`${environment.apiUrl}/coaches/me`, payload);
  }
}

export interface CoachScheduleAssignment {
  form_id: number;
  batch: string;
  module: string | null;
  time: string;
  day: string;
  highlight: 'blue' | 'beige';
  label: string;
  is_practice: boolean;
  slot: 'coach_1' | 'coach_2';
  days_summary: string;
}

export interface CoachSchedulePayload {
  coach: {
    id: number;
    first_name: string;
    last_name: string;
    display_name: string;
  };
  days: string[];
  time_slots: string[];
  assignments: CoachScheduleAssignment[];
}
