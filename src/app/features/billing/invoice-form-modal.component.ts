import { Component, inject, Input, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { NgbActiveModal } from '@ng-bootstrap/ng-bootstrap';
import { HttpErrorResponse } from '@angular/common/http';
import { BillingService } from 'src/app/core/services/billing.service';
import { getApiErrorMessage } from 'src/app/core/utils/http-error.util';

@Component({
  selector: 'app-invoice-form-modal',
  imports: [CommonModule, FormsModule],
  templateUrl: './invoice-form-modal.component.html'
})
export class InvoiceFormModalComponent implements OnInit {
  private readonly activeModal = inject(NgbActiveModal);
  private readonly billing = inject(BillingService);

  @Input() invoice: Record<string, unknown> | null = null;

  saving = signal(false);
  error = signal('');

  invoiceId = 0;
  amount = 0;
  description = '';
  due_date = '';
  status: 'pending' | 'paid' | 'cancelled' = 'pending';

  ngOnInit() {
    if (!this.invoice) {
      return;
    }
    this.invoiceId = Number(this.invoice['id']);
    this.amount = Number(this.invoice['amount']) || 0;
    this.description = String(this.invoice['description'] ?? '');
    this.due_date = this.invoice['due_date'] ? String(this.invoice['due_date']).slice(0, 10) : '';
    const s = String(this.invoice['status'] ?? 'pending');
    if (s === 'paid' || s === 'cancelled' || s === 'pending') {
      this.status = s;
    }
  }

  dismiss() {
    this.activeModal.dismiss();
  }

  save() {
    this.error.set('');
    if (this.amount <= 0) {
      this.error.set('Amount must be greater than zero');
      return;
    }

    this.saving.set(true);
    this.billing
      .update(this.invoiceId, {
        amount: this.amount,
        description: this.description.trim() || null,
        due_date: this.due_date || null,
        status: this.status
      })
      .subscribe({
        next: (res) => {
          this.saving.set(false);
          if (!res.success) {
            this.error.set(res.message ?? 'Could not update invoice');
            return;
          }
          this.activeModal.close(res.data);
        },
        error: (err: HttpErrorResponse) => {
          this.saving.set(false);
          this.error.set(getApiErrorMessage(err, 'Could not update invoice'));
        }
      });
  }
}
