import { inject, Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { ApiResponse } from '../models/api.model';
import { BatchMessage, BroadcastMessage, SupportTicket, SupportTicketMessage } from '../models/message.model';
import { environment } from 'src/environments/environment';

@Injectable({ providedIn: 'root' })
export class MessageService {
  private readonly http = inject(HttpClient);

  listSupportTickets(status?: string): Observable<ApiResponse<{ tickets: SupportTicket[] }>> {
    const params = status ? { status } : undefined;
    return this.http.get<ApiResponse<{ tickets: SupportTicket[] }>>(`${environment.apiUrl}/support-tickets`, {
      params
    });
  }

  listMySupportTickets(): Observable<ApiResponse<{ tickets: SupportTicket[] }>> {
    return this.http.get<ApiResponse<{ tickets: SupportTicket[] }>>(
      `${environment.apiUrl}/students/me/support-tickets`
    );
  }

  getSupportTicket(id: number, asStudent = false): Observable<
    ApiResponse<{ ticket: SupportTicket; messages: SupportTicketMessage[] }>
  > {
    const base = asStudent
      ? `${environment.apiUrl}/students/me/support-tickets/${id}`
      : `${environment.apiUrl}/support-tickets/${id}`;
    return this.http.get<ApiResponse<{ ticket: SupportTicket; messages: SupportTicketMessage[] }>>(base);
  }

  createSupportTicket(payload: { subject: string; body: string }): Observable<
    ApiResponse<{ ticket: SupportTicket; message: SupportTicketMessage }>
  > {
    return this.http.post<ApiResponse<{ ticket: SupportTicket; message: SupportTicketMessage }>>(
      `${environment.apiUrl}/students/me/support-tickets`,
      payload
    );
  }

  replySupportTicket(
    id: number,
    body: string,
    asStudent = false
  ): Observable<ApiResponse<{ message: SupportTicketMessage }>> {
    const base = asStudent
      ? `${environment.apiUrl}/students/me/support-tickets/${id}/messages`
      : `${environment.apiUrl}/support-tickets/${id}/messages`;
    return this.http.post<ApiResponse<{ message: SupportTicketMessage }>>(base, { body });
  }

  assignSelf(id: number): Observable<ApiResponse<{ ticket: SupportTicket }>> {
    return this.http.patch<ApiResponse<{ ticket: SupportTicket }>>(`${environment.apiUrl}/support-tickets/${id}`, {
      assign_self: true
    });
  }

  resolveTicket(id: number, resolutionComment: string): Observable<ApiResponse<{ ticket: SupportTicket }>> {
    return this.http.patch<ApiResponse<{ ticket: SupportTicket }>>(`${environment.apiUrl}/support-tickets/${id}`, {
      status: 'resolved',
      resolution_comment: resolutionComment
    });
  }

  listBatchMessages(formId: number): Observable<ApiResponse<{ messages: BatchMessage[] }>> {
    return this.http.get<ApiResponse<{ messages: BatchMessage[] }>>(
      `${environment.apiUrl}/forms/${formId}/messages`
    );
  }

  sendBatchMessage(formId: number, body: string): Observable<ApiResponse<{ message: BatchMessage }>> {
    return this.http.post<ApiResponse<{ message: BatchMessage }>>(
      `${environment.apiUrl}/forms/${formId}/messages`,
      { body }
    );
  }

  listBroadcastMessages(): Observable<ApiResponse<{ messages: BroadcastMessage[] }>> {
    return this.http.get<ApiResponse<{ messages: BroadcastMessage[] }>>(
      `${environment.apiUrl}/broadcast-messages`
    );
  }

  listMyBroadcastMessages(): Observable<ApiResponse<{ messages: BroadcastMessage[] }>> {
    return this.http.get<ApiResponse<{ messages: BroadcastMessage[] }>>(
      `${environment.apiUrl}/students/me/broadcast-messages`
    );
  }

  sendBroadcastMessage(payload: {
    title: string;
    body: string;
  }): Observable<ApiResponse<{ message: BroadcastMessage; push: { ok: boolean; detail: string } }>> {
    return this.http.post<ApiResponse<{ message: BroadcastMessage; push: { ok: boolean; detail: string } }>>(
      `${environment.apiUrl}/broadcast-messages`,
      payload
    );
  }
}
