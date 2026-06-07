import { Component, computed, inject, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { HttpErrorResponse } from '@angular/common/http';
import { CardComponent } from 'src/app/theme/shared/components/card/card.component';
import { AuthService } from 'src/app/core/services/auth.service';
import { MessageService } from 'src/app/core/services/message.service';
import { SupportTicket, BroadcastMessage } from 'src/app/core/models/message.model';
import { getApiErrorMessage } from 'src/app/core/utils/http-error.util';
import { SupportTicketDetailModalComponent } from './support-ticket-detail-modal.component';

@Component({
  selector: 'app-messages',
  imports: [CommonModule, FormsModule, CardComponent],
  templateUrl: './messages.component.html',
  styleUrl: './messages.component.scss'
})
export class MessagesComponent implements OnInit {
  private readonly messages = inject(MessageService);
  private readonly modal = inject(NgbModal);
  readonly auth = inject(AuthService);

  loading = signal(true);
  error = signal('');
  success = signal('');
  rows = signal<SupportTicket[]>([]);
  broadcasts = signal<BroadcastMessage[]>([]);
  statusFilter = signal<'all' | 'open' | 'resolved'>('all');

  broadcastTitle = 'Brainstorm announcement';
  broadcastBody = '';
  broadcasting = signal(false);
  broadcastsLoading = signal(false);

  readonly isStudent = computed(() => this.auth.hasRole(['student']));
  readonly isAdmin = computed(() => this.auth.hasRole(['admin']));

  newSubject = '';
  newBody = '';
  creating = signal(false);

  filteredRows = computed(() => {
    const filter = this.statusFilter();
    if (filter === 'all') {
      return this.rows();
    }
    return this.rows().filter((row) => row.status === filter);
  });

  ngOnInit() {
    this.load();
    this.loadBroadcasts();
  }

  loadBroadcasts() {
    this.broadcastsLoading.set(true);
    const request = this.isStudent() ? this.messages.listMyBroadcastMessages() : this.messages.listBroadcastMessages();
    request.subscribe({
      next: (res) => {
        this.broadcasts.set(res.data?.messages ?? []);
        this.broadcastsLoading.set(false);
      },
      error: () => {
        this.broadcastsLoading.set(false);
      }
    });
  }

  load() {
    this.loading.set(true);
    const request = this.isStudent()
      ? this.messages.listMySupportTickets()
      : this.messages.listSupportTickets();

    request.subscribe({
      next: (res) => {
        this.rows.set(res.data?.tickets ?? []);
        this.loading.set(false);
        this.error.set('');
      },
      error: (err: HttpErrorResponse) => {
        this.error.set(getApiErrorMessage(err, 'Could not load support messages'));
        this.loading.set(false);
      }
    });
  }

  openTicket(ticket: SupportTicket) {
    const ref = this.modal.open(SupportTicketDetailModalComponent, { size: 'lg', scrollable: true });
    ref.componentInstance.ticketId = ticket.id;
    ref.componentInstance.asStudent = this.isStudent();
    ref.closed.subscribe((changed) => {
      if (changed) {
        this.load();
      }
    });
  }

  createTicket() {
    const subject = this.newSubject.trim();
    const body = this.newBody.trim();
    if (!subject || !body) {
      this.error.set('Subject and message are required');
      return;
    }

    this.creating.set(true);
    this.error.set('');
    this.messages.createSupportTicket({ subject, body }).subscribe({
      next: () => {
        this.newSubject = '';
        this.newBody = '';
        this.success.set('Support request submitted');
        this.creating.set(false);
        this.load();
      },
      error: (err: HttpErrorResponse) => {
        this.error.set(getApiErrorMessage(err, 'Could not submit support request'));
        this.creating.set(false);
      }
    });
  }

  studentName(ticket: SupportTicket): string {
    const first = ticket.student_first_name ?? '';
    const last = ticket.student_last_name ?? '';
    return `${first} ${last}`.trim() || 'Student';
  }

  assigneeName(ticket: SupportTicket): string {
    if (!ticket.assigned_to_user_id) {
      return 'Unassigned';
    }
    const first = ticket.assignee_first_name ?? '';
    const last = ticket.assignee_last_name ?? '';
    return `${first} ${last}`.trim() || 'Admin';
  }

  sendBroadcast() {
    const title = this.broadcastTitle.trim() || 'Brainstorm announcement';
    const body = this.broadcastBody.trim();
    if (!body) {
      this.error.set('Announcement message is required');
      return;
    }

    this.broadcasting.set(true);
    this.error.set('');
    this.messages.sendBroadcastMessage({ title, body }).subscribe({
      next: (res) => {
        this.broadcastBody = '';
        this.broadcasting.set(false);
        const pushOk = res.data?.push?.ok;
        this.success.set(
          pushOk
            ? 'Announcement sent to all students via Firebase push'
            : 'Announcement saved (Firebase push not configured or failed)'
        );
        this.loadBroadcasts();
      },
      error: (err: HttpErrorResponse) => {
        this.broadcasting.set(false);
        this.error.set(getApiErrorMessage(err, 'Could not send announcement'));
      }
    });
  }

  broadcastSenderName(message: BroadcastMessage): string {
    const first = message.sender_first_name ?? '';
    const last = message.sender_last_name ?? '';
    return `${first} ${last}`.trim() || 'Admin';
  }
}
