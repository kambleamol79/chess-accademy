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
}
