-- Live match event sequence for SSE / WebSocket push
ALTER TABLE chess_live_matches
  ADD COLUMN event_seq INT UNSIGNED NOT NULL DEFAULT 0 AFTER updated_at;
