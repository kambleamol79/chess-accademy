import { Injectable } from '@angular/core';
import { ZoomEmbeddedClient, ZoomSdkGlobal } from '../types/zoom-sdk.global';

@Injectable({ providedIn: 'root' })
export class ZoomSdkLoaderService {
  private loadPromise: Promise<ZoomSdkGlobal> | null = null;

  createClient(): Promise<ZoomEmbeddedClient> {
    return this.loadSdk().then((sdk) => sdk.createClient());
  }

  private loadSdk(): Promise<ZoomSdkGlobal> {
    if (window.ReactWidgets?.createClient) {
      return Promise.resolve(window.ReactWidgets);
    }

    if (!this.loadPromise) {
      this.loadPromise = this.loadScripts().then(() => this.waitForSdk());
    }

    return this.loadPromise;
  }

  private async loadScripts(): Promise<void> {
    await this.loadScript(this.assetUrl('assets/zoom/react.production.min.js'));
    await this.loadScript(this.assetUrl('assets/zoom/react-dom.production.min.js'));
    await this.loadScript(this.assetUrl('assets/zoom/zoomus-websdk-embedded.umd.min.js'));
  }

  /** Resolve asset path against the app base href (works on any dev-server port). */
  private assetUrl(relativePath: string): string {
    const base = document.baseURI.endsWith('/') ? document.baseURI : `${document.baseURI}/`;
    return new URL(relativePath.replace(/^\//, ''), base).href;
  }

  private loadScript(src: string): Promise<void> {
    if (document.querySelector(`script[src="${src}"]`)) {
      return Promise.resolve();
    }

    return new Promise((resolve, reject) => {
      const script = document.createElement('script');
      script.src = src;
      script.async = false;
      script.onload = () => resolve();
      script.onerror = () =>
        reject(
          new Error(
            `Failed to load Zoom script (${src}). Restart ng serve and open the URL shown in the terminal (not port 4200 if another app uses it).`
          )
        );
      document.head.appendChild(script);
    });
  }

  private waitForSdk(): Promise<ZoomSdkGlobal> {
    return new Promise((resolve, reject) => {
      let attempts = 0;

      const check = () => {
        if (window.ReactWidgets?.createClient) {
          resolve(window.ReactWidgets);
          return;
        }

        if (++attempts > 200) {
          reject(new Error('Zoom Meeting SDK failed to initialize'));
          return;
        }

        setTimeout(check, 50);
      };

      check();
    });
  }
}
