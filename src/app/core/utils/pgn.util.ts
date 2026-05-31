import { Chess } from 'chess.js';

export interface PgnParseResult {
  valid: boolean;
  error?: string;
  headers: Record<string, string>;
  suggestedTitle?: string;
  moveCount: number;
  fens: string[];
}

export function parsePgnHeaders(pgn: string): Record<string, string> {
  const headers: Record<string, string> = {};
  for (const line of pgn.split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed.startsWith('[')) {
      break;
    }
    const match = trimmed.match(/^\[(\w+)\s+"(.*)"\s*\]$/);
    if (match) {
      headers[match[1]] = match[2];
    }
  }
  return headers;
}

export function suggestTitleFromPgn(pgn: string): string | undefined {
  const h = parsePgnHeaders(pgn);
  if (h['White'] && h['Black']) {
    return `${h['White']} vs ${h['Black']}`;
  }
  return h['Event'] || h['Site'] || h['White'] || h['Black'];
}

/** Validate PGN and build FEN trail for board replay. */
export function parsePgn(pgn: string): PgnParseResult {
  const trimmed = pgn.trim();
  if (!trimmed) {
    return { valid: false, error: 'PGN is empty', headers: {}, moveCount: 0, fens: [] };
  }

  const headers = parsePgnHeaders(trimmed);
  const endGame = new Chess();

  try {
    endGame.loadPgn(trimmed, { strict: false });
  } catch {
    return {
      valid: false,
      error: 'Invalid PGN format.',
      headers,
      moveCount: 0,
      fens: []
    };
  }

  const verbose = endGame.history({ verbose: true });
  if (verbose.length === 0) {
    return {
      valid: false,
      error: 'No moves found in PGN. Check move notation.',
      headers,
      moveCount: 0,
      fens: []
    };
  }
  const replay = new Chess();
  const fens = [replay.fen()];

  for (const move of verbose) {
    replay.move(move);
    fens.push(replay.fen());
  }

  return {
    valid: true,
    headers,
    suggestedTitle: suggestTitleFromPgn(trimmed),
    moveCount: verbose.length,
    fens
  };
}
