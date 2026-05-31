import 'package:flutter/foundation.dart';

import '../models/payment.dart';
import '../services/api_service.dart';

class PaymentsController extends ChangeNotifier {
  PaymentsController(this._api);

  final ApiService _api;

  PaymentHistory? history;
  bool loading = false;
  String? error;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      history = await _api.fetchPayments();
    } catch (e) {
      error = e.toString().replaceFirst('ApiException: ', '');
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
