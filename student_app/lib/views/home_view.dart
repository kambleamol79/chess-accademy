import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../config/theme.dart';
import '../controllers/auth_controller.dart';
import '../controllers/home_controller.dart';
import '../controllers/puzzle_controller.dart';
import '../models/batch.dart';
import '../widgets/animated_ui.dart';
import '../widgets/app_ui.dart';
import '../widgets/loading_view.dart';
import '../widgets/reminder_tile.dart';
// FEATURE: live arena — enable when ready
// import 'arena_view.dart';

class HomeView extends StatelessWidget {
  const HomeView({
    super.key,
    required this.onNavigateToTab,
    required this.onOpenReminders,
  });

  final ValueChanged<int> onNavigateToTab;
  final VoidCallback onOpenReminders;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final home = context.watch<HomeController>();
    final puzzles = context.watch<PuzzleController>();

    if (home.loading) return const LoadingView(message: 'Loading your dashboard…');
    if (home.error != null) {
      return ErrorView(message: home.error!, onRetry: home.load);
    }

    return RefreshIndicator(
      color: AppColors.accentOrange,
      onRefresh: home.load,
      child: Container(
        decoration: const BoxDecoration(gradient: AppColors.surfaceGradient),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          children: [
            StaggeredFadeIn(
              index: 0,
              child: _WelcomeHero(userName: auth.user?.fullName ?? 'Student'),
            ),
            StaggeredFadeIn(
              index: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  AppSectionHeader(
                    title: 'Upcoming batch',
                    subtitle: 'Your next class schedule',
                    trailing: home.batch != null
                        ? TextButton(
                            onPressed: () => onNavigateToTab(1),
                            child: const Text('Details', style: TextStyle(fontWeight: FontWeight.w700)),
                          )
                        : null,
                  ),
                  if (home.batch != null)
                    _BatchPreviewCard(batch: home.batch!, onTap: () => onNavigateToTab(1))
                  else
                    const AppEmptyState(
                      message: 'No batch assigned yet.\nContact the academy admin.',
                      icon: Icons.groups_rounded,
                    ),
                ],
              ),
            ),
            // FEATURE: live arena — enable when ready
            // StaggeredFadeIn(
            //   index: 2,
            //   child: Padding(
            //     padding: const EdgeInsets.only(top: 16),
            //     child: ScaleTap(
            //       onTap: () {
            //         Navigator.of(context).push(
            //           MaterialPageRoute<void>(builder: (_) => const ArenaView()),
            //         );
            //       },
            //       child: Container(
            //         width: double.infinity,
            //         padding: const EdgeInsets.all(18),
            //         decoration: BoxDecoration(
            //           gradient: LinearGradient(
            //             colors: [
            //               AppColors.primaryBlue,
            //               AppColors.primaryBlue.withValues(alpha: 0.85),
            //             ],
            //           ),
            //           borderRadius: BorderRadius.circular(16),
            //           boxShadow: [
            //             BoxShadow(
            //               color: AppColors.primaryBlue.withValues(alpha: 0.25),
            //               blurRadius: 12,
            //               offset: const Offset(0, 6),
            //             ),
            //           ],
            //         ),
            //         child: Row(
            //           children: [
            //             const Icon(Icons.emoji_events_rounded, color: AppColors.white, size: 32),
            //             const SizedBox(width: 14),
            //             Expanded(
            //               child: Column(
            //                 crossAxisAlignment: CrossAxisAlignment.start,
            //                 children: [
            //                   Text(
            //                     'Chess arena',
            //                     style: Theme.of(context).textTheme.titleMedium?.copyWith(
            //                           color: AppColors.white,
            //                           fontWeight: FontWeight.w800,
            //                         ),
            //                   ),
            //                   Text(
            //                     'Play live vs other students',
            //                     style: TextStyle(
            //                       color: AppColors.white.withValues(alpha: 0.85),
            //                       fontSize: 13,
            //                     ),
            //                   ),
            //                 ],
            //               ),
            //             ),
            //             Icon(Icons.arrow_forward_rounded, color: AppColors.white.withValues(alpha: 0.9)),
            //           ],
            //         ),
            //       ),
            //     ),
            //   ),
            // ),
            StaggeredFadeIn(
              index: 3,
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: AppStatCard(
                        label: 'Reminders',
                        value: '${home.reminderCount}',
                        icon: Icons.notifications_active_rounded,
                        color: AppColors.accentOrange,
                        index: 0,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppStatCard(
                        label: 'Puzzles solved',
                        value: puzzles.solvedCount > 0 ? '${puzzles.solvedCount}' : '—',
                        icon: Icons.emoji_events_rounded,
                        color: AppColors.success,
                        index: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            StaggeredFadeIn(
              index: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 22),
                  AppSectionHeader(
                    title: 'Upcoming reminders',
                    subtitle: 'Classes, payments & practice',
                    trailing: home.reminders.isNotEmpty
                        ? TextButton(
                            onPressed: onOpenReminders,
                            child: const Text('See all', style: TextStyle(fontWeight: FontWeight.w700)),
                          )
                        : null,
                  ),
                  if (home.reminders.isEmpty)
                    const AppEmptyState(
                      message: 'All clear — no reminders right now.',
                      icon: Icons.check_circle_outline_rounded,
                    )
                  else
                    ...home.reminders.take(3).map((r) => ReminderTile(reminder: r)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeHero extends StatelessWidget {
  const _WelcomeHero({required this.userName});

  final String userName;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get _initials {
    final parts = userName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'S';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        gradient: AppColors.heroGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -20,
            right: -10,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            bottom: -15,
            left: 30,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentOrange.withValues(alpha: 0.12),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.white.withValues(alpha: 0.28),
                            AppColors.white.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.white.withValues(alpha: 0.25)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _initials,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _greeting,
                            style: TextStyle(
                              color: AppColors.white.withValues(alpha: 0.8),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            userName,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.emoji_events_rounded, color: AppColors.white, size: 24),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: AppColors.white.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.school_rounded, color: AppColors.white.withValues(alpha: 0.85), size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppConfig.appName,
                              style: const TextStyle(
                                color: AppColors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            ShaderMask(
                              shaderCallback: (bounds) => AppColors.accentGradient.createShader(bounds),
                              child: const Text(
                                'Train · Play · Improve',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BatchPreviewCard extends StatelessWidget {
  const _BatchPreviewCard({required this.batch, required this.onTap});

  final StudentBatch batch;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ScaleTap(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: const BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppRadius.md),
                  topRight: Radius.circular(AppRadius.md),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.white.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      batch.batch,
                      style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                  ),
                  const Spacer(),
                  if (batch.module != null && batch.module!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: AppColors.accentGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        batch.module!,
                        style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 11),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _BatchInfoChip(icon: Icons.calendar_month_rounded, text: batch.daysSummary),
                  const SizedBox(width: 8),
                  _BatchInfoChip(icon: Icons.schedule_rounded, text: batch.time),
                ],
              ),
            ),
            if (batch.coachesLabel != 'Not assigned')
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Icon(Icons.person_rounded, size: 16, color: AppColors.textMuted.withValues(alpha: 0.8)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        batch.coachesLabel,
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.primaryBlue.withValues(alpha: 0.6)),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('View batch', style: TextStyle(fontSize: 12, color: AppColors.primaryBlue.withValues(alpha: 0.8), fontWeight: FontWeight.w700)),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.primaryBlue.withValues(alpha: 0.6)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BatchInfoChip extends StatelessWidget {
  const _BatchInfoChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.lightBlue,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: AppColors.primaryBlue),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textDark),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
