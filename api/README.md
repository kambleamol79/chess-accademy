# Chess Academy API

PHP Slim 4 REST API with JWT auth and MySQL database **`chess_academy`**.

## Setup

```bash
cd api
cp .env.example .env
# Edit DB_USER, DB_PASS, JWT_SECRET
composer install
```

Import database (order matters):

```bash
mysql -u root -p < database/schema.sql
mysql -u root -p < database/seeds/forms_seed.sql
mysql -u root -p < database/seeds/admin_seed.sql
mysql -u root -p < database/seeds/coach_seed.sql
# optional:
mysql -u root -p < database/seeds/sample_data.sql
```

Run server:

```bash
php -S localhost:8080 -t public
```

**Default admin:** `admin@chessacademy.local` / `Admin@123456`  
**Default coach:** `coach@chessacademy.local` / `Coach@123456` (students + batch assign)

## Zoom details on batches

Batch schedules store manual Zoom details entered by an admin: meeting link, optional username, and optional password.

Run migration if upgrading an existing database that already has the earlier Zoom columns:

```bash
mysql -u root chess_academy < database/manual_zoom_fields_migration.sql
```

## Messaging (support + batch announcements)

Run migration on existing databases:

```bash
mysql -u root chess_academy < database/messaging_migration.sql
```

**Student support (student ↔ admin only)**

| Method | URL | Roles |
|--------|-----|-------|
| GET | `/api/v1/students/me/support-tickets` | student |
| POST | `/api/v1/students/me/support-tickets` | student |
| GET | `/api/v1/students/me/support-tickets/{id}` | student |
| POST | `/api/v1/students/me/support-tickets/{id}/messages` | student |
| GET | `/api/v1/support-tickets` | admin |
| GET | `/api/v1/support-tickets/{id}` | admin |
| POST | `/api/v1/support-tickets/{id}/messages` | admin |
| PATCH | `/api/v1/support-tickets/{id}` | admin (`assign_self`, `status: resolved`, `resolution_comment`) |

**Batch messages (admin sends; visible to enrolled students + assigned coaches)**

| Method | URL | Roles |
|--------|-----|-------|
| GET | `/api/v1/forms/{form_id}/messages` | admin, coach, student |
| POST | `/api/v1/forms/{form_id}/messages` | admin |
| GET | `/api/v1/students/me/batch-messages` | student |

## Auth

| Method | URL | Auth |
|--------|-----|------|
| POST | `/api/v1/auth/login` | — |
| POST | `/api/v1/auth/register` | — |
| POST | `/api/v1/auth/refresh` | — |
| POST | `/api/v1/auth/logout` | — |
| GET | `/api/v1/auth/me` | Bearer JWT |

### Login

```bash
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@chessacademy.local","password":"Admin@123456"}'
```

Response:

```json
{
  "success": true,
  "data": {
    "user": { "id": 1, "email": "...", "role": "admin", ... },
    "access_token": "...",
    "refresh_token": "..."
  }
}
```

Use header on protected routes: `Authorization: Bearer <access_token>`

## Database tables

| Table | Purpose |
|-------|---------|
| `users` | Login accounts (roles: admin, coach, student, accountant) |
| `refresh_tokens` | JWT refresh tokens |
| `forms` | Batch schedule (spreadsheet structure) |
| `coaches` | Coach profiles |
| `students` | Student profiles |
| `form_enrollments` | Students enrolled in a batch (`form_id`) |
| `invoices` | Billing |
| `puzzles` / `puzzle_attempts` | Training puzzles |
| `games` | Game review (PGN) |
| `settings` | Academy settings (JSON key/value) |

## Protected endpoints (require JWT)

| Resource | Base URL |
|----------|----------|
| Dashboard metrics | `GET /api/v1/dashboard/metrics` |
| Students | `/api/v1/students` |
| Coaches | `/api/v1/coaches` (write: admin) |
| Batch schedule | `/api/v1/forms` |
| Enrollments | `/api/v1/enrollments` |
| Billing | `/api/v1/billing/invoices` |
| Puzzles | `/api/v1/puzzles`, `POST .../attempt` |
| Game review | `/api/v1/games` |
| Settings | `/api/v1/settings` (admin) |
| Staff users | `GET/POST /api/v1/users`, `PATCH /api/v1/users/{id}` (password; admin only) |

## `forms` columns (spreadsheet)

`highlight`, `batch`, `module`, `time`, `days_summary`, `day_1`, `coach_1`, `day_2`, `coach_2`, `notes`

## Roles

- **admin** — full access
- **coach** — students (add), assign students to **own** batches only (`coach_1` / `coach_2` on batch), dashboard schedule
- **student** — own profile, puzzles, games, student portal (`/students/me/*`)
- **accountant** — billing

## Live chess (student vs student)

Migrations:

```bash
php scripts/migrate_chess_competition.php
php scripts/migrate_live_match_events.php
```

- Moves are validated on the server with `akondas/chess.php` (illegal moves rejected; checkmate/draw auto-finish).
- Real-time updates: **SSE** `GET /live-matches/{id}/stream?since=0` (works with PHP built-in server).
- Optional **WebSocket** (lower latency):

```bash
cd api/realtime && npm install && node ws-server.mjs
```

In `api/.env`:

```env
LIVE_WS_ENABLED=true
LIVE_WS_BROADCAST_URL=http://127.0.0.1:8091/broadcast
LIVE_WS_INTERNAL_SECRET=change-me-live-ws-secret
```

Angular `environment.liveWsUrl`: `ws://127.0.0.1:8091` (optional)  
Flutter: `--dart-define=LIVE_WS_URL=...` (optional)

**Important for local dev:** `php -S` handles **one request at a time**. Do **not** use the SSE `/stream` endpoint with the built-in server — it blocks other players for tens of seconds. Live matches use fast **revision polling** (`/revision?since=N`) instead.

### Auto-resign idle games (cron)

If the student on move does not play for **`time_control_minutes + 10`** minutes (configurable grace), a cron job ends the match as a timeout loss for that player.

```bash
mkdir -p var/log
php scripts/auto_resign_inactive_matches.php
```

Install cron (edit path in `cron/live_match_auto_resign.cron`):

```bash
crontab -e
# * * * * * cd /path/to/chess-accademy/api && php scripts/auto_resign_inactive_matches.php >> var/log/live_match_auto_resign.log 2>&1
```

Optional in `.env`: `LIVE_MATCH_IDLE_GRACE_MINUTES=10` (extra minutes after the match time control).

### Voice chat (live match)

Students can use **Join voice** / **Mute** in the CRM chess arena during an active match. Audio is peer-to-peer (WebRTC) with signaling via `POST/GET /live-matches/{id}/voice/signals`. Optional WebSocket (`liveWsUrl`) relays signaling faster when `api/realtime/ws-server.mjs` is running.

Requires HTTPS or `localhost`, and browser microphone permission.

## Angular

```typescript
apiUrl: 'http://localhost:8080/api/v1'
liveWsUrl: 'ws://127.0.0.1:8091' // optional; omit for SSE-only
```
