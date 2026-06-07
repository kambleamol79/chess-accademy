import { Component, computed, inject, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { CardComponent } from 'src/app/theme/shared/components/card/card.component';
import { ListFilterComponent } from 'src/app/theme/shared/components/list-filter/list-filter.component';
import { ListDateRangeFilterComponent } from 'src/app/theme/shared/components/list-date-range-filter/list-date-range-filter.component';
import { StudentService } from 'src/app/core/services/student.service';
import { STUDENT_FILTER_FIELDS } from './students-filter.fields';
import { filterByDateRange } from 'src/app/core/utils/date-range-filter.util';
import { filterRecords } from 'src/app/core/utils/record-filter.util';
import { AuthService } from 'src/app/core/services/auth.service';
import { HttpErrorResponse } from '@angular/common/http';
import { StudentFormModalComponent } from './student-form-modal.component';
import { StudentAssignBatchModalComponent } from './student-assign-batch-modal.component';
import { confirmDelete } from 'src/app/core/utils/confirm.util';
import { getApiErrorMessage } from 'src/app/core/utils/http-error.util';
import {
  STUDENT_MONTH_FIELDS,
  STUDENT_MONTH_LABELS,
  StudentMonthField
} from 'src/app/core/models/student-roster.model';
import { BulkAssignResult } from 'src/app/core/services/enrollment.service';

@Component({
  selector: 'app-students',
  imports: [CommonModule, CardComponent, ListFilterComponent, ListDateRangeFilterComponent],
  templateUrl: './students.component.html',
  styleUrl: './students.component.scss'
})
export class StudentsComponent implements OnInit {
  private readonly students = inject(StudentService);
  private readonly modal = inject(NgbModal);
  readonly auth = inject(AuthService);

  readonly monthFields = STUDENT_MONTH_FIELDS;
  readonly monthLabels = STUDENT_MONTH_LABELS;

  loading = signal(true);
  error = signal('');
  success = signal('');
  deletingId = signal<number | null>(null);
  allRows = signal<Record<string, unknown>[]>([]);
  filterField = signal(STUDENT_FILTER_FIELDS[0].key);
  filterValue = signal('');
  dateFrom = signal('');
  dateTo = signal('');
  selectedIds = signal<Set<number>>(new Set());

  readonly filterFields = STUDENT_FILTER_FIELDS;

  /** Same source as the PAYMENT D column in the roster table. */
  studentFilterDate(row: Record<string, unknown>): unknown {
    return row['payment_date'] ?? row['enrollment_date'] ?? row['created_at'];
  }

  private readonly studentDateGetter = (row: Record<string, unknown>) => this.studentFilterDate(row);

  private readonly dateFilteredRows = computed(() =>
    filterByDateRange(this.allRows(), this.studentDateGetter, this.dateFrom(), this.dateTo())
  );

  filteredRows = computed(() =>
    filterRecords(
      this.dateFilteredRows(),
      this.filterField(),
      this.filterValue(),
      STUDENT_FILTER_FIELDS
    )
  );

  selectedCount = computed(() => this.selectedIds().size);
  allSelected = computed(() => {
    const rows = this.filteredRows();
    return rows.length > 0 && rows.every((r) => this.selectedIds().has(Number(r['id'])));
  });

  ngOnInit() {
    this.load();
  }

  canAddStudent(): boolean {
    return this.auth.hasRole(['admin', 'coach']);
  }

  canAssignBatch(): boolean {
    return this.auth.hasRole(['admin', 'coach']);
  }

  canDelete(): boolean {
    return this.auth.hasRole(['admin']);
  }

  load() {
    this.loading.set(true);
    this.students.list().subscribe({
      next: (res) => {
        this.allRows.set(res.data ?? []);
        this.selectedIds.set(new Set());
        this.loading.set(false);
        this.error.set('');
      },
      error: () => {
        this.error.set('Failed to load students');
        this.loading.set(false);
      }
    });
  }

  canEdit(): boolean {
    return this.auth.hasRole(['admin']);
  }

  cell(value: unknown): string {
    if (value === null || value === undefined || value === '') {
      return '—';
    }
    return String(value);
  }

  studentName(row: Record<string, unknown>): string {
    return `${row['first_name'] ?? ''} ${row['last_name'] ?? ''}`.trim();
  }

  contactNo(row: Record<string, unknown>): string {
    return this.cell(row['phone'] || row['parent_phone']);
  }

  paymentDate(row: Record<string, unknown>): string {
    const d = row['payment_date'] ?? row['enrollment_date'];
    if (!d) {
      return '—';
    }
    const parsed = new Date(String(d));
    if (Number.isNaN(parsed.getTime())) {
      return String(d);
    }
    return parsed.toLocaleDateString();
  }

  batchDay(row: Record<string, unknown>): string {
    if (row['batch_day']) {
      const time = row['batch_time'] ? ` · ${row['batch_time']}` : '';
      return `${row['batch_day']}${time}`;
    }
    return '—';
  }

  monthValue(row: Record<string, unknown>, field: StudentMonthField): string {
    return this.cell(row[field]);
  }

  isSelected(row: Record<string, unknown>): boolean {
    return this.selectedIds().has(Number(row['id']));
  }

  toggleRow(row: Record<string, unknown>, checked: boolean) {
    const id = Number(row['id']);
    const next = new Set(this.selectedIds());
    if (checked) {
      next.add(id);
    } else {
      next.delete(id);
    }
    this.selectedIds.set(next);
  }

  toggleSelectAll(checked: boolean) {
    if (!checked) {
      this.selectedIds.set(new Set());
      return;
    }
    this.selectedIds.set(new Set(this.filteredRows().map((r) => Number(r['id']))));
  }

  clearFilter() {
    this.filterValue.set('');
  }

  clearDateRange() {
    this.dateFrom.set('');
    this.dateTo.set('');
  }

  hasActiveFilters(): boolean {
    return Boolean(this.filterValue().trim() || this.dateFrom() || this.dateTo());
  }

  openAssignBatch() {
    const ids = Array.from(this.selectedIds());
    if (ids.length === 0) {
      return;
    }

    const names = this.allRows()
      .filter((r) => ids.includes(Number(r['id'])))
      .map((r) => this.studentName(r));

    const ref = this.modal.open(StudentAssignBatchModalComponent, {
      size: 'lg',
      centered: true,
      scrollable: true,
      backdrop: 'static'
    });
    ref.componentInstance.studentIds = ids;
    ref.componentInstance.studentNames = names;

    ref.closed.subscribe((result: BulkAssignResult | undefined) => {
      if (!result) {
        return;
      }
      const skipped = result.skipped?.length ?? 0;
      let msg = `${result.created} student(s) assigned to batch.`;
      if (skipped > 0) {
        msg += ` ${skipped} skipped (already enrolled).`;
      }
      this.success.set(msg);
      this.load();
    });
  }

  openAddStudent() {
    this.openStudentModal('create');
  }

  openEditStudent(row: Record<string, unknown>) {
    this.openStudentModal('edit', row);
  }

  private openStudentModal(mode: 'create' | 'edit', student?: Record<string, unknown>) {
    const ref = this.modal.open(StudentFormModalComponent, {
      size: 'lg',
      centered: true,
      backdrop: 'static'
    });
    ref.componentInstance.mode = mode;
    if (student) {
      ref.componentInstance.student = student;
    }
    ref.closed.subscribe(() => this.load());
  }

  deleteStudent(row: Record<string, unknown>) {
    const id = Number(row['id']);
    const label = this.studentName(row);
    if (!confirmDelete(label || `Student #${id}`)) {
      return;
    }

    this.deletingId.set(id);
    this.students.delete(id).subscribe({
      next: () => {
        this.deletingId.set(null);
        this.load();
      },
      error: (err: HttpErrorResponse) => {
        this.deletingId.set(null);
        this.error.set(getApiErrorMessage(err, 'Could not delete student'));
      }
    });
  }
}
