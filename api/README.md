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
# optional:
mysql -u root -p < database/seeds/sample_data.sql
```

Run server:

```bash
php -S localhost:8080 -t public
```

**Default admin:** `admin@chessacademy.local` / `Admin@123456`

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
| `class_materials` | Materials per batch row |
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
| Materials | `/api/v1/materials?form_id=` |
| Settings | `/api/v1/settings` (admin) |

## `forms` columns (spreadsheet)

`highlight`, `batch`, `module`, `time`, `days_summary`, `day_1`, `coach_1`, `day_2`, `coach_2`, `notes`

## Roles

- **admin** — full access
- **coach** — forms, enrollments, puzzles, games, materials
- **student** — own profile, puzzles, games, materials (read)
- **accountant** — billing

## Angular

```typescript
apiUrl: 'http://localhost:8080/api/v1'
```
