# Brainstorm Chess Academy — Student App

Flutter mobile app for students (MVC architecture) with batch schedule, payments, reminders, notifications, and a chess practice board.

## Brand theme

- Primary blue: `#003B71`
- Accent orange: `#FF4500`
- Background: white / light blue

## Structure (MVC)

```
lib/
  config/       # App config & theme
  models/       # Data models
  services/     # API & storage (data layer)
  controllers/  # Business logic (ChangeNotifier)
  views/        # Screens
  widgets/      # Reusable UI components
```

## Requirements

- Flutter 3.10+
- Chess Academy API running at `http://localhost:8080`

## Run

```bash
cd student_app
flutter pub get

# 1) Start API (from repo root) — use 0.0.0.0 so phones/emulators can connect
cd api && php -S 0.0.0.0:8080 -t public

# 2) Run app (pick your target)
```

| Target | Command |
|--------|---------|
| **Android emulator** | `flutter run -d emulator-5554` (uses `10.0.2.2` automatically) |
| **Physical phone (Wi‑Fi)** | `flutter run --dart-define=API_HOST=192.168.1.15 -d <device-id>` |
| **Physical phone (USB)** | `adb reverse tcp:8080 tcp:8080` then `flutter run --dart-define=API_HOST=127.0.0.1` |
| **iOS simulator / macOS** | `flutter run` (uses `localhost`) |

Find your Mac's IP: `ipconfig getifaddr en0`

Full URL override: `--dart-define=API_URL=http://192.168.1.15:8080/api/v1`

## Student API endpoints

| Endpoint | Description |
|---|---|
| `POST /auth/login` | Sign in (student role only) |
| `GET /auth/me` | Current user profile |
| `GET /students/me/batch` | Assigned batch |
| `GET /students/me/payments` | Payment history |
| `GET /students/me/reminders` | Class & payment reminders |
| `GET /students/me/notifications` | Academy notifications |

## Features

- **Home** — Welcome dashboard with batch summary and reminders
- **My Batch** — Schedule, coaches, Zoom join link
- **Payments** — Invoices and monthly payment records
- **Reminders** — Upcoming classes, dues, practice nudges
- **Notifications** — Batch assignment and payment alerts
- **Board** — Play vs **Stockfish** (on-device, Android/iOS) or free play; built-in engine fallback on desktop/web
