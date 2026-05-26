import { HttpClient } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { environment } from 'src/environments/environment';
import { ApiResponse } from '../models/api.model';
import { CoachSchedulePayload } from './coach.service';

export interface DashboardMetrics {
  total_students: number;
  coaches_count: number;
  active_batches: number;
  active_enrollments: number;
  revenue_this_month: number;
  pending_invoices: number;
  puzzles_solved_week: number;
  upcoming_batches: Array<Record<string, unknown>>;
  enrollment_by_batch: Array<{ batch: string; enrolled: number }>;
  revenue_by_month: Array<{ month: string; amount: number }>;
  invoice_by_status: Array<{ status: string; count: number }>;
}

export interface DashboardStatCard {
  label: string;
  value: string;
  icon: string;
  cardClass: string;
  iconClass: string;
}

@Injectable({ providedIn: 'root' })
export class DashboardService {
  private readonly http = inject(HttpClient);

  getMetrics(): Observable<ApiResponse<DashboardMetrics>> {
    return this.http.get<ApiResponse<DashboardMetrics>>(`${environment.apiUrl}/dashboard/metrics`);
  }

  getCoachSchedule(): Observable<ApiResponse<CoachSchedulePayload>> {
    return this.http.get<ApiResponse<CoachSchedulePayload>>(`${environment.apiUrl}/dashboard/coach-schedule`);
  }
}
