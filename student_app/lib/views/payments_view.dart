import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../controllers/payments_controller.dart';
import '../widgets/app_ui.dart';
import '../widgets/loading_view.dart';
import '../widgets/payment_tile.dart';

class PaymentsView extends StatefulWidget {
  const PaymentsView({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  State<PaymentsView> createState() => _PaymentsViewState();
}

class _PaymentsViewState extends State<PaymentsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentsController>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PaymentsController>();

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: widget.showAppBar ? AppBar(title: const Text('Payment History')) : null,
      body: _buildBody(controller),
    );
  }

  Widget _buildBody(PaymentsController controller) {
    if (controller.loading) return const LoadingView();
    if (controller.error != null) {
      return ErrorView(message: controller.error!, onRetry: controller.load);
    }

    final history = controller.history!;
    return RefreshIndicator(
      color: AppColors.accentOrange,
      onRefresh: controller.load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          PaymentSummaryCard(summary: history.summary),
          const SizedBox(height: 20),
          if (history.invoices.isNotEmpty) ...[
            const AppSectionHeader(title: 'Invoices'),
            ...history.invoices.map((i) => InvoiceTile(invoice: i)),
          ],
          if (history.monthly.isNotEmpty) ...[
            const AppSectionHeader(title: 'Monthly payments'),
            ...history.monthly.map((m) => MonthlyPaymentTile(payment: m)),
          ],
          if (history.invoices.isEmpty && history.monthly.isEmpty)
            const AppEmptyState(
              message: 'No payment records found yet.',
              icon: Icons.receipt_long_rounded,
            ),
        ],
      ),
    );
  }
}
