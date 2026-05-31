/** Open Zoom join/start URL in a maximized browser window (or same tab if blocked). */
export function openZoomExternalFullscreen(url: string, windowName = 'chess-academy-zoom'): void {
  const trimmed = url.trim();
  if (!trimmed) {
    return;
  }

  const w = window.screen.availWidth ?? window.innerWidth;
  const h = window.screen.availHeight ?? window.innerHeight;
  const features = `noopener,noreferrer,width=${w},height=${h},left=0,top=0`;
  const popup = window.open(trimmed, windowName, features);

  if (!popup) {
    window.location.assign(trimmed);
  }
}
