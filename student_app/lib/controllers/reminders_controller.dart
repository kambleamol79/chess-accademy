import 'package:flutter/foundation.dart';

import '../models/reminder.dart';
import '../services/api_service.dart';

class RemindersController extends ChangeNotifier {
  RemindersController(this._api);

  final ApiService _api;

  List<Reminder> reminders = [];
  bool loading = false;
  String? error;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      reminders = await _api.fetchReminders();
    } catch (e) {
      error = e.toString().replaceFirst('ApiException: ', '');
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
