import { Component, EventEmitter, Input, Output } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ListFilterField } from 'src/app/core/models/list-filter.model';

@Component({
  selector: 'app-list-filter',
  imports: [CommonModule, FormsModule],
  templateUrl: './list-filter.component.html',
  styleUrl: './list-filter.component.scss'
})
export class ListFilterComponent {
  @Input({ required: true }) fields: ListFilterField[] = [];
  @Input() fieldKey = '';
  @Input() value = '';
  @Input() resultCount: number | null = null;
  @Input() totalCount: number | null = null;
  /** When true, omits bottom margin for use in a page header row. */
  @Input() inline = false;

  @Output() fieldKeyChange = new EventEmitter<string>();
  @Output() valueChange = new EventEmitter<string>();
  @Output() clear = new EventEmitter<void>();

  onFieldChange(key: string) {
    this.fieldKeyChange.emit(key);
  }

  onValueChange(text: string) {
    this.valueChange.emit(text);
  }

  onClear() {
    this.clear.emit();
  }
}
