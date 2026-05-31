import 'package:flutter/foundation.dart';

import '../models/batch.dart';
import '../services/api_service.dart';

class BatchController extends ChangeNotifier {
  BatchController(this._api);

  final ApiService _api;

  StudentBatch? batch;
  bool loading = false;
  String? error;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      batch = await _api.fetchMyBatch();
    } catch (e) {
      error = e.toString().replaceFirst('ApiException: ', '');
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
