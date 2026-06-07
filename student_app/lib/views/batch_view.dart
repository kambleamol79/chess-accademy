import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../controllers/batch_controller.dart';
import '../controllers/batch_messages_controller.dart';
import '../models/batch_message.dart';
import '../widgets/app_ui.dart';
import '../widgets/batch_card.dart';
import '../widgets/loading_view.dart';

class BatchView extends StatefulWidget {
  const BatchView({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  State<BatchView> createState() => _BatchViewState();
}

class _BatchViewState extends State<BatchView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BatchController>().load();
      context.read<BatchMessagesController>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BatchController>();

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: widget.showAppBar ? AppBar(title: const Text('My Batch')) : null,
      body: _buildBody(controller),
    );
  }

  Widget _buildBody(BatchController controller) {
    if (controller.loading) return const LoadingView();
    if (controller.error != null) {
      return ErrorView(message: controller.error!, onRetry: controller.load);
    }
    if (controller.batch == null) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: const [
          AppEmptyState(
            message: 'You are not assigned to a batch yet.\nContact Brainstorm.',
            icon: Icons.groups_rounded,
          ),
        ],
      );
    }

    final messagesController = context.watch<BatchMessagesController>();

    return RefreshIndicator(
      color: AppColors.accentOrange,
      onRefresh: () async {
        await controller.load();
        await messagesController.load();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          const AppSectionHeader(title: 'Class details', subtitle: 'Schedule, coach & Zoom link'),
          BatchCard(batch: controller.batch!),
          const SizedBox(height: 20),
          const AppSectionHeader(
            title: 'Batch messages',
            subtitle: 'Announcements from admin to your batch',
          ),
          if (messagesController.loading && messagesController.messages.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (messagesController.messages.isEmpty)
            const AppEmptyState(
              message: 'No batch messages yet.',
              icon: Icons.campaign_rounded,
            )
          else
            ...messagesController.messages.map((message) => _BatchMessageTile(message: message)),
        ],
      ),
    );
  }
}

class _BatchMessageTile extends StatelessWidget {
  const _BatchMessageTile({required this.message});

  final BatchMessage message;

  @override
  Widget build(BuildContext context) {
    return Padding(
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
    );
  }
}
