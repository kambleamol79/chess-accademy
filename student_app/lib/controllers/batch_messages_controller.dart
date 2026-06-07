import 'package:flutter/foundation.dart';

import '../models/batch_message.dart';
import '../services/api_service.dart' show ApiService, ApiException, BatchMessagesResult;

class BatchMessagesController extends ChangeNotifier {
  BatchMessagesController(this._api);

  final ApiService _api;

  List<BatchMessage> messages = [];
  int? formId;
  bool loading = false;
  String? error;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final result = await _api.fetchMyBatchMessages();
      formId = result.formId;
      messages = result.messages;
      loading = false;
      notifyListeners();
    } on ApiException catch (e) {
      error = e.message;
      loading = false;
      notifyListeners();
    }
  }
}
