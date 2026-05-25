import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { AuthService } from '../services/auth.service';
import { UserRole } from '../models/api.model';

export const roleGuard: CanActivateFn = (route) => {
  const auth = inject(AuthService);
  const router = inject(Router);
  const roles = (route.data['roles'] as UserRole[]) ?? [];

  if (!auth.isAuthenticated()) {
    return router.createUrlTree(['/login']);
  }

  if (roles.length === 0 || auth.hasRole(roles)) {
    return true;
  }

  return router.createUrlTree(['/dashboard']);
};
