import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../controllers/auth_controller.dart';
import '../controllers/practice_controller.dart';
import '../services/api_service.dart';
import '../services/stockfish_service.dart';
import '../models/chess_game.dart';
import '../models/chess_learning_hint.dart';
import '../widgets/app_ui.dart';
import '../widgets/chess_board_widget.dart';

class PracticeView extends StatelessWidget {
  const PracticeView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => PracticeController(
        context.read<StockfishService>(),
        context.read<ApiService>(),
      ),
      child: const _PracticeBody(),
    );
  }
}

class _PracticeBody extends StatelessWidget {
  const _PracticeBody();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PracticeController>();
    final auth = context.watch<AuthController>();
    final displayName = auth.user?.firstName.trim().isNotEmpty == true
        ? auth.user!.firstName
        : (auth.user?.fullName ?? 'You');

    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 18),
      children: [
        Row(
          children: [
            Expanded(child: _PracticeTabBar(controller: controller)),
            if (controller.screenTab == PracticeScreenTab.board) ...[
              const SizedBox(width: 10),
              _PracticeOptionsDropdown(controller: controller),
            ],
          ],
        ),
        const SizedBox(height: 12),
        if (controller.screenTab == PracticeScreenTab.board) ...[
          _PracticeBoardSummary(controller: controller),
          const SizedBox(height: 10),
          if (controller.isViewingSavedSession) ...[
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      controller.statusMessage,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: controller.exitSavedSessionView,
                    child: const Text('New live game'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (controller.isReplayMode) ...[
            _ReplayBanner(controller: controller),
            const SizedBox(height: 8),
          ],
          Stack(
            clipBehavior: Clip.none,
            children: [
              ChessBoardWidget(controller: controller, playerName: displayName),
              if (controller.canStartGame)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Play vs Stockfish',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFF5F0E8),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${controller.level.label} · ${controller.playerColor.label} · ${controller.timeControl.label}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFFB8A898),
                              ),
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF16A34A),
                                  foregroundColor: AppColors.white,
                                  minimumSize: const Size(0, 52),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: controller.startGame,
                                icon: const Icon(
                                  Icons.play_arrow_rounded,
                                  size: 26,
                                ),
                                label: const Text(
                                  'Start Game',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (controller.learningHintsEnabled && controller.lastHint != null)
            _LearningHintCard(hint: controller.lastHint!),
          if (controller.learningHintsEnabled && controller.lastHint != null)
            const SizedBox(height: 12),
          if (!controller.isViewingSavedSession) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.lightBlue,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Icon(
                    controller.isGameOver
                        ? Icons.flag_rounded
                        : Icons.info_outline_rounded,
                    color: AppColors.primaryBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      controller.statusMessage,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: controller.canUndo ? controller.undoMove : null,
                  icon: const Icon(Icons.undo_rounded, size: 18),
                  label: const Text('Undo'),
                ),
                OutlinedButton.icon(
                  onPressed: controller.canEndGame ? controller.endGame : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                  ),
                  icon: const Icon(Icons.stop_circle_outlined, size: 18),
                  label: const Text('End game'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentOrange,
                    foregroundColor: AppColors.white,
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                  onPressed: controller.aiThinking
                      ? null
                      : controller.resetBoard,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(
                    controller.isVsComputer ? 'New game' : 'Reset board',
                  ),
                ),
              ],
            ),
          ],
          if (controller.gameHistory.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  controller.isViewingSavedSession
                      ? 'Saved moves'
                      : 'Move history',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontSize: 14),
                ),
                const Spacer(),
                Text(
                  'Tap to review',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: controller.gameHistory
                    .map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Material(
                          color: controller.isHistoryMoveActive(entry.ply)
                              ? AppColors.lightBlue
                              : AppColors.white,
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            onTap: () => controller.goToReplayIndex(entry.ply),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color:
                                      controller.isHistoryMoveActive(entry.ply)
                                      ? AppColors.primaryBlue
                                      : AppColors.border,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (entry.color == 'w')
                                    Text(
                                      '${controller.practiceMoveNumber(entry)}. ',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  Text(
                                    entry.san,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    entry.player == 'human' ? 'YOU' : 'SF',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: entry.player == 'human'
                                          ? AppColors.success
                                          : AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ] else ...[
          AppCard(
            padding: const EdgeInsets.all(16),
            child: _SavedGamesSection(controller: controller),
          ),
        ],
      ],
    );
  }
}

class _PracticeTabBar extends StatelessWidget {
  const _PracticeTabBar({required this.controller});

