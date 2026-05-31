import 'package:flutter/material.dart';

import '../config/theme.dart';
import 'animated_ui.dart';
import 'app_ui.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message = 'Loading…'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.surfaceGradient),
      child: Center(
        child: FadeSlideIn(
          child: AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 32),
            child: GradientLoader(message: message),
          ),
        ),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: FadeSlideIn(
          child: AppCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppIconBadge(icon: Icons.error_outline_rounded, color: AppColors.error, size: 56),
                const SizedBox(height: 14),
                Text(message, textAlign: TextAlign.center),
                if (onRetry != null) ...[
                  const SizedBox(height: 18),
                  AppPrimaryButton(label: 'Retry', onPressed: onRetry, gradient: true),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.message, this.icon = Icons.inbox_outlined});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(child: AppEmptyState(message: message, icon: icon));
  }
}
