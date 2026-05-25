import { Component, inject, Input, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { NgbActiveModal } from '@ng-bootstrap/ng-bootstrap';
import { HttpErrorResponse } from '@angular/common/http';
import { LeadService } from 'src/app/core/services/lead.service';
import { getApiErrorMessage } from 'src/app/core/utils/http-error.util';

@Component({
  selector: 'app-lead-form-modal',
  imports: [CommonModule, FormsModule],
  templateUrl: './lead-form-modal.component.html'
})
export class LeadFormModalComponent implements OnInit {
  private readonly activeModal = inject(NgbActiveModal);
  private readonly leads = inject(LeadService);

  @Input() mode: 'create' | 'edit' = 'create';
  @Input() lead: Record<string, unknown> | null = null;

  saving = signal(false);
  error = signal('');

  leadId = 0;
  captured_at = '';
  child_name = '';
  parents_name = '';
  phone = '';
  email = '';
  age = '';
  std = '';
  city = '';

  get isEdit(): boolean {
    return this.mode === 'edit';
  }

  ngOnInit() {
    if (!this.lead) {
      return;
    }
    this.leadId = Number(this.lead['id']);
    this.child_name = String(this.lead['child_name'] ?? '');
    this.parents_name = String(this.lead['parents_name'] ?? '');
    this.phone = String(this.lead['phone'] ?? '');
    this.email = String(this.lead['email'] ?? '');
    this.age = String(this.lead['age'] ?? '');
    this.std = String(this.lead['std'] ?? '');
    this.city = String(this.lead['city'] ?? '');
    if (this.lead['captured_at']) {
      const d = new Date(String(this.lead['captured_at']));
      if (!Number.isNaN(d.getTime())) {
        const pad = (n: number) => String(n).padStart(2, '0');
        this.captured_at = `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
      }
    }
  }

  dismiss() {
    this.activeModal.dismiss();
  }

  save() {
    this.error.set('');
    if (!this.child_name.trim()) {
      this.error.set('Child name is required');
      return;
    }

    const payload: Record<string, unknown> = {
      child_name: this.child_name.trim(),
      parents_name: this.parents_name.trim() || null,
      phone: this.phone.trim() || null,
      email: this.email.trim() || null,
      age: this.age.trim() || null,
      std: this.std.trim() || null,
      city: this.city.trim() || null
    };

    if (this.captured_at) {
      const normalized = this.captured_at.length === 16 ? `${this.captured_at}:00` : this.captured_at;
      payload['captured_at'] = normalized.replace('T', ' ');
    }

    this.saving.set(true);
    const req = this.isEdit
      ? this.leads.update(this.leadId, payload)
      : this.leads.create(payload);

    req.subscribe({
      next: (res) => {
        this.saving.set(false);
        if (!res.success) {
          this.error.set(res.message ?? (this.isEdit ? 'Could not update lead' : 'Could not create lead'));
          return;
        }
        this.activeModal.close(res.data);
      },
      error: (err: HttpErrorResponse) => {
        this.saving.set(false);
        this.error.set(getApiErrorMessage(err, this.isEdit ? 'Could not update lead' : 'Could not create lead'));
      }
    });
  }
}
