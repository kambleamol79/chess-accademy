export type SupportTicketStatus = 'open' | 'resolved';

export interface SupportTicket {
  id: number;
  student_id: number;
  subject: string;
  status: SupportTicketStatus;
  assigned_to_user_id: number | null;
  resolution_comment: string | null;
  student_first_name?: string;
  student_last_name?: string;
  student_email?: string;
  assignee_first_name?: string | null;
  assignee_last_name?: string | null;
  created_at: string;
  updated_at: string;
}

export interface SupportTicketMessage {
  id: number;
  ticket_id: number;
  sender_user_id: number;
  body: string;
  sender_first_name?: string;
  sender_last_name?: string;
  sender_role?: string;
  created_at: string;
}

export interface BatchMessage {
  id: number;
  form_id: number;
  sender_user_id: number;
  body: string;
  sender_first_name?: string;
  sender_last_name?: string;
  sender_role?: string;
  created_at: string;
}

export interface BroadcastMessage {
  id: number;
  sender_user_id: number;
  title: string;
  body: string;
  push_sent: number | boolean;
  push_detail?: string | null;
  sender_first_name?: string;
  sender_last_name?: string;
  created_at: string;
}
