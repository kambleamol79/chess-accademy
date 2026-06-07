import packageInfo from '../../package.json';

export const environment = {
  appVersion: packageInfo.version,
  appName: 'Brainstorm',
  production: true,
  apiUrl: '/brainstorm/api/v1',
  liveWsUrl: '',
  tokenKey: 'ca_access_token',
  refreshKey: 'ca_refresh_token',
  todayTournamentUrl: 'https://www.chess.com/play/arena/31279193'
};
