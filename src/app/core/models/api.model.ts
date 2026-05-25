export interface ApiResponse<T> {
  success: boolean;
  data: T;
  message?: string;
  errors?: Record<string, string>;
}

export type UserRole = 'admin' | 'coach' | 'student' | 'accountant';

export interface User {
  id: number;
  email: string;
  role: UserRole;
  first_name: string;
  last_name: string;
  phone?: string | null;
  is_active: boolean;
  created_at?: string;
  coach?: Record<string, unknown>;
  student?: Record<string, unknown>;
}

export interface AuthTokens {
  user: User;
  access_token: string;
  refresh_token: string;
}
