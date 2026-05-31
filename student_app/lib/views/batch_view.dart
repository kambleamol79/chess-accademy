import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../controllers/batch_controller.dart';
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

    return RefreshIndicator(
      color: AppColors.accentOrange,
      onRefresh: controller.load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          const AppSectionHeader(title: 'Class details', subtitle: 'Schedule, coach & Zoom link'),
          BatchCard(batch: controller.batch!),
        ],
      ),
    );
  }
}
