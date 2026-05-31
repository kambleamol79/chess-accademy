/**
 * Optional WebSocket server for live chess matches.
 * Run: cd api/realtime && npm install && node ws-server.mjs
 *
 * Env: LIVE_WS_PORT=8091, LIVE_WS_INTERNAL_SECRET=..., JWT_SECRET=... (from api/.env)
 */
import http from 'http';
import { WebSocketServer } from 'ws';
import { createHmac } from 'crypto';
import { readFileSync, existsSync } from 'fs';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));

function loadEnv() {
  const envPath = resolve(__dirname, '../.env');
  const out = {};
  if (!existsSync(envPath)) return out;
  for (const line of readFileSync(envPath, 'utf8').split('\n')) {
    const t = line.trim();
    if (!t || t.startsWith('#')) continue;
    const i = t.indexOf('=');
    if (i < 1) continue;
    let v = t.slice(i + 1).trim();
    if ((v.startsWith('"') && v.endsWith('"')) || (v.startsWith("'") && v.endsWith("'"))) {
      v = v.slice(1, -1);
    }
    out[t.slice(0, i).trim()] = v;
  }
  return out;
}

const env = { ...loadEnv(), ...process.env };
const PORT = Number(env.LIVE_WS_PORT || 8091);
const SECRET = env.LIVE_WS_INTERNAL_SECRET || 'change-me-live-ws-secret';
const JWT_SECRET = env.JWT_SECRET || '';

/** @type {Map<number, Set<import('ws').WebSocket>>} */
const rooms = new Map();

function verifyJwt(token) {
  if (!token || !JWT_SECRET) return false;
  const parts = token.split('.');
  if (parts.length !== 3) return false;
  const [header, payload, sig] = parts;
  const expected = createHmac('sha256', JWT_SECRET)
    .update(`${header}.${payload}`)
    .digest('base64url');
  return sig === expected;
}

function roomAdd(matchId, ws) {
  if (!rooms.has(matchId)) rooms.set(matchId, new Set());
  rooms.get(matchId).add(ws);
}

function roomRemove(matchId, ws) {
  const set = rooms.get(matchId);
  if (!set) return;
  set.delete(ws);
  if (set.size === 0) rooms.delete(matchId);
}

function broadcast(matchId, data) {
  const set = rooms.get(matchId);
  if (!set) return;
  const msg = JSON.stringify(data);
  for (const ws of set) {
    if (ws.readyState === 1) ws.send(msg);
  }
}

const server = http.createServer((req, res) => {
  if (req.method === 'POST' && req.url === '/broadcast') {
    const auth = req.headers['x-live-secret'];
    if (auth !== SECRET) {
      res.writeHead(403);
      res.end('forbidden');
      return;
    }
    let body = '';
    req.on('data', (c) => (body += c));
    req.on('end', () => {
      try {
        const data = JSON.parse(body);
        if (data.match_id) broadcast(Number(data.match_id), data);
        res.writeHead(200);
        res.end('ok');
      } catch {
        res.writeHead(400);
        res.end('bad json');
      }
    });
    return;
  }
  res.writeHead(404);
  res.end();
});

const wss = new WebSocketServer({ server });

wss.on('connection', (ws, req) => {
  const url = new URL(req.url || '/', `http://127.0.0.1:${PORT}`);
  const matchId = Number(url.searchParams.get('match_id'));
  const token = url.searchParams.get('token') || '';

  if (!matchId || !verifyJwt(token)) {
    ws.close(4001, 'unauthorized');
    return;
  }

  roomAdd(matchId, ws);
  ws.on('message', (raw) => {
    let data;
    try {
      data = JSON.parse(String(raw));
    } catch {
      return;
    }
    if (data?.kind !== 'voice') return;
    const msg = JSON.stringify(data);
    const set = rooms.get(matchId);
    if (!set) return;
    for (const peer of set) {
      if (peer !== ws && peer.readyState === 1) {
        peer.send(msg);
      }
    }
  });
  ws.on('close', () => roomRemove(matchId, ws));
  ws.send(JSON.stringify({ type: 'connected', match_id: matchId }));
});

server.listen(PORT, () => {
  console.log(`Live match WebSocket listening on ws://127.0.0.1:${PORT}`);
  console.log(`Broadcast HTTP POST http://127.0.0.1:${PORT}/broadcast`);
});
