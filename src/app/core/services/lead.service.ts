import { HttpClient } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { environment } from 'src/environments/environment';
import { ApiResponse } from '../models/api.model';

@Injectable({ providedIn: 'root' })
export class LeadService {
  private readonly http = inject(HttpClient);

  list(): Observable<ApiResponse<Record<string, unknown>[]>> {
    return this.http.get<ApiResponse<Record<string, unknown>[]>>(`${environment.apiUrl}/leads`);
  }

  create(payload: Record<string, unknown>): Observable<ApiResponse<unknown>> {
    return this.http.post<ApiResponse<unknown>>(`${environment.apiUrl}/leads`, payload);
  }

  update(id: number, payload: Record<string, unknown>): Observable<ApiResponse<unknown>> {
    return this.http.put<ApiResponse<unknown>>(`${environment.apiUrl}/leads/${id}`, payload);
  }

  delete(id: number): Observable<ApiResponse<unknown>> {
    return this.http.delete<ApiResponse<unknown>>(`${environment.apiUrl}/leads/${id}`);
  }

  bulkUpload(payload: { csv: string } | { leads: Record<string, unknown>[] }): Observable<
    ApiResponse<{ created: number; skipped: number; errors: { row: number; message: string }[] }>
  > {
    return this.http.post<
      ApiResponse<{ created: number; skipped: number; errors: { row: number; message: string }[] }>
    >(`${environment.apiUrl}/leads/bulk`, payload);
  }
}
