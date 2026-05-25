import { Component, inject, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { CardComponent } from 'src/app/theme/shared/components/card/card.component';
import { environment } from 'src/environments/environment';
import { ApiResponse } from 'src/app/core/models/api.model';

@Component({
  selector: 'app-settings',
  imports: [CommonModule, CardComponent],
  templateUrl: './settings.component.html',
  styleUrl: './settings.component.scss'
})
export class SettingsComponent implements OnInit {
  private readonly http = inject(HttpClient);

  loading = signal(true);
  settings = signal<Record<string, unknown>>({});

  ngOnInit() {
    this.http.get<ApiResponse<Record<string, unknown>>>(`${environment.apiUrl}/settings`).subscribe({
      next: (res) => {
        this.settings.set(res.data);
        this.loading.set(false);
      },
      error: () => this.loading.set(false)
    });
  }
}
