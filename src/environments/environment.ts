import packageInfo from '../../package.json';

export const environment = {
  appVersion: packageInfo.version,
  appName: 'Chess Academy',
  production: false,
  apiUrl: 'http://localhost:8080/api/v1',
  tokenKey: 'ca_access_token',
  refreshKey: 'ca_refresh_token'
};
