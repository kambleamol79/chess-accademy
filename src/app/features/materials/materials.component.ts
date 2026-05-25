import { Component, inject, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { CardComponent } from 'src/app/theme/shared/components/card/card.component';
import { MaterialService } from 'src/app/core/services/material.service';

@Component({
  selector: 'app-materials',
  imports: [CommonModule, CardComponent],
  templateUrl: './materials.component.html',
  styleUrl: './materials.component.scss'
})
export class MaterialsComponent implements OnInit {
  private readonly materials = inject(MaterialService);

  loading = signal(true);
  error = signal('');
  rows = signal<Record<string, unknown>[]>([]);

  ngOnInit() {
    this.materials.list().subscribe({
      next: (res) => {
        this.rows.set(res.data);
        this.loading.set(false);
      },
      error: () => {
        this.error.set('Failed to load materials');
        this.loading.set(false);
      }
    });
  }
}
