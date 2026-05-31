import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../controllers/arena_controller.dart';
import '../widgets/app_ui.dart';
import '../widgets/loading_view.dart';
import 'live_match_view.dart';

class ArenaView extends StatefulWidget {
  const ArenaView({super.key});

  @override
  State<ArenaView> createState() => _ArenaViewState();
}

class _ArenaViewState extends State<ArenaView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ArenaController>().load();
    });
  }

  Future<void> _openMatch(int id) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => LiveMatchView(matchId: id)),
    );
    if (mounted) context.read<ArenaController>().load();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ArenaController>();

    if (c.matchedMatchId != null) {
      final id = c.matchedMatchId!;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        c.clearPendingMatch();
        await _openMatch(id);
      });
    }

    if (c.loading) return const LoadingView(message: 'Loading arena…');

    return RefreshIndicator(
      color: AppColors.accentOrange,
      onRefresh: c.load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          if (c.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(c.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          if (c.message.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(c.message, style: const TextStyle(color: AppColors.primaryBlue)),
            ),
          const AppSectionHeader(title: 'Quick play', subtitle: 'Live game vs another student'),
          const SizedBox(height: 8),
          if (c.finding)
            Row(
              children: [
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                const Expanded(child: Text('Waiting for opponent…')),
                TextButton(onPressed: c.cancelFind, child: const Text('Cancel')),
              ],
            )
          else
            FilledButton.icon(
              onPressed: () async {
                final id = await c.findOpponent();
                if (id != null && mounted) await _openMatch(id);
              },
              icon: const Icon(Icons.people_rounded),
              label: const Text('Find opponent'),
            ),
          const SizedBox(height: 24),
          const AppSectionHeader(title: 'Tournaments', subtitle: 'Register and play'),
          const SizedBox(height: 8),
          if (c.tournaments.isEmpty)
            const AppEmptyState(
              message: 'No tournaments scheduled.',
              icon: Icons.emoji_events_outlined,
            )
          else
            ...c.tournaments.map(
              (t) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(
                        '${t.startsAt} · ${t.timeControlMinutes} min · ${t.status}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: [
                          if (t.status == 'registration' || t.status == 'scheduled')
                            OutlinedButton(
                              onPressed: () => c.register(t),
                              child: const Text('Register'),
                            ),
                          FilledButton(
                            onPressed: c.finding
                                ? null
                                : () async {
                                    final id = await c.findOpponent(
                                      tournamentId: t.id,
                                      timeControl: t.timeControlMinutes,
                                    );
                                    if (id != null && mounted) await _openMatch(id);
                                  },
                            child: const Text('Play'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          const AppSectionHeader(title: 'Your matches'),
          ...c.matches.map(
            (m) => ListTile(
              title: Text('${m.whiteName} vs ${m.blackName}'),
              subtitle: Text(m.status),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openMatch(m.id),
            ),
          ),
        ],
      ),
    );
  }
}
