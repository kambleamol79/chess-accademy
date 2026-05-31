import { HttpClient } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable, map } from 'rxjs';
import { environment } from 'src/environments/environment';
import { ApiResponse } from '../models/api.model';
import { CreateGamePayload, ReviewGame, reviewGameFromApi } from '../models/game.model';

@Injectable({ providedIn: 'root' })
export class GameService {
  private readonly http = inject(HttpClient);

  list(studentId?: number): Observable<ApiResponse<ReviewGame[]>> {
    const url =
      studentId != null
        ? `${environment.apiUrl}/games?student_id=${studentId}`
        : `${environment.apiUrl}/games`;
    return this.http.get<ApiResponse<Record<string, unknown>[]>>(url).pipe(
      map((res) => ({
        ...res,
        data: (res.data ?? []).map(reviewGameFromApi)
      }))
    );
  }

  get(id: number): Observable<ApiResponse<ReviewGame>> {
    return this.http.get<ApiResponse<Record<string, unknown>>>(`${environment.apiUrl}/games/${id}`).pipe(
      map((res) => ({
        ...res,
        data: reviewGameFromApi(res.data ?? {})
      }))
    );
  }

  create(payload: CreateGamePayload): Observable<ApiResponse<ReviewGame>> {
    return this.http.post<ApiResponse<Record<string, unknown>>>(`${environment.apiUrl}/games`, payload).pipe(
      map((res) => ({
        ...res,
        data: reviewGameFromApi(res.data ?? {})
      }))
    );
  }

  delete(id: number): Observable<ApiResponse<unknown>> {
    return this.http.delete<ApiResponse<unknown>>(`${environment.apiUrl}/games/${id}`);
  }
}
