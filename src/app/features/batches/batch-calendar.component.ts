import { Component, computed, input, output, signal } from '@angular/core';
import { CommonModule, NgClass } from '@angular/common';
import { BatchForm } from 'src/app/core/models/form.model';
import {
  BATCH_CALENDAR_HEADERS,
  BATCH_WEEKDAYS,
  BatchCalendarMonthDay,
  BatchCalendarOccurrence,
  BatchWeekday,
  buildMonthCalendar,
  buildWeekDays,
  buildWeekTimeGrid,
  monthYearLabel,
  occurrenceTitle,
  occurrenceTone,
  occurrenceTrack as trackOccurrence,
  startOfWeekMonday,
  weekGridCellKey,
  weekRangeLabel
} from 'src/app/core/utils/batch-calendar.util';
import { CoachSlot } from './batch-assign-coach-modal.component';

export type BatchCalendarView = 'month' | 'week';

@Component({
  selector: 'app-batch-calendar',
  imports: [CommonModule, NgClass],
  templateUrl: './batch-calendar.component.html',
  styleUrl: './batch-calendar.component.scss'
})
export class BatchCalendarComponent {
  batches = input.required<BatchForm[]>();
  canEdit = input(false);
  canAssignCoach = input(false);

  editBatch = output<BatchForm>();
  assignCoach = output<{ batch: BatchForm; slot: CoachSlot }>();

  readonly headers = BATCH_CALENDAR_HEADERS;
  readonly trackOccurrence = trackOccurrence;

  view = signal<BatchCalendarView>('month');
  focusDate = signal(this.stripTime(new Date()));

  monthWeeks = computed(() => buildMonthCalendar(this.batches(), this.focusDate()));
  weekDays = computed(() => buildWeekDays(this.batches(), startOfWeekMonday(this.focusDate())));
  weekGrid = computed(() => buildWeekTimeGrid(this.batches()));

  monthLabel = computed(() => monthYearLabel(this.focusDate()));
  weekLabel = computed(() => weekRangeLabel(startOfWeekMonday(this.focusDate())));

  setView(mode: BatchCalendarView) {
    this.view.set(mode);
  }

  goToday() {
    this.focusDate.set(this.stripTime(new Date()));
  }

  goPrev() {
    const d = new Date(this.focusDate());
    if (this.view() === 'month') {
      d.setMonth(d.getMonth() - 1);
    } else {
      d.setDate(d.getDate() - 7);
    }
    this.focusDate.set(this.stripTime(d));
  }

  goNext() {
    const d = new Date(this.focusDate());
    if (this.view() === 'month') {
      d.setMonth(d.getMonth() + 1);
    } else {
      d.setDate(d.getDate() + 7);
    }
    this.focusDate.set(this.stripTime(d));
  }

  weekGridEntries(time: string, weekday: BatchWeekday): BatchCalendarOccurrence[] {
    return this.weekGrid().cells.get(weekGridCellKey(time, weekday)) ?? [];
  }

  trackWeek(_index: number, week: BatchCalendarMonthDay[]): number {
    return week[0]?.date.getTime() ?? _index;
  }

  weekdayLabel(weekday: BatchWeekday): string {
    const index = BATCH_WEEKDAYS.indexOf(weekday);
    return index >= 0 ? BATCH_CALENDAR_HEADERS[index] : weekday;
  }

  eventClasses(o: BatchCalendarOccurrence, compact = false): Record<string, boolean> {
    return {
      'batch-cal__event': true,
      'batch-cal__event--compact': compact,
      [`batch-cal__event--${occurrenceTone(o)}`]: true
    };
  }

  eventTitle(o: BatchCalendarOccurrence): string {
    return occurrenceTitle(o);
  }

  onEventClick(o: BatchCalendarOccurrence, event: Event) {
    event.stopPropagation();
    if (this.canEdit()) {
      this.editBatch.emit(o.batch);
    }
  }

  onCoachClick(o: BatchCalendarOccurrence, event: Event) {
    event.stopPropagation();
    if (!this.canAssignCoach()) {
      return;
    }
    const slot: CoachSlot = o.dayField === 'day_1' ? 'coach_1' : 'coach_2';
    this.assignCoach.emit({ batch: o.batch, slot });
  }

  dayAriaLabel(day: { date: Date; occurrences: BatchCalendarOccurrence[] }): string {
    return `${day.date.toLocaleDateString()} — ${day.occurrences.length} batch session(s)`;
  }

  private stripTime(date: Date): Date {
    return new Date(date.getFullYear(), date.getMonth(), date.getDate());
  }
}
