import { Component, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { NgbActiveModal } from '@ng-bootstrap/ng-bootstrap';
import { HttpErrorResponse } from '@angular/common/http';
import { LeadService } from 'src/app/core/services/lead.service';
import { getApiErrorMessage } from 'src/app/core/utils/http-error.util';
import { downloadLeadCsvTemplate, parseLeadCsv } from './lead-csv.util';

@Component({
  selector: 'app-lead-bulk-upload-modal',
  imports: [CommonModule],
  templateUrl: './lead-bulk-upload-modal.component.html'
})
export class LeadBulkUploadModalComponent {
  private readonly activeModal = inject(NgbActiveModal);
  private readonly leads = inject(LeadService);

  saving = signal(false);
  error = signal('');
  fileName = signal('');
  parsedCount = signal(0);
  parseErrors = signal<{ row: number; message: string }[]>([]);
  preview = signal<Record<string, unknown>[]>([]);

  private csvText = '';

  dismiss() {
    this.activeModal.dismiss();
  }

  downloadTemplate() {
    downloadLeadCsvTemplate();
  }

  onFileSelected(event: Event) {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];
    if (!file) {
      return;
    }

    this.error.set('');
    this.fileName.set(file.name);

    if (!file.name.toLowerCase().endsWith('.csv')) {
      this.error.set('Please choose a .csv file');
      input.value = '';
      return;
    }

    const reader = new FileReader();
    reader.onload = () => {
      this.csvText = String(reader.result ?? '');
      const result = parseLeadCsv(this.csvText);
      this.parsedCount.set(result.leads.length);
      this.parseErrors.set(result.errors);
      this.preview.set(result.leads.slice(0, 5));
      if (result.leads.length === 0 && result.errors.length === 0) {
        this.error.set('No data rows found in the file');
      }
    };
    reader.onerror = () => this.error.set('Could not read file');
    reader.readAsText(file);
  }

  upload() {
    this.error.set('');

    if (!this.csvText.trim()) {
      this.error.set('Select a CSV file first');
      return;
    }

    const { leads, errors } = parseLeadCsv(this.csvText);
    if (leads.length === 0) {
      this.error.set(errors[0]?.message ?? 'No valid rows to import');
      return;
    }

    this.saving.set(true);
    this.leads.bulkUpload({ csv: this.csvText }).subscribe({
      next: (res) => {
        this.saving.set(false);
        if (!res.success) {
          this.error.set(res.message ?? 'Import failed');
          return;
        }
        this.activeModal.close({
          ...res.data,
          message: res.message
        });
      },
      error: (err: HttpErrorResponse) => {
        this.saving.set(false);
        this.error.set(getApiErrorMessage(err, 'Import failed'));
      }
    });
  }
}