  final PracticeController controller;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          Expanded(
            child: _PracticeTabChip(
              label: 'Board',
              icon: Icons.grid_4x4_rounded,
              selected: controller.screenTab == PracticeScreenTab.board,
              onTap: () => controller.setScreenTab(PracticeScreenTab.board),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _PracticeTabChip(
              label: 'Saved games',
              icon: Icons.history_rounded,
              selected: controller.screenTab == PracticeScreenTab.saved,
              badge: controller.savedSessions.isNotEmpty
                  ? controller.savedSessions.length
                  : null,
              onTap: () => controller.setScreenTab(PracticeScreenTab.saved),
            ),
          ),
        ],
      ),
    );
  }
}

class _PracticeTabChip extends StatelessWidget {
  const _PracticeTabChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primaryBlue : AppColors.offWhite,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? AppColors.white : AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: selected ? AppColors.white : AppColors.textDark,
                  ),
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.white.withValues(alpha: 0.25)
                        : AppColors.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$badge',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: selected ? AppColors.white : AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PracticeBoardSummary extends StatelessWidget {
  const _PracticeBoardSummary({required this.controller});

  final PracticeController controller;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      controller.mode.label,
      controller.timeControl.label,
      if (controller.isVsComputer) controller.level.label,
      if (controller.isVsComputer) controller.playerColor.label,
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.lightBlue,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.tune_rounded,
            size: 18,
            color: AppColors.primaryBlue,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              parts.join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.primaryBlue,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            controller.learningHintsEnabled ? 'Hints on' : 'Hints off',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PracticeOptionsDropdown extends StatelessWidget {
  const _PracticeOptionsDropdown({required this.controller});

  final PracticeController controller;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: () => _showOptions(context),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.card,
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.filter_list_rounded,
                color: AppColors.primaryBlue,
                size: 20,
              ),
              SizedBox(width: 6),
              Text(
                'Filter',
                style: TextStyle(
                  color: AppColors.primaryBlue,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: controller,
        child: const _PracticeOptionsSheet(),
      ),
    );
  }
}

class _PracticeOptionsSheet extends StatelessWidget {
  const _PracticeOptionsSheet();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PracticeController>();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                Icons.filter_list_rounded,
                color: AppColors.primaryBlue,
              ),
              const SizedBox(width: 8),
              Text(
                'Board filters',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ModeSelector(controller: controller),
          const SizedBox(height: 14),
          _TimeControlSelector(controller: controller),
          if (controller.isVsComputer) ...[
            const SizedBox(height: 18),
            _LevelSelector(controller: controller),
            const SizedBox(height: 14),
            _ColorSelector(controller: controller),
          ],
          const SizedBox(height: 14),
          _LearningToggle(controller: controller),
        ],
      ),
    );
  }
}

class _LearningToggle extends StatelessWidget {
  const _LearningToggle({required this.controller});

  final PracticeController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.offWhite,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lightbulb_outline_rounded,
            color: AppColors.accentOrange,
            size: 20,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Learning suggestions',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          Switch.adaptive(
            value: controller.learningHintsEnabled,
            activeTrackColor: AppColors.primaryBlue.withValues(alpha: 0.5),
            activeThumbColor: AppColors.primaryBlue,
            onChanged: controller.aiThinking
                ? null
                : controller.setLearningHintsEnabled,
          ),
        ],
      ),
    );
  }
}

class _LearningHintCard extends StatelessWidget {
  const _LearningHintCard({required this.hint});

  final ChessLearningHint hint;

