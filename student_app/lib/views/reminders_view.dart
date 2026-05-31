import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../controllers/reminders_controller.dart';
import '../widgets/app_ui.dart';
import '../widgets/loading_view.dart';
import '../widgets/reminder_tile.dart';

class RemindersView extends StatefulWidget {
  const RemindersView({super.key});

  @override
  State<RemindersView> createState() => _RemindersViewState();
}

class _RemindersViewState extends State<RemindersView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RemindersController>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RemindersController>();

    if (controller.loading) return const LoadingView();
    if (controller.error != null) {
      return ErrorView(message: controller.error!, onRetry: controller.load);
    }

    return RefreshIndicator(
      color: AppColors.accentOrange,
      onRefresh: controller.load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          const AppSectionHeader(title: 'Your reminders', subtitle: 'Stay on top of classes & payments'),
          if (controller.reminders.isEmpty)
            const AppEmptyState(message: 'All caught up — no reminders.', icon: Icons.alarm_off_rounded)
          else
            ...controller.reminders.map((r) => ReminderTile(reminder: r)),
        ],
      ),
    );
  }
}
