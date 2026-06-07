import { HttpClient } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { environment } from 'src/environments/environment';
import { ApiResponse, User, UserRole } from '../models/api.model';

export type StaffRole = Extract<UserRole, 'admin' | 'coach' | 'accountant'>;

export interface CreateStaffUserPayload {
  email: string;
  password: string;
  first_name: string;
  last_name: string;
  role: StaffRole;
  phone?: string | null;
  title?: string | null;
}

@Injectable({ providedIn: 'root' })
export class StaffUserService {
  private readonly http = inject(HttpClient);

  list(): Observable<ApiResponse<User[]>> {
    return this.http.get<ApiResponse<User[]>>(`${environment.apiUrl}/users`);
  }

  create(payload: CreateStaffUserPayload): Observable<ApiResponse<User>> {
    return this.http.post<ApiResponse<User>>(`${environment.apiUrl}/users`, payload);
  }

  updatePassword(userId: number, password: string): Observable<ApiResponse<User>> {
    return this.http.patch<ApiResponse<User>>(`${environment.apiUrl}/users/${userId}`, { password });
  }
}
