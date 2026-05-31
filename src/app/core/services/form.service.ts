import { HttpClient } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { environment } from 'src/environments/environment';
import { ApiResponse } from '../models/api.model';
import { BatchForm } from '../models/form.model';
import { ZoomJoinSignature } from '../models/zoom.model';

@Injectable({ providedIn: 'root' })
export class FormService {
  private readonly http = inject(HttpClient);

  list(): Observable<ApiResponse<BatchForm[]>> {
    return this.http.get<ApiResponse<BatchForm[]>>(`${environment.apiUrl}/forms`);
  }

  nextBatch(): Observable<ApiResponse<{ batch: string }>> {
    return this.http.get<ApiResponse<{ batch: string }>>(`${environment.apiUrl}/forms/next-batch`);
  }

  create(payload: Partial<BatchForm>): Observable<ApiResponse<BatchForm>> {
    return this.http.post<ApiResponse<BatchForm>>(`${environment.apiUrl}/forms`, payload);
  }

  update(id: number, payload: Partial<BatchForm>): Observable<ApiResponse<BatchForm>> {
    return this.http.patch<ApiResponse<BatchForm>>(`${environment.apiUrl}/forms/${id}`, payload);
  }

  delete(id: number): Observable<ApiResponse<unknown>> {
    return this.http.delete<ApiResponse<unknown>>(`${environment.apiUrl}/forms/${id}`);
  }

  zoomSignature(id: number): Observable<ApiResponse<ZoomJoinSignature>> {
    return this.http.get<ApiResponse<ZoomJoinSignature>>(`${environment.apiUrl}/forms/${id}/zoom/signature`);
  }
}
