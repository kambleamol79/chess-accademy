import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../controllers/support_controller.dart';
import '../models/support_ticket.dart';
import '../widgets/app_ui.dart';
import '../widgets/loading_view.dart';

class SupportView extends StatefulWidget {
  const SupportView({super.key});

  @override
  State<SupportView> createState() => _SupportViewState();
}

class _SupportViewState extends State<SupportView> {
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _creating = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupportController>().load();
    });
  }

  Future<void> _createTicket(SupportController controller) async {
    final subject = _subjectController.text.trim();
    final body = _bodyController.text.trim();
    if (subject.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subject and message are required')),
      );
      return;
    }

    setState(() => _creating = true);
    final ok = await controller.createTicket(subject: subject, body: body);
    if (!mounted) return;
    setState(() => _creating = false);

    if (ok) {
      _subjectController.clear();
      _bodyController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Support request sent')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SupportController>();

    if (controller.loading && controller.tickets.isEmpty) {
      return const LoadingView();
    }

    return RefreshIndicator(
      color: AppColors.accentOrange,
      onRefresh: controller.load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          const AppSectionHeader(
            title: 'Contact support',
            subtitle: 'Send issues or questions to the academy admin',
          ),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _subjectController,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    hintText: 'Payment issue, batch change, etc.',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _bodyController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    hintText: 'Describe your issue',
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _creating ? null : () => _createTicket(controller),
                  child: Text(_creating ? 'Sending…' : 'Send to admin'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const AppSectionHeader(title: 'Your requests', subtitle: 'Track replies from admin'),
          if (controller.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(controller.error!, style: const TextStyle(color: Colors.red)),
            ),
          if (controller.tickets.isEmpty)
            const AppEmptyState(
              message: 'No support requests yet.',
              icon: Icons.support_agent_rounded,
            )
          else
            ...controller.tickets.map((ticket) => _TicketTile(
                  ticket: ticket,
                  onTap: () => _openTicket(context, ticket),
                )),
        ],
      ),
    );
  }

  void _openTicket(BuildContext context, SupportTicket ticket) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SupportTicketDetailView(ticketId: ticket.id, subject: ticket.subject),
      ),
    );
  }
}

class _TicketTile extends StatelessWidget {
  const _TicketTile({required this.ticket, required this.onTap});

  final SupportTicket ticket;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: onTap,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ticket.subject, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    ticket.isResolved ? 'Resolved' : 'Open',
                    style: TextStyle(
                      color: ticket.isResolved ? Colors.green.shade700 : AppColors.accentOrange,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class SupportTicketDetailView extends StatefulWidget {
  const SupportTicketDetailView({super.key, required this.ticketId, required this.subject});

  final int ticketId;
  final String subject;

  @override
  State<SupportTicketDetailView> createState() => _SupportTicketDetailViewState();
}

class _SupportTicketDetailViewState extends State<SupportTicketDetailView> {
  final _replyController = TextEditingController();
  bool _loading = true;
  bool _sending = false;
  SupportTicket? _ticket;
  List<SupportTicketMessage> _messages = [];

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final detail = await context.read<SupportController>().loadTicket(widget.ticketId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (detail != null) {
        _ticket = detail.ticket;
        _messages = detail.messages;
      }
    });
  }

  Future<void> _sendReply() async {
    final body = _replyController.text.trim();
    if (body.isEmpty || _ticket?.isResolved == true) return;

    setState(() => _sending = true);
    final ok = await context.read<SupportController>().reply(widget.ticketId, body);
    if (!mounted) return;
    setState(() => _sending = false);

    if (ok) {
      _replyController.clear();
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(title: Text(widget.subject)),
      body: _loading
          ? const LoadingView()
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                if (_ticket?.resolutionComment != null)
                  AppCard(
                    child: Text(
                      'Resolved: ${_ticket!.resolutionComment}',
                      style: TextStyle(color: Colors.green.shade800),
                    ),
                  ),
                ..._messages.map(
                  (message) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message.senderName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Text(message.body),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_ticket != null && !_ticket!.isResolved) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: _replyController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Reply'),
                  ),
                  const SizedBox(height: 10),
                  FilledButton(
                    onPressed: _sending ? null : _sendReply,
                    child: Text(_sending ? 'Sending…' : 'Send reply'),
                  ),
                ],
              ],
            ),
    );
  }
}
