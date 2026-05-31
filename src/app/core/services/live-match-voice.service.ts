import { HttpClient } from '@angular/common/http';
import { Injectable, inject, signal } from '@angular/core';
import { Subscription, firstValueFrom, timer } from 'rxjs';
import { exhaustMap } from 'rxjs/operators';
import { environment } from 'src/environments/environment';
import { ApiResponse } from '../models/api.model';
import { AuthService } from './auth.service';
import { LiveMatchState } from '../models/chess-arena.model';

type SignalType = 'offer' | 'answer' | 'ice';

interface VoiceSignalMessage {
  seq: number;
  type: SignalType;
  payload: RTCSessionDescriptionInit | RTCIceCandidateInit;
}

interface WsVoiceEnvelope {
  kind: 'voice';
  type: SignalType;
  payload: RTCSessionDescriptionInit | RTCIceCandidateInit;
}

const ICE_SERVERS: RTCConfiguration = {
  iceServers: [
    { urls: 'stun:stun.l.google.com:19302' },
    { urls: 'stun:stun1.l.google.com:19302' },
    {
      urls: [
        'turn:openrelay.metered.ca:80',
        'turn:openrelay.metered.ca:443',
        'turns:openrelay.metered.ca:443?transport=tcp'
      ],
      username: 'openrelayproject',
      credential: 'openrelayproject'
    }
  ],
  iceCandidatePoolSize: 10
};

@Injectable({ providedIn: 'root' })
export class LiveMatchVoiceService {
  private readonly http = inject(HttpClient);
  private readonly auth = inject(AuthService);

  readonly active = signal(false);
  readonly muted = signal(false);
  readonly connected = signal(false);
  readonly error = signal('');

  private matchId = 0;
  private initiator = false;
  private lastSeq = 0;
  private pc: RTCPeerConnection | null = null;
  private localStream: MediaStream | null = null;
  private remoteAudio: HTMLAudioElement | null = null;
  private pollSub: Subscription | null = null;
  private ws: WebSocket | null = null;
  private makingOffer = false;
  private pendingIce: RTCIceCandidateInit[] = [];
  private signalChain: Promise<void> = Promise.resolve();
  private remoteStream: MediaStream | null = null;

  async join(matchId: number, state: LiveMatchState, remoteAudioEl: HTMLAudioElement): Promise<void> {
    if (this.active()) {
      return;
    }
    this.error.set('');
    this.matchId = matchId;
    this.initiator = state.your_color === 'white';
    this.remoteAudio = remoteAudioEl;
    this.lastSeq = 0;
    this.pendingIce = [];
    this.signalChain = Promise.resolve();
    this.remoteStream = null;

    remoteAudioEl.volume = 1;
    remoteAudioEl.muted = false;

    if (this.initiator) {
      try {
        await firstValueFrom(
          this.http.post<ApiResponse<unknown>>(`${environment.apiUrl}/live-matches/${matchId}/voice/clear`, {})
        );
      } catch {
        /* continue */
      }
    }

    try {
      this.localStream = await navigator.mediaDevices.getUserMedia({
        audio: { echoCancellation: true, noiseSuppression: true },
        video: false
      });
    } catch {
      this.error.set('Microphone access denied or unavailable');
      return;
    }

    this.pc = new RTCPeerConnection(ICE_SERVERS);
    for (const track of this.localStream.getTracks()) {
      this.pc.addTrack(track, this.localStream);
    }

    this.pc.ontrack = (ev) => {
      if (!ev.track) return;
      if (!this.remoteStream) {
        this.remoteStream = new MediaStream();
      }
      const exists = this.remoteStream.getTracks().some((t) => t.id === ev.track.id);
      if (!exists) {
        this.remoteStream.addTrack(ev.track);
      }
      if (this.remoteAudio) {
        this.remoteAudio.srcObject = this.remoteStream;
        void this.playRemoteAudio();
      }
      this.connected.set(true);
    };

    this.pc.onicecandidate = (ev) => {
      if (ev.candidate) {
        void this.sendSignal('ice', ev.candidate.toJSON());
      }
    };

    this.pc.onconnectionstatechange = () => {
      const st = this.pc?.connectionState;
      if (st === 'failed' || st === 'disconnected') {
        this.error.set('Voice connection lost — try Leave voice then Join again');
      }
      if (st === 'connected') {
        this.connected.set(true);
        this.error.set('');
        void this.playRemoteAudio();
      }
    };

    this.connectSignalingTransport();
    this.startPolling();
    await this.pollSignalsOnce();

    if (this.initiator) {
      await this.createOffer();
    }

    this.active.set(true);
    this.muted.set(false);
  }

  leave(): void {
    this.stopPolling();
    this.ws?.close();
    this.ws = null;
    this.pc?.close();
    this.pc = null;
    this.localStream?.getTracks().forEach((t) => t.stop());
    this.localStream = null;
    this.remoteStream = null;
    if (this.remoteAudio) {
      this.remoteAudio.srcObject = null;
    }
    this.remoteAudio = null;
    this.matchId = 0;
    this.pendingIce = [];
    this.active.set(false);
    this.muted.set(false);
    this.connected.set(false);
    this.error.set('');
  }

  toggleMute(): void {
    const next = !this.muted();
    this.localStream?.getAudioTracks().forEach((t) => (t.enabled = !next));
    this.muted.set(next);
  }

