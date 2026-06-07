export interface StudentBatch {
  enrollment_id: number;
  form_id: number;
  batch: string;
  time: string;
  days_summary: string;
  day_1: string;
  day_2: string;
  module?: string | null;
  coach_1?: string | null;
  coach_2?: string | null;
  notes?: string | null;
  highlight?: 'blue' | 'beige' | string | null;
  enrolled_at?: string | null;
  status?: string | null;
  zoom_join_url?: string | null;
  zoom_username?: string | null;
  zoom_password?: string | null;
}

export type StudentReminderType = 'class' | 'payment' | 'practice' | 'profile' | 'info';

export interface StudentReminder {
  id: string;
  type: StudentReminderType;
  title: string;
  message: string;
  due_at?: string | null;
  priority?: 'low' | 'medium' | 'high' | string;
}
