import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { authGuard } from './core/guards/auth.guard';
import { roleGuard } from './core/guards/role.guard';
import { AdminComponent } from './theme/layout/admin/admin.component';
import { GuestComponent } from './theme/layout/guest/guest.component';

const routes: Routes = [
  {
    path: '',
    component: AdminComponent,
    canActivate: [authGuard],
    children: [
      { path: '', redirectTo: 'dashboard', pathMatch: 'full' },
      {
        path: 'dashboard',
        loadComponent: () => import('./features/dashboard/dashboard.component').then((c) => c.DashboardComponent)
      },
      {
        path: 'batches',
        loadComponent: () => import('./features/batches/batches.component').then((c) => c.BatchesComponent),
        canActivate: [roleGuard],
        data: { roles: ['admin', 'student', 'accountant'] }
      },
      {
        path: 'leads',
        loadComponent: () => import('./features/leads/leads.component').then((c) => c.LeadsComponent),
        canActivate: [roleGuard],
        data: { roles: ['admin'] }
      },
      {
        path: 'students',
        loadComponent: () => import('./features/students/students.component').then((c) => c.StudentsComponent),
        canActivate: [roleGuard],
        data: { roles: ['admin'] }
      },
      {
        path: 'coaches',
        loadComponent: () => import('./features/coaches/coaches.component').then((c) => c.CoachesComponent),
        canActivate: [roleGuard],
        data: { roles: ['admin'] }
      },
      {
        path: 'billing',
        loadComponent: () => import('./features/billing/billing.component').then((c) => c.BillingComponent),
        canActivate: [roleGuard],
        data: { roles: ['admin', 'accountant'] }
      },
      {
        path: 'puzzles',
        loadComponent: () => import('./features/puzzles/puzzles.component').then((c) => c.PuzzlesComponent),
        canActivate: [roleGuard],
        data: { roles: ['admin', 'student'] }
      },
      {
        path: 'game-review',
        loadComponent: () => import('./features/game-review/game-review.component').then((c) => c.GameReviewComponent),
        canActivate: [roleGuard],
        data: { roles: ['admin', 'student'] }
      },
      {
        path: 'materials',
        loadComponent: () => import('./features/materials/materials.component').then((c) => c.MaterialsComponent),
        canActivate: [roleGuard],
        data: { roles: ['admin', 'student'] }
      },
      {
        path: 'settings',
        loadComponent: () => import('./features/settings/settings.component').then((c) => c.SettingsComponent),
        canActivate: [roleGuard],
        data: { roles: ['admin'] }
      }
    ]
  },
  {
    path: '',
    component: GuestComponent,
    children: [
      {
        path: 'login',
        loadComponent: () => import('./auth/login/login.component').then((c) => c.LoginComponent)
      },
      {
        path: 'register',
        loadComponent: () => import('./auth/register/register.component').then((c) => c.RegisterComponent)
      }
    ]
  },
  { path: '**', redirectTo: 'dashboard' }
];

@NgModule({
  imports: [RouterModule.forRoot(routes)],
  exports: [RouterModule]
})
export class AppRoutingModule {}
