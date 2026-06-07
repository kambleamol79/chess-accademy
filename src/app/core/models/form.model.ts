export interface BatchForm {
  id: number;
  highlight: 'blue' | 'beige';
  batch: string;
  module: string | null;
  time: string;
  days_summary: string;
  day_1: string;
  coach_1: string | null;
  day_2: string;
  coach_2: string | null;
  notes: string | null;
  zoom_join_url?: string | null;
  zoom_username?: string | null;
  zoom_password?: string | null;
  created_at?: string;
  updated_at?: string;
}
