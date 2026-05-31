import { Injectable, signal } from '@angular/core';
import { Chess } from 'chess.js';
import { ChessMove, ComputerLevel } from '../models/chess-practice.model';
import { ChessEngineService } from './chess-engine.service';
import { stockfishLevelConfig } from '../utils/stockfish-level.util';

@Injectable({ providedIn: 'root' })
export class StockfishEngineService {
  private readonly builtin = new ChessEngineService();

  private worker: Worker | null = null;
  private ready = false;
  private initAbandoned = false;
  private initializing = false;
  private initPromise: Promise<void> | null = null;
  private disposed = false;

  private bestMoveWaiter: {
    resolve: (line: string) => void;
    reject: (err: Error) => void;
  } | null = null;
  private readyOkWaiter: (() => void) | null = null;

  private searchChain: Promise<void> = Promise.resolve();

  readonly engineLabel = signal('Stockfish');

  async ensureReady(): Promise<void> {
    if (this.ready || this.initAbandoned || this.disposed) {
      return;
    }
    if (this.initializing && this.initPromise) {
      return this.initPromise;
    }
    this.initializing = true;
    this.initPromise = this.initialize();
    return this.initPromise;
  }

  async pickMove(fen: string, level: ComputerLevel): Promise<ChessMove | null> {
    return this.enqueueSearch(() => this.pickMoveWithFallback(fen, level));
  }

  dispose(): void {
    this.disposed = true;
    this.terminateWorker();
  }

  private async initialize(): Promise<void> {
    if (typeof Worker === 'undefined') {
      this.initAbandoned = true;
      this.engineLabel.set('Built-in engine');
      this.initializing = false;
      return;
    }

    try {
      await new Promise<void>((resolve, reject) => {
        const worker = new Worker('/assets/stockfish/stockfish.worker.js');
        let uciOk = false;

        const timeout = setTimeout(() => {
          reject(new Error('Stockfish worker timeout'));
        }, 25000);

        worker.onmessage = (ev: MessageEvent<string>) => {
          const line = String(ev.data ?? '').trim();
          if (!line) return;

          if (line === 'uciok' && !uciOk) {
            uciOk = true;
            worker.postMessage('isready');
            return;
          }

          if (line === 'readyok' && uciOk && !this.ready) {
            clearTimeout(timeout);
            this.worker = worker;
            this.ready = true;
            this.engineLabel.set('Stockfish');
            resolve();
            return;
          }

          if (line.startsWith('bestmove ') && this.bestMoveWaiter) {
            this.bestMoveWaiter.resolve(line);
            this.bestMoveWaiter = null;
            return;
          }

          if (line === 'readyok' && this.readyOkWaiter) {
            this.readyOkWaiter();
            this.readyOkWaiter = null;
          }
        };

        worker.onerror = () => {
          clearTimeout(timeout);
          reject(new Error('Stockfish worker error'));
        };

        worker.postMessage('uci');
      });
    } catch {
      this.initAbandoned = true;
      this.engineLabel.set('Built-in engine');
      this.terminateWorker();
      this.ready = false;
    } finally {
      this.initializing = false;
    }
  }

  private async pickMoveWithFallback(fen: string, level: ComputerLevel): Promise<ChessMove | null> {
    if (!this.initAbandoned) {
      try {
        await this.ensureReady();
      } catch {
        this.initAbandoned = true;
        this.engineLabel.set('Built-in engine');
      }
    }

    if (this.ready && this.worker) {
      const cfg = stockfishLevelConfig(level);
      try {
        const move = await this.pickMoveStockfish(fen, cfg);
        if (move) return move;
      } catch {
        // fall through
      }
    }

    return this.builtin.pickMove(new Chess(fen), level);
  }

  private async pickMoveStockfish(fen: string, cfg: ReturnType<typeof stockfishLevelConfig>): Promise<ChessMove | null> {
    const worker = this.worker;
    if (!worker) return null;

    this.configureLevel(worker, cfg);
    worker.postMessage(`position fen ${fen}`);
    await this.waitReadyOk(worker);

    const line = await new Promise<string>((resolve, reject) => {
      this.bestMoveWaiter = { resolve, reject };
      worker.postMessage(`go movetime ${cfg.movetimeMs}`);

      setTimeout(() => {
        if (this.bestMoveWaiter) {
          worker.postMessage('stop');
          this.bestMoveWaiter.resolve('bestmove (none)');
          this.bestMoveWaiter = null;
        }
      }, cfg.movetimeMs + 5000);
    });

    return this.parseBestMove(line);
  }

  private configureLevel(worker: Worker, cfg: ReturnType<typeof stockfishLevelConfig>): void {
    if (cfg.limitStrength) {
      worker.postMessage('setoption name UCI_LimitStrength value true');
      worker.postMessage(`setoption name UCI_Elo value ${cfg.elo}`);
    } else {
      worker.postMessage('setoption name UCI_LimitStrength value false');
    }
    worker.postMessage(`setoption name Skill Level value ${cfg.skill}`);
  }

  private waitReadyOk(worker: Worker): Promise<void> {
    return new Promise((resolve) => {
      this.readyOkWaiter = resolve;
      worker.postMessage('isready');
      setTimeout(() => {
        if (this.readyOkWaiter) {
          this.readyOkWaiter();
          this.readyOkWaiter = null;
        }
      }, 3000);
    });
  }

  private parseBestMove(line: string): ChessMove | null {
    const parts = line.split(/\s+/);
    if (parts.length < 2 || parts[1] === '(none)') return null;

    const uci = parts[1];
    if (uci.length < 4) return null;

    return {
      from: uci.substring(0, 2),
      to: uci.substring(2, 4),
      promotion: uci.length > 4 ? uci.substring(4) : 'q'
    };
  }

  private enqueueSearch<T>(search: () => Promise<T>): Promise<T> {
    const run = this.searchChain.then(() => search());
    this.searchChain = run.then(
      () => undefined,
      () => undefined
    );
    return run;
  }

  private terminateWorker(): void {
    this.bestMoveWaiter = null;
    this.readyOkWaiter = null;
    if (this.worker) {
      try {
        this.worker.postMessage('quit');
      } catch {
        // ignore
      }
      this.worker.terminate();
      this.worker = null;
    }
    this.ready = false;
  }
}
