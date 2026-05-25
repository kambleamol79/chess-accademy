import { HttpErrorResponse } from '@angular/common/http';

export function getApiErrorMessage(err: HttpErrorResponse, fallback = 'Request failed'): string {
  if (err.error && typeof err.error === 'object' && 'message' in err.error) {
    return String((err.error as { message: string }).message);
  }
  if (typeof err.error === 'string' && err.error.includes('Database connection failed')) {
    return 'Database connection failed. Set DB_PASS in api/.env and restart the PHP server.';
  }
  if (err.status === 0) {
    return 'Cannot reach API at ' + err.url + '. Start it with: cd api && php -S localhost:8080 -t public';
  }
  return fallback;
}
