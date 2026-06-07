/** Open Zoom join URL once (guards double-clicks and duplicate handlers). */
let zoomOpenInFlight = false;

export function openZoomExternalFullscreen(url: string, windowName = 'chess-academy-zoom'): void {
  const trimmed = url.trim();
  if (!trimmed || zoomOpenInFlight) {
    return;
  }

  zoomOpenInFlight = true;
  window.setTimeout(() => {
    zoomOpenInFlight = false;
  }, 2000);

  const popup = window.open(trimmed, windowName, 'noopener,noreferrer');
  
}
