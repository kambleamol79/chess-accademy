import { Component, computed, inject, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { CardComponent } from 'src/app/theme/shared/components/card/card.component';
import { ListFilterComponent } from 'src/app/theme/shared/components/list-filter/list-filter.component';
import { ListDateRangeFilterComponent } from 'src/app/theme/shared/components/list-date-range-filter/list-date-range-filter.component';
import { LeadService } from 'src/app/core/services/lead.service';
import { AuthService } from 'src/app/core/services/auth.service';
import { LeadFormModalComponent } from './lead-form-modal.component';
import { LeadFollowupModalComponent } from './lead-followup-modal.component';
import { LeadBulkUploadModalComponent } from './lead-bulk-upload-modal.component';
import { downloadLeadCsvTemplate } from './lead-csv.util';
import { LEAD_FILTER_FIELDS } from './leads-filter.fields';
import { HttpErrorResponse } from '@angular/common/http';
import { confirmDelete } from 'src/app/core/utils/confirm.util';
import { getApiErrorMessage } from 'src/app/core/utils/http-error.util';
import { mergeAdditionalReview } from 'src/app/core/utils/lead.util';
import { filterByDateRange } from 'src/app/core/utils/date-range-filter.util';
import { filterRecords } from 'src/app/core/utils/record-filter.util';

@Component({
  selector: 'app-leads',
  imports: [CommonModule, CardComponent, ListFilterComponent, ListDateRangeFilterComponent],
  templateUrl: './leads.component.html',
  styleUrl: './leads.component.scss'
})
export class LeadsComponent implements OnInit {
  private readonly leads = inject(LeadService);
  private readonly modal = inject(NgbModal);
  readonly auth = inject(AuthService);

  loading = signal(true);
  error = signal('');
  success = signal('');
  deletingId = signal<number | null>(null);
  allRows = signal<Record<string, unknown>[]>([]);
  filterField = signal(LEAD_FILTER_FIELDS[0].key);
  filterValue = signal('');
  dateFrom = signal('');
  dateTo = signal('');

  readonly filterFields = LEAD_FILTER_FIELDS;

  private readonly dateFilteredRows = computed(() =>
    filterByDateRange(this.allRows(), 'captured_at', this.dateFrom(), this.dateTo())
  );

  filteredRows = computed(() =>
    filterRecords(
      this.dateFilteredRows(),
      this.filterField(),
      this.filterValue(),
      LEAD_FILTER_FIELDS
    )
  );

  hasActiveFilters(): boolean {
    return Boolean(this.filterValue().trim() || this.dateFrom() || this.dateTo());
  }

  ngOnInit() {
    this.load();
  }

  canManageLeads(): boolean {
    return this.auth.hasRole(['admin', 'coach']);
  }

  canDelete(): boolean {
    return this.auth.hasRole(['admin']);
  }

  load() {
    this.loading.set(true);
    this.leads.list().subscribe({
      next: (res) => {
        this.allRows.set(res.data ?? []);
        this.loading.set(false);
        this.error.set('');
      },
      error: () => {
        this.error.set('Failed to load leads');
        this.loading.set(false);
      }
    });
  }

  openAddLead() {
    const ref = this.modal.open(LeadFormModalComponent, {
      size: 'lg',
      centered: true,
      backdrop: 'static'
    });
    ref.closed.subscribe(() => this.load());
  }

  openEditLead(row: Record<string, unknown>) {
    const ref = this.modal.open(LeadFormModalComponent, {
      size: 'lg',
      centered: true,
      backdrop: 'static'
    });
    ref.componentInstance.mode = 'edit';
    ref.componentInstance.lead = { ...row };
    ref.closed.subscribe(() => this.load());
  }

  downloadCsvTemplate() {
    downloadLeadCsvTemplate();
  }

  openBulkUpload() {
    const ref = this.modal.open(LeadBulkUploadModalComponent, {
      size: 'lg',
      centered: true,
      backdrop: 'static'
    });
    ref.closed.subscribe(
      (result: { created?: number; skipped?: number; message?: string } | undefined) => {
        this.load();
        if (result && typeof result.created === 'number') {
          this.error.set('');
          this.success.set(result.message ?? `Imported ${result.created} lead(s).`);
        }
      }
    );
  }

  openFollowup(row: Record<string, unknown>) {
    const ref = this.modal.open(LeadFollowupModalComponent, {
      size: 'xl',
      centered: true,
      backdrop: 'static'
    });
    ref.componentInstance.lead = { ...row };
    ref.closed.subscribe((result: Record<string, unknown> | undefined) => {
      this.load();
      if (result?.['converted']) {
        this.error.set('');
        const pwd = String(result['temporary_password'] ?? '');
        this.success.set(
          pwd
            ? `Lead moved to Students. Share the temporary password with the family: ${pwd}`
            : 'Lead moved to Students.'
        );
      }
    });
  }

  formatDate(value: unknown): string {
    if (!value) {
      return '—';
    }
    const d = new Date(String(value));
    if (Number.isNaN(d.getTime())) {
      return String(value);
    }
    return d.toLocaleString(undefined, {
      month: 'numeric',
      day: 'numeric',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  }

  additionalReview(row: Record<string, unknown>): string {
    return mergeAdditionalReview(row['additional'], row['review']);
  }

  cell(value: unknown): string {
    if (value === null || value === undefined || value === '') {
      return '—';
    }
    return String(value);
  }

  badgeClass(field: string, value: unknown): string {
    const v = String(value ?? '').toUpperCase();
    if (field === 'paid' && v === 'PAID') {
      return 'bg-warning-subtle text-warning-emphasis';
    }
    if (field === 'status_int' && v === 'INT') {
      return 'bg-info-subtle text-info-emphasis';
    }
    if (field === 'q' && (v === 'YES' || v === 'NO')) {
      return v === 'YES' ? 'bg-success-subtle text-success-emphasis' : 'bg-secondary-subtle';
    }
    return '';
  }

  clearFilter() {
    this.filterValue.set('');
  }

  clearDateRange() {
    this.dateFrom.set('');
    this.dateTo.set('');
  }

  deleteLead(row: Record<string, unknown>) {
    const id = Number(row['id']);
    const label = String(row['child_name'] ?? `Lead #${id}`);
    if (!confirmDelete(label)) {
      return;
    }

    this.deletingId.set(id);
    this.leads.delete(id).subscribe({
      next: () => {
        this.deletingId.set(null);
        this.load();
      },
      error: (err: HttpErrorResponse) => {
        this.deletingId.set(null);
        this.error.set(getApiErrorMessage(err, 'Could not delete lead'));
      }
    });
  }
}
