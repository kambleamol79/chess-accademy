import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../controllers/auth_controller.dart';
import '../controllers/puzzle_controller.dart';
import '../models/puzzle.dart';
import '../widgets/animated_ui.dart';
import '../widgets/app_ui.dart';
import '../widgets/loading_view.dart';
import '../widgets/puzzle_board_widget.dart';

class PuzzlesView extends StatefulWidget {
  const PuzzlesView({super.key});

  @override
  State<PuzzlesView> createState() => _PuzzlesViewState();
}

class _PuzzlesViewState extends State<PuzzlesView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PuzzleController>().loadPuzzle(forceNew: true);
    });
  }

  Gradient _levelGradient(PuzzleDifficulty level) {
    return switch (level) {
      PuzzleDifficulty.easy => AppColors.easyGradient,
      PuzzleDifficulty.medium => AppColors.mediumGradient,
      PuzzleDifficulty.hard => AppColors.hardGradient,
    };
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PuzzleController>();
    final auth = context.watch<AuthController>();
    final displayName = auth.user?.firstName.trim().isNotEmpty == true
        ? auth.user!.firstName
        : (auth.user?.fullName ?? 'You');

    if (controller.status == PuzzleStatus.loading && controller.puzzle == null) {
      return const LoadingView(message: 'Finding your puzzle…');
    }

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.surfaceGradient),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          FadeSlideIn(
            child: _LevelSelectorCard(
              controller: controller,
              levelGradient: _levelGradient,
            ),
          ),
          if (controller.error != null) ...[
            const SizedBox(height: 12),
            FadeSlideIn(
              delay: const Duration(milliseconds: 80),
              child: AppCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text(controller.error!, style: const TextStyle(color: AppColors.error))),
                  ],
                ),
              ),
            ),
          ],
          if (controller.puzzle != null) ...[
            const SizedBox(height: 16),
            FadeSlideIn(
              delay: const Duration(milliseconds: 120),
              child: _PuzzleHeader(
                title: controller.puzzle!.title,
                difficulty: controller.level.label,
                gradient: _levelGradient(controller.level),
              ),
            ),
            const SizedBox(height: 12),
            FadeSlideIn(
              delay: const Duration(milliseconds: 180),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  AnimatedPuzzleBoard(
                    puzzleId: controller.puzzle!.id,
                    child: PuzzleBoardWidget(
                      controller: controller,
                      playerName: displayName,
                    ),
                  ),
                  Positioned(
                    top: -8,
                    child: CelebrationBurst(active: controller.status == PuzzleStatus.solved),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            FadeSlideIn(
              delay: const Duration(milliseconds: 240),
              child: _StatusBanner(controller: controller),
            ),
            const SizedBox(height: 14),
            FadeSlideIn(
              delay: const Duration(milliseconds: 300),
              child: Row(
                children: [
                  Expanded(
                    child: GlowButton(
                      label: 'Reset',
                      icon: Icons.restart_alt_rounded,
                      gradient: AppColors.mediumGradient,
                      outlined: true,
                      onPressed: controller.status == PuzzleStatus.loading ? null : controller.resetPuzzle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GlowButton(
                      label: 'Next puzzle',
                      icon: Icons.skip_next_rounded,
                      gradient: AppColors.accentGradient,
                      loading: controller.status == PuzzleStatus.loading,
                      onPressed: controller.status == PuzzleStatus.loading
                          ? null
                          : () => controller.loadPuzzle(forceNew: true),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LevelSelectorCard extends StatelessWidget {
  const _LevelSelectorCard({
    required this.controller,
    required this.levelGradient,
  });

  final PuzzleController controller;
  final Gradient Function(PuzzleDifficulty) levelGradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        gradient: AppColors.heroGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.extension_rounded, color: AppColors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Daily puzzles',
                        style: TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        controller.level.description,
                        style: TextStyle(
                          color: AppColors.white.withValues(alpha: 0.75),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (controller.solvedCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: AppColors.successGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.success.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '${controller.solvedCount} ✓',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: PuzzleDifficulty.values.map((level) {
                final selected = controller.level == level;
                final isLast = level == PuzzleDifficulty.values.last;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: isLast ? 0 : 8),
                    child: GradientChip(
                      label: level.label,
                      selected: selected,
                      gradient: levelGradient(level),
                      enabled: controller.status != PuzzleStatus.loading,
                      onTap: () {
                        controller.setLevel(level);
                        controller.loadPuzzle(forceNew: true);
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _PuzzleHeader extends StatelessWidget {
  const _PuzzleHeader({
    required this.title,
    required this.difficulty,
    required this.gradient,
  });

  final String? title;
  final String difficulty;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            difficulty,
            style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w800, fontSize: 10),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title ?? 'Find the best move',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.controller});

  final PuzzleController controller;

  @override
  Widget build(BuildContext context) {
    final (icon, color, gradient) = switch (controller.status) {
      PuzzleStatus.solved => (Icons.celebration_rounded, AppColors.success, AppColors.successGradient),
      PuzzleStatus.wrong => (Icons.close_rounded, AppColors.error, AppColors.errorGradient),
      PuzzleStatus.playing => (Icons.psychology_alt_rounded, AppColors.primaryBlue, AppColors.playingGradient),
      _ => (Icons.info_outline_rounded, AppColors.textMuted, const LinearGradient(colors: [AppColors.offWhite, AppColors.offWhite])),
    };

    return AnimatedStatusBanner(
      icon: icon,
      message: controller.message,
      color: color,
      gradient: gradient,
    );
  }
}
