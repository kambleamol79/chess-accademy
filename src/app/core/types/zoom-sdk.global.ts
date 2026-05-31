export interface ZoomEmbeddedClient {
  init(options: Record<string, unknown>): Promise<void>;
  join(options: Record<string, unknown>): Promise<void>;
  leaveMeeting(): void;
}

export interface ZoomSdkGlobal {
  createClient(): ZoomEmbeddedClient;
  destroyClient(): void;
}

declare global {
  interface Window {
    React?: unknown;
    ReactDOM?: unknown;
    ReactWidgets?: ZoomSdkGlobal;
  }
}

export {};
