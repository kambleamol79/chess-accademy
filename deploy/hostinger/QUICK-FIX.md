# Quick fix: "This Page Does Not Exist" on login URL

Your login URL is correct:

`POST https://alphasynctechnology.com/brainstorm/api/v1/auth/login`

Hostinger returns 404 because the rewrite pointed to **missing** `api/index.php`.
Your files are under **`api/public/`**.

## Do this in Hostinger File Manager

### 1. `public_html/brainstorm/.htaccess`

Paste the contents of `deploy/hostinger/brainstorm.htaccess` (rewrites to `api/public/index.php`).

### 2. `public_html/brainstorm/api/.htaccess`

Paste the contents of `api/.htaccess` from the repo.

### 3. Re-upload the real API (important)

Upload the full `api/` folder from your computer, especially:

- `api/public/index.php` (must be ~83 lines, Slim — not a tiny test file)
- `api/vendor/` (run `composer install` in `api/` locally, then upload `vendor/`)
- `api/config/`, `api/src/`, `api/.env`

If `api/public/index.php` only prints `5` or blank, it is the wrong file — replace it.

### 4. `api/.env` on server

```env
APP_ENV=production
APP_DEBUG=true
APP_BASE_PATH=/brainstorm

DB_HOST=localhost
DB_NAME=your_db_name
DB_USER=your_db_user
DB_PASS=your_db_password

JWT_SECRET=long-random-string
CORS_ORIGIN=https://alphasynctechnology.com
```

### 5. Test

```bash
curl -s https://alphasynctechnology.com/brainstorm/api/v1/health
```

```bash
curl -s -X POST https://alphasynctechnology.com/brainstorm/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@chessacademy.local","password":"Admin@123456"}'
```

Both must return **JSON**, not an HTML "page does not exist".
