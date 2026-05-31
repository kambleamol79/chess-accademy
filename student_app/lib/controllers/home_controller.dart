import 'package:flutter/foundation.dart';

import '../models/batch.dart';
import '../models/reminder.dart';
import '../services/api_service.dart';

class HomeController extends ChangeNotifier {
  HomeController(this._api);

  final ApiService _api;

  StudentBatch? batch;
  List<Reminder> reminders = [];
  bool loading = false;
  String? error;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _api.fetchMyBatch(),
        _api.fetchReminders(),
      ]);
      batch = results[0] as StudentBatch?;
      reminders = results[1] as List<Reminder>;
    } catch (e) {
      error = e.toString().replaceFirst('ApiException: ', '');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  int get reminderCount => reminders.length;
}
