import { HttpClient } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { environment } from 'src/environments/environment';
import { ApiResponse } from '../models/api.model';

@Injectable({ providedIn: 'root' })
export class BillingService {
  private readonly http = inject(HttpClient);

  list(): Observable<ApiResponse<Record<string, unknown>[]>> {
    return this.http.get<ApiResponse<Record<string, unknown>[]>>(`${environment.apiUrl}/billing/invoices`);
  }

  update(id: number, payload: Record<string, unknown>): Observable<ApiResponse<unknown>> {
    return this.http.patch<ApiResponse<unknown>>(`${environment.apiUrl}/billing/invoices/${id}`, payload);
  }

  markPaid(id: number): Observable<ApiResponse<unknown>> {
    return this.http.patch<ApiResponse<unknown>>(`${environment.apiUrl}/billing/invoices/${id}/pay`, {});
  }

  delete(id: number): Observable<ApiResponse<unknown>> {
    return this.http.delete<ApiResponse<unknown>>(`${environment.apiUrl}/billing/invoices/${id}`);
  }
}
