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
      { path: 'materials', redirectTo: 'dashboard', pathMatch: 'full' },
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
        path: 'practice',
        loadComponent: () => import('./features/practice/practice.component').then((c) => c.PracticeComponent),
        canActivate: [roleGuard],
        data: { roles: ['admin', 'student'] }
      },
      // FEATURE: game review — enable when ready
      // {
      //   path: 'game-review',
      //   loadComponent: () => import('./features/game-review/game-review.component').then((c) => c.GameReviewComponent),
      //   canActivate: [roleGuard],
      //   data: { roles: ['admin', 'student'] }
      // },
      // FEATURE: live arena — enable when ready
      // {
      //   path: 'chess-arena',
      //   loadComponent: () => import('./features/chess-arena/chess-arena.component').then((c) => c.ChessArenaComponent),
      //   canActivate: [roleGuard],
      //   data: { roles: ['student'] }
      // },
      // {
      //   path: 'chess-arena/match/:id',
      //   loadComponent: () => import('./features/chess-arena/live-match.component').then((c) => c.LiveMatchComponent),
      //   canActivate: [roleGuard],
      //   data: { roles: ['student'] }
      // },
      // {
      //   path: 'chess-tournaments',
      //   loadComponent: () =>
      //     import('./features/chess-tournaments/chess-tournaments.component').then((c) => c.ChessTournamentsComponent),
      //   canActivate: [roleGuard],
      //   data: { roles: ['admin'] }
      // },
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
