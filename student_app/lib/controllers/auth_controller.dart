import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class AuthController extends ChangeNotifier {
  AuthController(this._api, this._storage);

  final ApiService _api;
  final StorageService _storage;

  User? _user;
  bool _loading = false;
  String? _error;

  User? get user => _user;
  bool get isAuthenticated => _storage.accessToken != null;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> bootstrap() async {
    _user = _storage.user;
    if (!isAuthenticated) return;

    try {
      _user = await _api.fetchMe();
      await _storage.saveUser(_user!);
    } catch (_) {
      await _storage.clearSession();
      _user = null;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final tokens = await _api.login(email, password);
      if (tokens.user.role != 'student') {
        throw Exception('This app is for students only.');
      }
      await _storage.saveSession(tokens);
      _user = tokens.user;
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      var message = e.toString();
      message = message.replaceFirst('ApiException: ', '');
      message = message.replaceFirst('Exception: ', '');
      if (message.contains('ClientException') ||
          message.contains('Connection refused') ||
          message.contains('SocketException') ||
          message.contains('Failed host lookup')) {
        message = 'Cannot reach API at ${AppConfig.apiBaseUrl}.\n\n${AppConfig.connectionHelp}';
      }
      _error = message;
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _api.logout();
    _user = null;
    notifyListeners();
  }
}
