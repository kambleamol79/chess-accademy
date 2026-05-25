import packageInfo from '../../package.json';

export const environment = {
  appVersion: packageInfo.version,
  appName: 'Chess Academy',
  production: true,
  apiUrl: '/api/v1',
  tokenKey: 'ca_access_token',
  refreshKey: 'ca_refresh_token'
};
