import { Component, inject, Input, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { NgbActiveModal } from '@ng-bootstrap/ng-bootstrap';
import { HttpErrorResponse } from '@angular/common/http';
import { MessageService } from 'src/app/core/services/message.service';
import { AuthService } from 'src/app/core/services/auth.service';
import { SupportTicket, SupportTicketMessage } from 'src/app/core/models/message.model';
import { getApiErrorMessage } from 'src/app/core/utils/http-error.util';

@Component({
  selector: 'app-support-ticket-detail-modal',
  imports: [CommonModule, FormsModule],
  templateUrl: './support-ticket-detail-modal.component.html',
  styleUrl: './support-ticket-detail-modal.component.scss'
})
export class SupportTicketDetailModalComponent implements OnInit {
  private readonly activeModal = inject(NgbActiveModal);
  private readonly messages = inject(MessageService);
  readonly auth = inject(AuthService);

  @Input() ticketId!: number;
  @Input() asStudent = false;

  loading = signal(true);
  saving = signal(false);
  error = signal('');
  ticket = signal<SupportTicket | null>(null);
  thread = signal<SupportTicketMessage[]>([]);
  replyBody = '';
  resolutionComment = '';

  ngOnInit() {
    this.load();
  }

  load() {
    this.loading.set(true);
    this.messages.getSupportTicket(this.ticketId, this.asStudent).subscribe({
      next: (res) => {
        this.ticket.set(res.data?.ticket ?? null);
        this.thread.set(res.data?.messages ?? []);
        this.loading.set(false);
        this.error.set('');
      },
      error: (err: HttpErrorResponse) => {
        this.error.set(getApiErrorMessage(err, 'Could not load ticket'));
        this.loading.set(false);
      }
    });
  }

  isResolved(): boolean {
    return this.ticket()?.status === 'resolved';
  }

  canAssign(): boolean {
    return this.auth.hasRole(['admin']) && !this.isResolved() && !this.ticket()?.assigned_to_user_id;
  }

  canResolve(): boolean {
    return this.auth.hasRole(['admin']) && !this.isResolved();
  }

  senderName(message: SupportTicketMessage): string {
    const first = message.sender_first_name ?? '';
    const last = message.sender_last_name ?? '';
    const name = `${first} ${last}`.trim();
    if (name) {
      return name;
    }
    return message.sender_role === 'admin' ? 'Admin' : 'Student';
  }

  assignSelf() {
    this.saving.set(true);
    this.messages.assignSelf(this.ticketId).subscribe({
      next: (res) => {
        this.ticket.set(res.data?.ticket ?? this.ticket());
        this.saving.set(false);
      },
      error: (err: HttpErrorResponse) => {
        this.error.set(getApiErrorMessage(err, 'Could not assign ticket'));
        this.saving.set(false);
      }
    });
  }

  sendReply() {
    const body = this.replyBody.trim();
    if (!body) {
      return;
    }

    this.saving.set(true);
    this.messages.replySupportTicket(this.ticketId, body, this.asStudent).subscribe({
      next: (res) => {
        const message = res.data?.message;
        if (message) {
          this.thread.update((items) => [...items, message]);
        }
        this.replyBody = '';
        this.saving.set(false);
      },
      error: (err: HttpErrorResponse) => {
        this.error.set(getApiErrorMessage(err, 'Could not send reply'));
        this.saving.set(false);
      }
    });
  }

  resolve() {
    const comment = this.resolutionComment.trim();
    if (!comment) {
      this.error.set('Please describe how this was resolved');
      return;
    }

    this.saving.set(true);
    this.messages.resolveTicket(this.ticketId, comment).subscribe({
      next: (res) => {
        this.ticket.set(res.data?.ticket ?? this.ticket());
        this.saving.set(false);
        this.activeModal.close(true);
      },
      error: (err: HttpErrorResponse) => {
        this.error.set(getApiErrorMessage(err, 'Could not resolve ticket'));
        this.saving.set(false);
      }
    });
  }

  close() {
    this.activeModal.dismiss();
  }
}
