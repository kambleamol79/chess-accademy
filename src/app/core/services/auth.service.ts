import { HttpClient } from '@angular/common/http';
import { Injectable, computed, inject, signal } from '@angular/core';
import { Router } from '@angular/router';
import { Observable, tap } from 'rxjs';
import { environment } from 'src/environments/environment';
import { ApiResponse, AuthTokens, User, UserRole } from '../models/api.model';

@Injectable({ providedIn: 'root' })
export class AuthService {
  private readonly http = inject(HttpClient);
  private readonly router = inject(Router);

  private readonly userSignal = signal<User | null>(this.loadUser());

  readonly user = this.userSignal.asReadonly();
  readonly isLoggedIn = computed(() => this.userSignal() !== null);
  readonly role = computed(() => this.userSignal()?.role ?? null);

  login(email: string, password: string): Observable<ApiResponse<AuthTokens>> {
    return this.http.post<ApiResponse<AuthTokens>>(`${environment.apiUrl}/auth/login`, { email, password }).pipe(
      tap((res) => {
        if (res.success && res.data?.access_token) {
          this.persistSession(res.data);
        }
      })
    );
  }

  register(payload: Record<string, unknown>): Observable<ApiResponse<AuthTokens>> {
    return this.http
      .post<ApiResponse<AuthTokens>>(`${environment.apiUrl}/auth/register`, payload)
      .pipe(tap((res) => this.persistSession(res.data)));
  }

  logout(): void {
    const refresh = localStorage.getItem(environment.refreshKey);
    if (refresh) {
      this.http.post(`${environment.apiUrl}/auth/logout`, { refresh_token: refresh }).subscribe();
    }
    this.clearSession();
    this.router.navigate(['/login']);
  }

  getToken(): string | null {
    return localStorage.getItem(environment.tokenKey);
  }

  isAuthenticated(): boolean {
    return !!this.getToken() && !!this.userSignal();
  }

  hasRole(roles: UserRole[]): boolean {
    const r = this.userSignal()?.role;
    return !!r && roles.includes(r);
  }

  refreshUser(): Observable<ApiResponse<User>> {
    return this.http.get<ApiResponse<User>>(`${environment.apiUrl}/auth/me`).pipe(
      tap((res) => {
        if (res.success && res.data) {
          localStorage.setItem('ca_user', JSON.stringify(res.data));
          this.userSignal.set(res.data);
        }
      })
    );
  }

  private persistSession(data: AuthTokens): void {
    localStorage.setItem(environment.tokenKey, data.access_token);
    localStorage.setItem(environment.refreshKey, data.refresh_token);
    localStorage.setItem('ca_user', JSON.stringify(data.user));
    this.userSignal.set(data.user);
  }

  private loadUser(): User | null {
    const raw = localStorage.getItem('ca_user');
    if (!raw) {
      return null;
    }
    try {
      return JSON.parse(raw) as User;
    } catch {
      return null;
    }
  }

  private clearSession(): void {
    localStorage.removeItem(environment.tokenKey);
    localStorage.removeItem(environment.refreshKey);
    localStorage.removeItem('ca_user');
    this.userSignal.set(null);
  }
}
