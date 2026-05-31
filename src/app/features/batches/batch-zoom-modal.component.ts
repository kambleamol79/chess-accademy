import { Component, ElementRef, Input, NgZone, OnDestroy, OnInit, ViewChild, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { NgbActiveModal } from '@ng-bootstrap/ng-bootstrap';
import { HttpErrorResponse } from '@angular/common/http';
import { BatchForm } from 'src/app/core/models/form.model';
import { FormService } from 'src/app/core/services/form.service';
import { ZoomSdkLoaderService } from 'src/app/core/services/zoom-sdk-loader.service';
import { ZoomJoinSignature } from 'src/app/core/models/zoom.model';
import { ZoomEmbeddedClient } from 'src/app/core/types/zoom-sdk.global';
import { getApiErrorMessage } from 'src/app/core/utils/http-error.util';
import { openZoomExternalFullscreen } from 'src/app/core/utils/zoom-open.util';

@Component({
  selector: 'app-batch-zoom-modal',
  imports: [CommonModule],
  templateUrl: './batch-zoom-modal.component.html',
  styleUrl: './batch-zoom-modal.component.scss'
})
export class BatchZoomModalComponent implements OnInit, OnDestroy {
  private readonly activeModal = inject(NgbActiveModal);
  private readonly forms = inject(FormService);
  private readonly zoomSdk = inject(ZoomSdkLoaderService);
  private readonly ngZone = inject(NgZone);

  @Input({ required: true }) batch!: BatchForm;

  @ViewChild('meetingRoot', { static: true }) meetingRoot!: ElementRef<HTMLDivElement>;

  loading = signal(true);
  error = signal('');
  warning = signal('');
  joined = signal(false);
  hostStartPending = signal(false);
  hostStarted = signal(false);

  private client: ZoomEmbeddedClient | null = null;
  private joinPayload: ZoomJoinSignature | null = null;

  ngOnInit() {
    this.forms.zoomSignature(this.batch.id).subscribe({
      next: (res) => {
        if (!res.success || !res.data) {
          this.error.set(res.message ?? 'Could not start Zoom meeting');
          this.loading.set(false);
          return;
        }

        if (res.data.hostWarning) {
          this.warning.set(res.data.hostWarning);
        }

        this.joinPayload = res.data;

        if (res.data.hostStartUrl && !res.data.zak) {
          this.hostStartPending.set(true);
          this.loading.set(false);
          return;
        }

        this.joinMeeting(res.data);
      },
      error: (err: HttpErrorResponse) => {
        this.error.set(getApiErrorMessage(err, 'Could not start Zoom meeting'));
        this.loading.set(false);
      }
    });
  }

  ngOnDestroy() {
    this.exitMeetingFullscreen();
    this.ngZone.runOutsideAngular(() => {
      try {
        this.client?.leaveMeeting();
      } catch {
        // Meeting may not have started.
      }
    });
  }

  close() {
    this.exitMeetingFullscreen();
    this.activeModal.dismiss();
  }

  openHostStart() {
    const url = this.joinPayload?.hostStartUrl;
    if (!url) {
      return;
    }
    openZoomExternalFullscreen(url, 'chess-academy-zoom-host');
    this.hostStarted.set(true);
  }

  continueJoin() {
    if (!this.joinPayload) {
      return;
    }
    this.hostStartPending.set(false);
    this.loading.set(true);
    this.error.set('');
    this.joinMeeting(this.joinPayload);
  }

  private formatJoinError(err: unknown, setupHint?: string): string {
    const zoomErr = err as {
      reason?: string;
      errorMessage?: string;
      errorCode?: number;
    };

    let message =
      zoomErr.reason ??
      zoomErr.errorMessage ??
      (err instanceof Error ? err.message : 'Could not join Zoom meeting');

    if (zoomErr.errorCode === 3712 || /invalid signature/i.test(message)) {
      message = `Signature is invalid (error 3712). ${
        setupHint ??
        'Enable Meeting SDK on your Zoom General App and set ZOOM_SDK_CLIENT_ID/SECRET in api/.env.'
      }`;
    } else if (/meeting has not started/i.test(message)) {
      message =
        'Meeting has not started. Click “Start class in Zoom” first, wait until Zoom opens, then click “Join class”.';
    }

    return message;
  }

  private joinMeeting(data: ZoomJoinSignature) {
    const root = this.meetingRoot.nativeElement;

    this.ngZone.runOutsideAngular(() => {
      this.zoomSdk
        .createClient()
        .then((client) => {
          this.client = client;
          return client.init({
            zoomAppRoot: root,
            language: 'en-US',
            patchJsMedia: true,
            leaveOnPageUnload: true
          });
        })
        .then(() => {
          const joinOptions: Record<string, string> = {
            signature: data.signature,
            meetingNumber: data.meetingNumber,
            password: data.password,
            userName: data.userName
          };
          if (data.zak) {
            joinOptions['zak'] = data.zak;
          }
          return this.client!.join(joinOptions);
        })
        .then(() => {
          this.ngZone.run(() => {
            this.loading.set(false);
            this.joined.set(true);
            void this.enterMeetingFullscreen();
          });
        })
        .catch((err: unknown) => {
          this.ngZone.run(() => {
            this.error.set(this.formatJoinError(err, data.setupHint));
            this.loading.set(false);
            if (data.hostStartUrl && !data.zak) {
              this.hostStartPending.set(true);
            }
          });
        });
    });
  }

  private async enterMeetingFullscreen(): Promise<void> {
    const el = this.meetingRoot?.nativeElement;
    if (!el) {
      return;
    }

    try {
      if (document.fullscreenElement) {
        return;
      }
      if (el.requestFullscreen) {
        await el.requestFullscreen();
      } else {
        const legacy = el as HTMLElement & { webkitRequestFullscreen?: () => Promise<void> };
        await legacy.webkitRequestFullscreen?.();
      }
    } catch {
      // Some browsers block fullscreen after async join; modal is already fullscreen-sized.
    }
  }

  private exitMeetingFullscreen(): void {
    if (!document.fullscreenElement) {
      return;
    }
    document.exitFullscreen().catch(() => {});
  }
}
