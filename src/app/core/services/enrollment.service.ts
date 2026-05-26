import { HttpClient } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { environment } from 'src/environments/environment';
import { ApiResponse } from '../models/api.model';

export interface BulkAssignResult {
  created: number;
  skipped: Array<{ student_id: number; reason: string }>;
}

@Injectable({ providedIn: 'root' })
export class EnrollmentService {
  private readonly http = inject(HttpClient);

  bulkAssign(formId: number, studentIds: number[]): Observable<ApiResponse<BulkAssignResult>> {
    return this.http.post<ApiResponse<BulkAssignResult>>(`${environment.apiUrl}/enrollments/bulk-assign`, {
      form_id: formId,
      student_ids: studentIds
    });
  }
}
