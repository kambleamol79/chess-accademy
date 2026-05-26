import { Component, EventEmitter, Input, Output } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';

@Component({
  selector: 'app-list-date-range-filter',
  imports: [CommonModule, FormsModule],
  templateUrl: './list-date-range-filter.component.html',
  styleUrl: './list-date-range-filter.component.scss'
})
export class ListDateRangeFilterComponent {
  @Input() dateFrom = '';
  @Input() dateTo = '';
  /** Shown above From/To (e.g. "Payment date"). */
  @Input() heading = '';

  @Output() dateFromChange = new EventEmitter<string>();
  @Output() dateToChange = new EventEmitter<string>();
  @Output() clear = new EventEmitter<void>();

  get hasRange(): boolean {
    return Boolean(this.dateFrom || this.dateTo);
  }

  onClear() {
    this.clear.emit();
  }
}
