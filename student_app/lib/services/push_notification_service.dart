import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'api_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class PushNotificationService {
  PushNotificationService(this._api);

  final ApiService _api;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized || kIsWeb) {
      return;
    }

    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      await messaging.subscribeToTopic(AppConfig.firebaseStudentsTopic);

      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await _registerToken(token);
      }

      messaging.onTokenRefresh.listen(_registerToken);

      _initialized = true;
    } catch (_) {
      // Firebase not configured on this device yet (missing google-services.json / GoogleService-Info.plist).
    }
  }

  Future<void> _registerToken(String token) async {
    final platform = Platform.isIOS ? 'ios' : 'android';
    await _api.registerDeviceToken(token: token, platform: platform);
  }

  Future<void> unregister() async {
    if (!_initialized || kIsWeb) {
      return;
    }

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _api.unregisterDeviceToken(token);
      }
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}
  }
}
