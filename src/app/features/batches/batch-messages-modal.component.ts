import { Component, inject, Input, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { NgbActiveModal } from '@ng-bootstrap/ng-bootstrap';
import { HttpErrorResponse } from '@angular/common/http';
import { MessageService } from 'src/app/core/services/message.service';
import { BatchMessage } from 'src/app/core/models/message.model';
import { getApiErrorMessage } from 'src/app/core/utils/http-error.util';

@Component({
  selector: 'app-batch-messages-modal',
  imports: [CommonModule, FormsModule],
  templateUrl: './batch-messages-modal.component.html',
  styleUrl: './batch-messages-modal.component.scss'
})
export class BatchMessagesModalComponent implements OnInit {
  private readonly activeModal = inject(NgbActiveModal);
  private readonly messages = inject(MessageService);

  @Input() formId!: number;
  @Input() batchName = '';

  loading = signal(true);
  sending = signal(false);
  error = signal('');
  thread = signal<BatchMessage[]>([]);
  body = '';

  ngOnInit() {
    this.load();
  }

  load() {
    this.loading.set(true);
    this.messages.listBatchMessages(this.formId).subscribe({
      next: (res) => {
        this.thread.set(res.data?.messages ?? []);
        this.loading.set(false);
        this.error.set('');
      },
      error: (err: HttpErrorResponse) => {
        this.error.set(getApiErrorMessage(err, 'Could not load batch messages'));
        this.loading.set(false);
      }
    });
  }

  senderName(message: BatchMessage): string {
    const first = message.sender_first_name ?? '';
    const last = message.sender_last_name ?? '';
    const name = `${first} ${last}`.trim();
    return name || 'Admin';
  }

  send() {
    const body = this.body.trim();
    if (!body) {
      return;
    }

    this.sending.set(true);
    this.messages.sendBatchMessage(this.formId, body).subscribe({
      next: (res) => {
        const message = res.data?.message;
        if (message) {
          this.thread.update((items) => [...items, message]);
        }
        this.body = '';
        this.sending.set(false);
      },
      error: (err: HttpErrorResponse) => {
        this.error.set(getApiErrorMessage(err, 'Could not send message'));
        this.sending.set(false);
      }
    });
  }

  close() {
    this.activeModal.dismiss();
  }
}
