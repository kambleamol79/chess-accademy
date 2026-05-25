import { HttpClient } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { environment } from 'src/environments/environment';
import { ApiResponse } from '../models/api.model';

@Injectable({ providedIn: 'root' })
export class MaterialService {
  private readonly http = inject(HttpClient);

  list(formId?: number): Observable<ApiResponse<Record<string, unknown>[]>> {
    const q = formId ? `?form_id=${formId}` : '';
    return this.http.get<ApiResponse<Record<string, unknown>[]>>(`${environment.apiUrl}/materials${q}`);
  }
}
