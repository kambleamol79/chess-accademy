import { Component, inject, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { CardComponent } from 'src/app/theme/shared/components/card/card.component';
import { BillingService } from 'src/app/core/services/billing.service';

@Component({
  selector: 'app-billing',
  imports: [CommonModule, CardComponent],
  templateUrl: './billing.component.html',
  styleUrl: './billing.component.scss'
})
export class BillingComponent implements OnInit {
  private readonly billing = inject(BillingService);

  loading = signal(true);
  error = signal('');
  rows = signal<Record<string, unknown>[]>([]);

  ngOnInit() {
    this.load();
  }

  load() {
    this.billing.list().subscribe({
      next: (res) => {
        this.rows.set(res.data);
        this.loading.set(false);
      },
      error: () => {
        this.error.set('Failed to load invoices');
        this.loading.set(false);
      }
    });
  }

  markPaid(id: number) {
    this.billing.markPaid(id).subscribe({ next: () => this.load() });
  }
}
