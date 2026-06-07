import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import '../config/theme.dart';
import '../controllers/auth_controller.dart';
import '../controllers/batch_controller.dart';
import '../controllers/home_controller.dart';
import '../controllers/payments_controller.dart';
import '../controllers/puzzle_controller.dart';
import '../controllers/reminders_controller.dart';
import '../controllers/support_controller.dart';
import '../widgets/animated_ui.dart';
import '../widgets/app_ui.dart';
import '../widgets/loading_view.dart';
import 'home_view.dart';
import 'batch_view.dart';
import 'payments_view.dart';
import 'practice_view.dart';
import 'puzzles_view.dart';
import 'reminders_view.dart';
import 'support_view.dart';

class MainShellView extends StatefulWidget {
  const MainShellView({super.key});

  @override
  State<MainShellView> createState() => _MainShellViewState();
}

class _MainShellViewState extends State<MainShellView> {
  int _tab = 0;
  bool _loadedTabs = false;

  static const _titles = [
    'Home',
    'My Batch',
    'Payments',
    'Puzzles',
    'Chess Board',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitial());
  }

  Future<void> _loadInitial() async {
    await context.read<HomeController>().load();
    if (mounted) setState(() => _loadedTabs = true);
  }

  void _onTabChanged(int index) {
    setState(() => _tab = index);
    switch (index) {
      case 1:
        context.read<BatchController>().load();
      case 2:
        context.read<PaymentsController>().load();
      case 3:
        context.read<PuzzleController>().loadPuzzle(forceNew: true);
    }
  }

  void _openReminders() {
    context.read<RemindersController>().load();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const _RemindersPage(),
      ),
    );
  }

  void _openSupport() {
    context.read<SupportController>().load();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const _SupportPage(),
      ),
    );
  }

  Future<void> _openTodaysTournament() async {
    final uri = Uri.parse(AppConfig.todayTournamentUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open tournament link')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final home = context.watch<HomeController>();
    final reminderCount = home.reminderCount;

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: Column(
        children: [
          AppGradientHeader(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Column(
                          key: ValueKey(_tab),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _titles[_tab],
                              style: Theme.of(context).appBarTheme.titleTextStyle,
                            ),
                            if (_tab == 0)
                              Text(
                                auth.user?.firstName ?? 'Student',
                                style: TextStyle(
                                  color: AppColors.white.withValues(alpha: 0.75),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    ScaleTap(
                      onTap: _openTodaysTournament,
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppColors.accentOrange,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accentOrange.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.emoji_events_outlined, size: 16, color: AppColors.white),
                            SizedBox(width: 6),
                            Text(
                              "Today's tournament",
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    ScaleTap(
                      onTap: _openSupport,
                      child: const _HeaderIconButton(icon: Icons.support_agent_outlined),
                    ),
                    const SizedBox(width: 8),
                    ScaleTap(
                      onTap: _openReminders,
                      child: _HeaderIconButton(
                        icon: Icons.notifications_outlined,
                        badge: reminderCount > 0 ? reminderCount : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ScaleTap(
                      onTap: () async {
                        await auth.logout();
                        if (context.mounted) {
                          Navigator.of(context).pushReplacementNamed('/login');
                        }
                      },
                      child: _HeaderIconButton(icon: Icons.logout_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: !_loadedTabs && _tab == 0
                ? const LoadingView()
                : IndexedStack(
                    index: _tab,
                    children: [
                      HomeView(
                        onNavigateToTab: _onTabChanged,
                        onOpenReminders: _openReminders,
                      ),
                      BatchView(showAppBar: false),
                      PaymentsView(showAppBar: false),
                      PuzzlesView(),
                      PracticeView(),
                    ],
                  ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.white,
              AppColors.offWhite,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: _onTabChanged,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            indicatorColor: AppColors.lightBlue,
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
              NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups_rounded), label: 'Batch'),
              NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet_rounded), label: 'Pay'),
              NavigationDestination(icon: Icon(Icons.extension_outlined), selectedIcon: Icon(Icons.extension_rounded), label: 'Puzzle'),
              NavigationDestination(icon: Icon(Icons.sports_esports_outlined), selectedIcon: Icon(Icons.sports_esports_rounded), label: 'Board'),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, this.badge});

  final IconData icon;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon, size: 24, color: AppColors.white),
          if (badge != null)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                decoration: BoxDecoration(
                  color: AppColors.accentOrange,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.white, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  badge! > 9 ? '9+' : '$badge',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SupportPage extends StatelessWidget {
  const _SupportPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: Column(
        children: [
          AppGradientHeader(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 20, 12),
                child: Row(
                  children: [
                    ScaleTap(
                      onTap: () => Navigator.of(context).pop(),
                      child: _HeaderIconButton(icon: Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Support',
                      style: Theme.of(context).appBarTheme.titleTextStyle,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Expanded(child: SupportView()),
        ],
      ),
    );
  }
}

class _RemindersPage extends StatelessWidget {
  const _RemindersPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: Column(
        children: [
          AppGradientHeader(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 20, 12),
                child: Row(
                  children: [
                    ScaleTap(
                      onTap: () => Navigator.of(context).pop(),
                      child: _HeaderIconButton(icon: Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Reminders',
                      style: Theme.of(context).appBarTheme.titleTextStyle,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Expanded(child: RemindersView()),
        ],
      ),
    );
  }
}
