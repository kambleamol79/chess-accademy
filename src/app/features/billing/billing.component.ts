import { Component, inject, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { CardComponent } from 'src/app/theme/shared/components/card/card.component';
import { InvoiceFormModalComponent } from './invoice-form-modal.component';
import { HttpErrorResponse } from '@angular/common/http';
import { BillingService } from 'src/app/core/services/billing.service';
import { AuthService } from 'src/app/core/services/auth.service';
import { confirmDelete } from 'src/app/core/utils/confirm.util';
import { getApiErrorMessage } from 'src/app/core/utils/http-error.util';

@Component({
  selector: 'app-billing',
  imports: [CommonModule, CardComponent],
  templateUrl: './billing.component.html',
  styleUrl: './billing.component.scss'
})
export class BillingComponent implements OnInit {
  private readonly billing = inject(BillingService);
  private readonly modal = inject(NgbModal);
  readonly auth = inject(AuthService);

  loading = signal(true);
  error = signal('');
  deletingId = signal<number | null>(null);
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

  canDelete(): boolean {
    return this.auth.hasRole(['admin']);
  }

  canEdit(): boolean {
    return this.auth.hasRole(['admin', 'accountant']);
  }

  openEditInvoice(row: Record<string, unknown>) {
    const ref = this.modal.open(InvoiceFormModalComponent, {
      size: 'md',
      centered: true,
      backdrop: 'static'
    });
    ref.componentInstance.invoice = row;
    ref.closed.subscribe(() => this.load());
  }

  markPaid(id: number) {
    this.billing.markPaid(id).subscribe({ next: () => this.load() });
  }

  deleteInvoice(row: Record<string, unknown>) {
    const id = Number(row['id']);
    const label = `Invoice #${id}`;
    if (!confirmDelete(label)) {
      return;
    }

    this.deletingId.set(id);
    this.billing.delete(id).subscribe({
      next: () => {
        this.deletingId.set(null);
        this.load();
      },
      error: (err: HttpErrorResponse) => {
        this.deletingId.set(null);
        this.error.set(getApiErrorMessage(err, 'Could not delete invoice'));
      }
    });
  }
}
