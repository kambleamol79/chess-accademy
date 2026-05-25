import { ChangeDetectorRef, Component, inject, signal } from '@angular/core';
import { Router, RouterModule } from '@angular/router';
import { email, Field, form, minLength, required } from '@angular/forms/signals';
import { HttpErrorResponse } from '@angular/common/http';
import { AuthService } from 'src/app/core/services/auth.service';
import { environment } from 'src/environments/environment';

@Component({
  selector: 'app-register',
  imports: [RouterModule, Field],
  templateUrl: './register.component.html',
  styleUrls: ['./register.component.scss']
})
export class RegisterComponent {
  private readonly auth = inject(AuthService);
  private readonly router = inject(Router);
  private readonly cd = inject(ChangeDetectorRef);

  readonly appName = environment.appName;
  loading = signal(false);
  submitted = signal(false);
  error = signal('');

  registerModel = signal({
    first_name: '',
    last_name: '',
    email: '',
    password: ''
  });

  registerForm = form(this.registerModel, (schemaPath) => {
    required(schemaPath.email, { message: 'Email is required' });
    email(schemaPath.email, { message: 'Enter a valid email' });
    required(schemaPath.password, { message: 'Password is required' });
    minLength(schemaPath.password, 8, { message: 'Password must be at least 8 characters' });
    required(schemaPath.first_name, { message: 'First name is required' });
    required(schemaPath.last_name, { message: 'Last name is required' });
  });

  onSubmit(event: Event) {
    this.submitted.set(true);
    this.error.set('');
    event.preventDefault();

    const m = this.registerModel();
    this.loading.set(true);

    this.auth
      .register({
        email: m.email,
        password: m.password,
        first_name: m.first_name,
        last_name: m.last_name,
        role: 'student'
      })
      .subscribe({
        next: () => {
          this.loading.set(false);
          this.router.navigate(['/dashboard']);
        },
        error: (err: HttpErrorResponse) => {
          this.loading.set(false);
          this.error.set(err.error?.message ?? 'Registration failed');
          this.cd.detectChanges();
        }
      });
  }
}
