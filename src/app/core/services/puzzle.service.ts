import { HttpClient, HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable, map } from 'rxjs';
import { environment } from 'src/environments/environment';
import { ApiResponse } from '../models/api.model';
import { ChessPuzzle, PuzzleDifficulty, puzzleFromApi } from '../models/puzzle.model';

@Injectable({ providedIn: 'root' })
export class PuzzleService {
  private readonly http = inject(HttpClient);

  list(difficulty?: PuzzleDifficulty): Observable<ApiResponse<ChessPuzzle[]>> {
    let params = new HttpParams();
    if (difficulty) {
      params = params.set('difficulty', difficulty);
    }
    return this.http
      .get<ApiResponse<Record<string, unknown>[]>>(`${environment.apiUrl}/puzzles`, { params })
      .pipe(
        map((res) => ({
          ...res,
          data: (res.data ?? []).map(puzzleFromApi)
        }))
      );
  }

  next(difficulty: PuzzleDifficulty, excludeId?: number): Observable<ApiResponse<{ puzzle: ChessPuzzle }>> {
    let params = new HttpParams().set('difficulty', difficulty);
    if (excludeId != null) {
      params = params.set('exclude', String(excludeId));
    }
    return this.http
      .get<ApiResponse<{ puzzle: Record<string, unknown> }>>(`${environment.apiUrl}/puzzles/next`, { params })
      .pipe(
        map((res) => ({
          ...res,
          data: { puzzle: puzzleFromApi(res.data?.puzzle ?? {}) }
        }))
      );
  }

  show(id: number): Observable<ApiResponse<ChessPuzzle>> {
    return this.http
      .get<ApiResponse<Record<string, unknown>>>(`${environment.apiUrl}/puzzles/${id}`)
      .pipe(map((res) => ({ ...res, data: puzzleFromApi(res.data ?? {}) })));
  }

  attempt(puzzleId: number, isCorrect: boolean, studentId?: number): Observable<ApiResponse<{ is_correct: boolean }>> {
    const body: Record<string, unknown> = { is_correct: isCorrect };
    if (studentId != null) {
      body['student_id'] = studentId;
    }
    return this.http.post<ApiResponse<{ is_correct: boolean }>>(
      `${environment.apiUrl}/puzzles/${puzzleId}/attempt`,
      body
    );
  }

  delete(id: number): Observable<ApiResponse<unknown>> {
    return this.http.delete<ApiResponse<unknown>>(`${environment.apiUrl}/puzzles/${id}`);
  }
}
