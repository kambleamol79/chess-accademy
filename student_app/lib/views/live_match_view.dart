import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../controllers/live_match_controller.dart';
import '../services/api_service.dart';
import '../widgets/chess_board_core.dart';
import '../widgets/chess_play_surface.dart';
import '../widgets/loading_view.dart';

class LiveMatchView extends StatelessWidget {
  const LiveMatchView({super.key, required this.matchId});

  final int matchId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => LiveMatchController(
        ctx.read<ApiService>(),
        matchId,
      )..load(),
      child: const _LiveMatchBody(),
    );
  }
}

class _LiveMatchBody extends StatelessWidget {
  const _LiveMatchBody();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<LiveMatchController>();

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: const Text('Live match'),
        actions: [
          if (c.state?.match.status == 'active')
            TextButton(
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Resign?'),
                    content: const Text('End this game as a loss?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Resign')),
                    ],
                  ),
                );
                if (ok == true) await c.resign();
              },
              child: const Text('Resign', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: c.loading
          ? const LoadingView()
          : c.error != null && c.state == null
              ? Center(child: Text(c.error!))
              : Column(
                  children: [
                    if (c.error != null)
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(c.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(c.statusLine, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: ChessPlaySurface(
                          topPlayer: ChessPlayerBar(
                            name: c.topName,
                            avatarLabel: 'O',
                            timerText: c.topTimerText,
                            isActive: c.topTimerActive,
                            isLowTime: false,
                            alignTimerRight: true,
                          ),
                          bottomPlayer: ChessPlayerBar(
                            name: c.bottomName,
                            subtitle: 'You',
                            avatarLabel: 'Y',
                            timerText: c.bottomTimerText,
                            isActive: c.bottomTimerActive,
                            isLowTime: false,
                            alignTimerRight: true,
                          ),
                          board: ChessBoardCore(
                            fen: c.displayFen,
                            boardFlipped: c.boardFlipped,
                            selectedSquare: c.selectedSquare,
                            legalTargets: c.legalTargets,
                            interactionEnabled: !c.boardDisabled,
                            onSquareTap: c.onSquareTap,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
