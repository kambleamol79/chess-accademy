import { Component, inject, Input, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { NgbActiveModal } from '@ng-bootstrap/ng-bootstrap';
import { HttpErrorResponse } from '@angular/common/http';
import { LeadService } from 'src/app/core/services/lead.service';
import { getApiErrorMessage } from 'src/app/core/utils/http-error.util';
import {
  formatLeadTimeSlot,
  mergeAdditionalReview,
  parseLeadTimeSlot
} from 'src/app/core/utils/lead.util';
import { isValidTimeSlotRange } from 'src/app/core/utils/batch.util';

@Component({
  selector: 'app-lead-followup-modal',
  imports: [CommonModule, FormsModule],
  templateUrl: './lead-followup-modal.component.html',
  styleUrl: './lead-followup-modal.component.scss'
})
export class LeadFollowupModalComponent implements OnInit {
  private readonly activeModal = inject(NgbActiveModal);
  private readonly leads = inject(LeadService);

  @Input() lead!: Record<string, unknown>;

  saving = signal(false);
  error = signal('');

  child_name = '';
  parents_name = '';
  phone = '';
  email = '';
  age = '';
  std = '';
  city = '';

  q1: string | null = null;
  q2: string | null = null;
  q3: string | null = null;

  timeStart = '07:00';
  timeEnd = '08:00';
  attd_no = '';
  module = '';
  interested = false;
  not_interested = '';
  paid = false;
  wasPaid = false;
  receiptFile: File | null = null;
  receiptFileName = '';
  dnp = '';
  additionalReview = '';

  readonly moduleLevels = [
    'IB - 0',
    'IB - 1',
    'IB - 2',
    'IB - 3',
    'IB - 4',
    'IB - 5',
    'IB - 6',
    'IB - 7',
    'IB - 8'
  ];

  ngOnInit() {
    this.child_name = String(this.lead['child_name'] ?? '');
    this.parents_name = String(this.lead['parents_name'] ?? '');
    this.phone = String(this.lead['phone'] ?? '');
    this.email = String(this.lead['email'] ?? '');
    this.age = String(this.lead['age'] ?? '');
    this.std = String(this.lead['std'] ?? '');
    this.city = String(this.lead['city'] ?? '');

    this.q1 = (this.lead['q1'] as string | null) ?? null;
    this.q2 = (this.lead['q2'] as string | null) ?? null;
    this.q3 = (this.lead['q3'] as string | null) ?? null;

    const { start, end } = parseLeadTimeSlot(String(this.lead['time_slot'] ?? ''));
    this.timeStart = start;
    this.timeEnd = end;
    this.attd_no = String(this.lead['attd_no'] ?? '');
    this.module = String(this.lead['module'] ?? '');
    this.interested = String(this.lead['status_int'] ?? '').toUpperCase() === 'INT';
    this.not_interested = String(this.lead['not_interested'] ?? '');
    this.wasPaid = String(this.lead['paid'] ?? '').toUpperCase() === 'PAID';
    this.paid = this.wasPaid;
    this.dnp = String(this.lead['dnp'] ?? '');
    this.additionalReview = mergeAdditionalReview(this.lead['additional'], this.lead['review']);
  }

  get formattedTimeSlot(): string {
    return formatLeadTimeSlot(this.timeStart, this.timeEnd);
  }

  dismiss() {
    this.activeModal.dismiss();
  }

  onReceiptSelected(event: Event) {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0] ?? null;
    this.receiptFile = file;
    this.receiptFileName = file?.name ?? '';
  }

  private buildPayload(): Record<string, unknown> {
    const reviewText = this.additionalReview.trim();
    return {
      child_name: this.child_name.trim(),
      parents_name: this.parents_name.trim() || null,
      phone: this.phone.trim() || null,
      email: this.email.trim() || null,
      age: this.age.trim() || null,
      std: this.std.trim() || null,
      city: this.city.trim() || null,
      q1: this.q1 || null,
      q2: this.q2 || null,
      q3: this.q3 || null,
      time_slot: this.formattedTimeSlot,
      attd_no: this.attd_no.trim() || null,
      module: this.module.trim() || null,
      status_int: this.interested ? 'INT' : null,
      not_interested: this.not_interested.trim() || null,
      dnp: this.dnp.trim() || null,
      additional: null,
      review: reviewText || null
    };
  }

  save() {
    this.error.set('');
    if (!this.child_name.trim()) {
      this.error.set('Child name is required');
      return;
    }

    if (!isValidTimeSlotRange(this.timeStart, this.timeEnd)) {
      this.error.set('End time must be after start time');
      return;
    }

    const id = Number(this.lead['id']);
    const payload = this.buildPayload();

    if (this.paid) {
      if (!this.receiptFile) {
        this.error.set('Attach a payment receipt before marking as paid');
        return;
      }

      const formData = new FormData();
      formData.append('payment_receipt', this.receiptFile);
      formData.append('data', JSON.stringify(payload));

      this.saving.set(true);
      this.leads.markPaid(id, formData).subscribe({
        next: (res) => {
          this.saving.set(false);
          if (!res.success) {
            this.error.set(res.message ?? 'Could not convert lead');
            return;
          }
          this.activeModal.close(res.data);
        },
        error: (err: HttpErrorResponse) => {
          this.saving.set(false);
          this.error.set(getApiErrorMessage(err, 'Could not convert lead'));
        }
      });
      return;
    }

    const updatePayload = { ...payload, paid: null };

    this.saving.set(true);
    this.leads.update(id, updatePayload).subscribe({
      next: (res) => {
        this.saving.set(false);
        if (!res.success) {
          this.error.set(res.message ?? 'Could not update lead');
          return;
        }
        this.activeModal.close(res.data);
      },
      error: (err: HttpErrorResponse) => {
        this.saving.set(false);
        this.error.set(getApiErrorMessage(err, 'Could not update lead'));
      }
    });
  }
}
