import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../models/user.dart';

class StorageService {
  StorageService(this._prefs);

  final SharedPreferences _prefs;

  static Future<StorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  String? get accessToken => _prefs.getString(AppConfig.accessTokenKey);
  String? get refreshToken => _prefs.getString(AppConfig.refreshTokenKey);

  User? get user {
    final raw = _prefs.getString(AppConfig.userKey);
    if (raw == null) return null;
    return User.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveSession(AuthTokens tokens) async {
    await _prefs.setString(AppConfig.accessTokenKey, tokens.accessToken);
    await _prefs.setString(AppConfig.refreshTokenKey, tokens.refreshToken);
    await _prefs.setString(AppConfig.userKey, jsonEncode(tokens.user.toJson()));
  }

  Future<void> saveUser(User user) async {
    await _prefs.setString(AppConfig.userKey, jsonEncode(user.toJson()));
  }

  Future<void> clearSession() async {
    await _prefs.remove(AppConfig.accessTokenKey);
    await _prefs.remove(AppConfig.refreshTokenKey);
    await _prefs.remove(AppConfig.userKey);
  }

  int? lastPuzzleId(String difficulty) {
    final id = _prefs.getInt('${AppConfig.lastPuzzlePrefix}$difficulty');
    return id != null && id > 0 ? id : null;
  }

  Future<void> saveLastPuzzleId(String difficulty, int puzzleId) async {
    await _prefs.setInt('${AppConfig.lastPuzzlePrefix}$difficulty', puzzleId);
  }
}
