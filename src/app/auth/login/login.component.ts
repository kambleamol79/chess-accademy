import { ChangeDetectorRef, Component, inject, signal } from '@angular/core';
import { Router, RouterModule } from '@angular/router';
import { HttpErrorResponse } from '@angular/common/http';
import { FormsModule } from '@angular/forms';
import { AuthService } from 'src/app/core/services/auth.service';
import { getApiErrorMessage } from 'src/app/core/utils/http-error.util';
import { environment } from 'src/environments/environment';

@Component({
  selector: 'app-login',
  imports: [RouterModule, FormsModule],
  templateUrl: './login.component.html',
  styleUrls: ['./login.component.scss']
})
export class LoginComponent {
  private readonly auth = inject(AuthService);
  private readonly router = inject(Router);
  private readonly cd = inject(ChangeDetectorRef);

  readonly appName = environment.appName;
  loading = signal(false);
  error = signal('');

  email = 'admin@chessacademy.local';
  password = 'Admin@123456';

  onSubmit(event: Event) {
    event.preventDefault();
    this.error.set('');

    const email = this.email.trim();
    const password = this.password;

    if (!email || !password) {
      this.error.set('Email and password are required');
      return;
    }

    if (password.length < 8) {
      this.error.set('Password must be at least 8 characters');
      return;
    }

    this.loading.set(true);

    this.auth.login(email, password).subscribe({
      next: (res) => {
        this.loading.set(false);
        if (!res.success || !res.data?.access_token) {
          this.error.set(res.message ?? 'Invalid credentials');
          return;
        }
        this.router.navigate(['/dashboard']);
      },
      error: (err: HttpErrorResponse) => {
        this.loading.set(false);
        this.error.set(getApiErrorMessage(err, 'Login failed. Check credentials and API.'));
        this.cd.detectChanges();
      }
    });
  }
}
