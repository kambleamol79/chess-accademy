import 'package:flutter/foundation.dart';

import '../models/support_ticket.dart';
import '../services/api_service.dart' show ApiService, ApiException, SupportTicketDetail;

class SupportController extends ChangeNotifier {
  SupportController(this._api);

  final ApiService _api;

  List<SupportTicket> tickets = [];
  bool loading = false;
  String? error;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      tickets = await _api.fetchMySupportTickets();
      loading = false;
      notifyListeners();
    } on ApiException catch (e) {
      error = e.message;
      loading = false;
      notifyListeners();
    }
  }

  Future<({SupportTicket ticket, List<SupportTicketMessage> messages})?> loadTicket(int id) async {
    try {
      final detail = await _api.fetchSupportTicket(id);
      return (ticket: detail.ticket, messages: detail.messages);
    } on ApiException catch (e) {
      error = e.message;
      notifyListeners();
      return null;
    }
  }

  Future<bool> createTicket({required String subject, required String body}) async {
    try {
      await _api.createSupportTicket(subject: subject, body: body);
      await load();
      return true;
    } on ApiException catch (e) {
      error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> reply(int ticketId, String body) async {
    try {
      await _api.replySupportTicket(ticketId, body);
      return true;
    } on ApiException catch (e) {
      error = e.message;
      notifyListeners();
      return false;
    }
  }
}