  private async playRemoteAudio(): Promise<void> {
    if (!this.remoteAudio) return;
    try {
      await this.remoteAudio.play();
    } catch {
      this.error.set('Click Join voice again if you cannot hear your opponent');
    }
  }

  private connectSignalingTransport(): void {
    const base = environment.liveWsUrl?.trim();
    const token = this.auth.getToken();
    if (!base || !token || !this.matchId) {
      return;
    }

    const url = `${base}?match_id=${this.matchId}&token=${encodeURIComponent(token)}`;
    this.ws = new WebSocket(url);
    this.ws.onmessage = (ev) => {
      try {
        const data = JSON.parse(ev.data as string) as WsVoiceEnvelope;
        if (data.kind === 'voice' && data.type && data.payload) {
          this.enqueueSignal({ seq: 0, type: data.type, payload: data.payload });
        }
      } catch {
        /* ignore */
      }
    };
  }

  private startPolling(): void {
    this.stopPolling();
    this.pollSub = timer(0, 400)
      .pipe(
        exhaustMap(() =>
          this.http.get<ApiResponse<{ signals: VoiceSignalMessage[] }>>(
            `${environment.apiUrl}/live-matches/${this.matchId}/voice/signals`,
            { params: { since: String(this.lastSeq) } }
          )
        )
      )
      .subscribe({
        next: (res) => this.ingestSignals(res.data?.signals ?? []),
        error: () => undefined
      });
  }

  private async pollSignalsOnce(): Promise<void> {
    try {
      const res = await firstValueFrom(
        this.http.get<ApiResponse<{ signals: VoiceSignalMessage[] }>>(
          `${environment.apiUrl}/live-matches/${this.matchId}/voice/signals`,
          { params: { since: String(this.lastSeq) } }
        )
      );
      this.ingestSignals(res.data?.signals ?? []);
    } catch {
      /* ignore */
    }
  }

  private ingestSignals(signals: VoiceSignalMessage[]): void {
    for (const sig of signals) {
      if (sig.seq > this.lastSeq) {
        this.lastSeq = sig.seq;
      }
      this.enqueueSignal(sig);
    }
  }

  private enqueueSignal(sig: VoiceSignalMessage): void {
    this.signalChain = this.signalChain.then(() => this.processSignal(sig)).catch(() => undefined);
  }

  private stopPolling(): void {
    this.pollSub?.unsubscribe();
    this.pollSub = null;
  }

  private async createOffer(): Promise<void> {
    if (!this.pc || this.makingOffer) return;
    this.makingOffer = true;
    try {
      const offer = await this.pc.createOffer({ offerToReceiveAudio: true });
      await this.pc.setLocalDescription(offer);
      await this.sendSignal('offer', this.pc.localDescription!.toJSON());
    } catch {
      this.error.set('Could not start voice offer');
    } finally {
      this.makingOffer = false;
    }
  }

  private async processSignal(sig: VoiceSignalMessage): Promise<void> {
    if (!this.pc) return;

    if (sig.type === 'offer') {
      if (this.initiator) return;
      if (this.pc.signalingState !== 'stable') return;

      await this.pc.setRemoteDescription(new RTCSessionDescription(sig.payload as RTCSessionDescriptionInit));
      await this.flushPendingIce();
      const answer = await this.pc.createAnswer();
      await this.pc.setLocalDescription(answer);
      await this.sendSignal('answer', this.pc.localDescription!.toJSON());
      return;
    }

    if (sig.type === 'answer') {
      if (!this.initiator) return;
      if (this.pc.signalingState !== 'have-local-offer') return;

      await this.pc.setRemoteDescription(new RTCSessionDescription(sig.payload as RTCSessionDescriptionInit));
      await this.flushPendingIce();
      return;
    }

    if (sig.type === 'ice' && sig.payload) {
      await this.addIceCandidate(sig.payload as RTCIceCandidateInit);
    }
  }

  private async addIceCandidate(candidate: RTCIceCandidateInit): Promise<void> {
    if (!this.pc?.remoteDescription) {
      this.pendingIce.push(candidate);
      return;
    }
    try {
      await this.pc.addIceCandidate(new RTCIceCandidate(candidate));
    } catch {
      this.pendingIce.push(candidate);
    }
  }

  private async flushPendingIce(): Promise<void> {
    if (!this.pc?.remoteDescription) return;
    const batch = this.pendingIce.splice(0);
    for (const c of batch) {
      try {
        await this.pc.addIceCandidate(new RTCIceCandidate(c));
      } catch {
        /* skip invalid */
      }
    }
  }

  private async sendSignal(type: SignalType, payload: RTCSessionDescriptionInit | RTCIceCandidateInit): Promise<void> {
    if (!this.matchId) return;

    const envelope: WsVoiceEnvelope = { kind: 'voice', type, payload };
    if (this.ws?.readyState === WebSocket.OPEN) {
      this.ws.send(JSON.stringify(envelope));
    }

    try {
      await firstValueFrom(
        this.http.post<ApiResponse<{ seq: number }>>(`${environment.apiUrl}/live-matches/${this.matchId}/voice/signals`, {
          type,
          payload
        })
      );
    } catch {
      this.error.set('Voice signaling failed — check API connection');
    }
  }
}
