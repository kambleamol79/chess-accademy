import packageInfo from '../../package.json';

export const environment = {
  appVersion: packageInfo.version,
  appName: 'Brainstorm',
  production: true,
  apiUrl: '/api/v1',
  liveWsUrl: '',
  tokenKey: 'ca_access_token',
  refreshKey: 'ca_refresh_token'
};
