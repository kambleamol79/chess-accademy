/**
 * Boots Stockfish lite-single in a dedicated worker (UCI over postMessage).
 */
(function () {
  const origin = self.location.origin;
  const base = origin + '/assets/stockfish/stockfish-18-lite-single';
  const wasmUrl = encodeURIComponent(base + '.wasm');
  importScripts(base + '.js#' + wasmUrl + ',worker');
})();
