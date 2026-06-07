# Deploy Brainstorm to Hostinger (`/brainstorm/`)

## Target layout on server

```
public_html/brainstorm/
  .htaccess                    ← deploy/hostinger/brainstorm.htaccess
  index.html                   ← Angular build (dist/)
  *.js, *.css, assets/         ← Angular build
  api/
    .env                       ← production secrets (not in git)
    vendor/                    ← composer install output
    public/index.php
    src/, config/, ...
```

## Build locally

```bash
yarn install
yarn build:brainstorm

cd api
composer install --no-dev --optimize-autoloader
```

Upload **contents of `dist/`** into `public_html/brainstorm/` and the full **`api/`** folder into `public_html/brainstorm/api/`.

## Server setup

1. Copy `deploy/hostinger/brainstorm.htaccess` → `public_html/brainstorm/.htaccess`
2. Create `api/.env` from `api/.env.example` with Hostinger MySQL credentials
3. Set production values:
   - `APP_ENV=production`
   - `APP_DEBUG=false`
   - `APP_BASE_PATH=/brainstorm`
   - `CORS_ORIGIN=https://alphasynctechnology.com`
   - `CORS_ALLOW_LOCAL_DEV=false`
   - Strong `JWT_SECRET`
4. Import database: `mysql … chess_academy < dumpv.sql` (or schema + seeds)
5. Ensure `api/var` and `api/storage` are writable by PHP

## Verify

```bash
curl -s https://alphasynctechnology.com/brainstorm/api/v1/health
# {"success":true,"data":{"status":"ok",...}}

curl -sI https://alphasynctechnology.com/brainstorm/
# HTTP/2 200, text/html (not 500)
```

## Common errors

| Symptom | Fix |
|--------|-----|
| **403** on `/brainstorm/api/` | Upload `api/index.php` + replace `api/.htaccess` from repo. Run `composer install` in `api/`. |
| **403** on `/brainstorm/` | Upload Angular `dist/` (`index.html` required). Use `deploy/hostinger/brainstorm.htaccess` (do not pass directory requests through unchanged). |
| Blank **500** on every URL | Run `composer install` inside `brainstorm/api` |
| 500 after git pull | Upload **all** changed PHP files together (container + controllers) |
| API **404** | Copy `api/index.php`, `api/.htaccess`, and `deploy/hostinger/brainstorm.htaccess`; set `APP_BASE_PATH=/brainstorm` |
| App loads but login fails | Fix `api/.env` DB_* and import `dumpv.sql` |

### Permissions (Hostinger)

- Folders: `755`
- Files: `644`
- `api/var` and `api/storage`: `755` (writable by PHP)
