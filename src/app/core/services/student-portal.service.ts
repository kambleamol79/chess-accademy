import { HttpClient } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { environment } from 'src/environments/environment';
import { ApiResponse } from '../models/api.model';
import { StudentBatch, StudentReminder } from '../models/student-portal.model';

@Injectable({ providedIn: 'root' })
export class StudentPortalService {
  private readonly http = inject(HttpClient);

  getMyBatch(): Observable<ApiResponse<{ batch: StudentBatch | null }>> {
    return this.http.get<ApiResponse<{ batch: StudentBatch | null }>>(`${environment.apiUrl}/students/me/batch`);
  }

  getReminders(): Observable<ApiResponse<{ reminders: StudentReminder[] }>> {
    return this.http.get<ApiResponse<{ reminders: StudentReminder[] }>>(`${environment.apiUrl}/students/me/reminders`);
  }
}