  @override
  Widget build(BuildContext context) {
    final (icon, color, bg) = switch (hint.kind) {
      HintKind.greatMove => (
        Icons.thumb_up_alt_rounded,
        AppColors.success,
        const Color(0xFFDCFCE7),
      ),
      HintKind.alternative => (
        Icons.tips_and_updates_rounded,
        AppColors.warning,
        const Color(0xFFFEF3C7),
      ),
      HintKind.nextMove => (
        Icons.lightbulb_rounded,
        AppColors.primaryBlue,
        AppColors.lightBlue,
      ),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hint.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: color,
                  ),
                ),
              ),
              if (hint.suggestedSan != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    hint.suggestedSan!,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: color,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            hint.message,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppColors.textDark,
            ),
          ),
          if (hint.highlightFrom != null && hint.highlightTo != null) ...[
            const SizedBox(height: 8),
            Text(
              'Green squares show the suggested move on the board.',
              style: TextStyle(
                fontSize: 11,
                color: color.withValues(alpha: 0.85),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.controller});

  final PracticeController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: PracticeMode.values.map((mode) {
        final selected = controller.mode == mode;
        final isLast = mode == PracticeMode.values.last;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : 8),
            child: _ChoiceTile(
              label: mode.label,
              icon: mode == PracticeMode.freePlay
                  ? Icons.open_in_full_rounded
                  : Icons.smart_toy_rounded,
              selected: selected,
              onTap:
                  controller.aiThinking ||
                      controller.gameActive && controller.isVsComputer
                  ? null
                  : () => controller.setMode(mode),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _TimeControlSelector extends StatelessWidget {
  const _TimeControlSelector({required this.controller});

  final PracticeController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.timer_outlined, size: 18, color: AppColors.primaryBlue),
            SizedBox(width: 8),
            Text(
              'Time control',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: GameTimeControl.values.map((control) {
            final selected = controller.timeControl == control;
            final isLast = control == GameTimeControl.values.last;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: isLast ? 0 : 6),
                child: _ChoiceTile(
                  label: control.label,
                  selected: selected,
                  compact: true,
                  onTap: controller.gameActive || controller.aiThinking
                      ? null
                      : () => controller.setTimeControl(control),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _LevelSelector extends StatelessWidget {
  const _LevelSelector({required this.controller});

  final PracticeController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Computer level',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Row(
          children: ComputerLevel.values.map((level) {
            final selected = controller.level == level;
            final isLast = level == ComputerLevel.values.last;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: isLast ? 0 : 6),
                child: _ChoiceTile(
                  label: level.label,
                  selected: selected,
                  compact: true,
                  accentColor: AppColors.accentOrange,
                  onTap: controller.aiThinking
                      ? null
                      : () => controller.setLevel(level),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 6),
        Text(
          controller.level.description,
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _ColorSelector extends StatelessWidget {
  const _ColorSelector({required this.controller});

  final PracticeController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'You play as',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _PieceColorTile(
                label: 'White',
                isWhitePiece: true,
                selected: controller.playerColor == PlayerColor.white,
                onTap: controller.aiThinking
                    ? null
                    : () => controller.setPlayerColor(PlayerColor.white),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PieceColorTile(
                label: 'Black',
                isWhitePiece: false,
                selected: controller.playerColor == PlayerColor.black,
                onTap: controller.aiThinking
                    ? null
                    : () => controller.setPlayerColor(PlayerColor.black),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.compact = false,
    this.accentColor = AppColors.primaryBlue,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool compact;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? accentColor : AppColors.offWhite,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: compact ? 10 : 12,
            horizontal: 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: selected ? accentColor : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: selected ? AppColors.white : AppColors.textMuted,
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 11 : 13,
                    fontWeight: FontWeight.w700,
                    color: selected ? AppColors.white : AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PieceColorTile extends StatelessWidget {
  const _PieceColorTile({
    required this.label,
    required this.isWhitePiece,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool isWhitePiece;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.lightBlue : AppColors.offWhite,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: selected ? AppColors.primaryBlue : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isWhitePiece
                      ? const Color(0xFFF8FAFC)
                      : const Color(0xFF0F172A),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF334155),
                    width: 1.5,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  '♞',
                  style: TextStyle(
                    fontSize: 16,
                    color: isWhitePiece
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFF8FAFC),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: selected ? AppColors.primaryBlue : AppColors.textDark,
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.check_circle_rounded,
                  size: 16,
                  color: AppColors.primaryBlue,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ReplayBanner extends StatelessWidget {
  const _ReplayBanner({required this.controller});

  final PracticeController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.offWhite,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            controller.replayCaption,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: controller.canReplayPrevious
                      ? controller.replayPrevious
                      : null,
                  icon: const Icon(Icons.chevron_left, size: 18),
                  label: const Text('Previous'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: controller.canReplayNext
                      ? controller.replayNext
                      : null,
                  icon: const Icon(Icons.chevron_right, size: 18),
                  label: const Text('Next'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: controller.returnToLive,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: AppColors.white,
                  ),
                  child: const Text('Live'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SavedGamesSection extends StatelessWidget {
  const _SavedGamesSection({required this.controller});

  final PracticeController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Saved games',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Tap a game to open it on the Board tab and review moves.',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 12),
        if (controller.loadingSavedSessions)
          const Text(
            'Loading saved games…',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          )
        else if (controller.savedSessions.isEmpty)
          const Text(
            'Play a game to save your moves for later.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: controller.savedSessions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final session = controller.savedSessions[index];
                final selected = controller.viewingSavedSessionId == session.id;
                return Material(
                  color: selected ? AppColors.lightBlue : AppColors.white,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: () => controller.openSavedSession(session.id),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected
                              ? AppColors.primaryBlue
                              : AppColors.border,
                        ),
                      ),
                      child: Text(
                        session.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
