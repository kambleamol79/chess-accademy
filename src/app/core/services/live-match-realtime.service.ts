import { Injectable, inject, OnDestroy } from '@angular/core';
import { Observable, Subject } from 'rxjs';
import { environment } from 'src/environments/environment';
import { AuthService } from './auth.service';
import { LiveMatchState } from '../models/chess-arena.model';

export interface LiveMatchRealtimeEvent {
  event_seq: number;
  state?: LiveMatchState;
}

@Injectable({ providedIn: 'root' })
export class LiveMatchRealtimeService implements OnDestroy {
  private readonly auth = inject(AuthService);

  private ws: WebSocket | null = null;
  private es: EventSource | null = null;
  private activeMatchId = 0;
  private lastSeq = 0;
  private useSse = false;
  private readonly events$ = new Subject<LiveMatchRealtimeEvent>();

  ngOnDestroy(): void {
    this.disconnect();
  }

  watch(matchId: number, sinceSeq = 0): Observable<LiveMatchRealtimeEvent> {
    this.disconnect();
    this.activeMatchId = matchId;
    this.lastSeq = sinceSeq;
    this.useSse = false;

    const wsUrl = environment.liveWsUrl?.trim();
    if (wsUrl) {
      this.connectWebSocket(matchId, wsUrl);
    } else {
      this.connectSse(matchId, sinceSeq);
    }
    return this.events$.asObservable();
  }

  disconnect(): void {
    this.ws?.close();
    this.ws = null;
    this.es?.close();
    this.es = null;
    this.activeMatchId = 0;
    this.useSse = false;
  }

  private connectWebSocket(matchId: number, baseUrl: string): void {
    const token = this.auth.getToken();
    if (!token) {
      this.connectSse(matchId, this.lastSeq);
      return;
    }

    const url = `${baseUrl}?match_id=${matchId}&token=${encodeURIComponent(token)}`;
    this.ws = new WebSocket(url);

    const failToSse = (): void => {
      if (this.useSse || this.activeMatchId !== matchId) return;
      this.useSse = true;
      this.ws?.close();
      this.ws = null;
      this.connectSse(matchId, this.lastSeq);
    };

    const failTimer = setTimeout(failToSse, 3000);

    this.ws.onopen = () => clearTimeout(failTimer);
    this.ws.onerror = () => {
      clearTimeout(failTimer);
      failToSse();
    };
    this.ws.onmessage = (ev) => {
      try {
        const data = JSON.parse(ev.data as string) as { event_seq?: number; type?: string };
        if (data.event_seq != null && data.event_seq > this.lastSeq) {
          this.lastSeq = data.event_seq;
          this.events$.next({ event_seq: data.event_seq });
        }
      } catch {
        /* ignore */
      }
    };
    this.ws.onclose = () => {
      clearTimeout(failTimer);
      if (this.activeMatchId === matchId && !this.useSse) {
        setTimeout(() => this.connectWebSocket(matchId, baseUrl), 2000);
      }
    };
  }

  private connectSse(matchId: number, sinceSeq: number): void {
    const token = this.auth.getToken();
    if (!token) return;

    const url = `${environment.apiUrl}/live-matches/${matchId}/stream?since=${sinceSeq}&access_token=${encodeURIComponent(token)}`;
    this.es = new EventSource(url);
    this.es.addEventListener('update', (ev) => {
      try {
        const data = JSON.parse((ev as MessageEvent).data) as LiveMatchRealtimeEvent;
        if (data.event_seq > this.lastSeq) {
          this.lastSeq = data.event_seq;
          this.events$.next(data);
        }
      } catch {
        /* ignore */
      }
    });
    this.es.onerror = () => {
      this.es?.close();
      this.es = null;
      if (this.activeMatchId === matchId) {
        setTimeout(() => this.connectSse(matchId, this.lastSeq), 2000);
      }
    };
  }
}
