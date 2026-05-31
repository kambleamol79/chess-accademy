import packageInfo from '../../package.json';

export const environment = {
  appVersion: packageInfo.version,
  appName: 'Brainstorm',
  production: false,
  apiUrl: 'http://localhost:8080/api/v1',
  /** Set when api/realtime/ws-server.mjs is running; empty uses SSE + HTTP polling. */
  liveWsUrl: '',
  tokenKey: 'ca_access_token',
  refreshKey: 'ca_refresh_token'
};
