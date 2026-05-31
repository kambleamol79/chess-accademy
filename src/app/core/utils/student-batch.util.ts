import { BatchForm } from '../models/form.model';
import { StudentBatch } from '../models/student-portal.model';

/** Map student portal batch payload to BatchForm for Zoom modal / shared UI. */
export function studentBatchToBatchForm(batch: StudentBatch): BatchForm {
  const highlight = batch.highlight === 'beige' ? 'beige' : 'blue';

  return {
    id: batch.form_id,
    highlight,
    batch: batch.batch,
    module: batch.module ?? null,
    time: batch.time,
    days_summary: batch.days_summary,
    day_1: batch.day_1,
    coach_1: batch.coach_1 ?? null,
    day_2: batch.day_2,
    coach_2: batch.coach_2 ?? null,
    notes: batch.notes ?? null,
    zoom_meeting_id: batch.zoom_meeting_id ?? null
  };
}

export function studentCoachesLabel(batch: StudentBatch): string {
  const parts = [batch.coach_1, batch.coach_2].filter((c) => c != null && String(c).trim() !== '');
  return parts.length === 0 ? 'Not assigned' : parts.join(' · ');
}

export function hasStudentZoomJoin(batch: StudentBatch | null): boolean {
  return !!batch?.zoom_join_url?.trim() || !!batch?.zoom_meeting_id?.trim();
}
