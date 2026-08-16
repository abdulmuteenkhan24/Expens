import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import 'shell_screen.dart';

/// Bumped when onboarding content changes so users see the new privacy slides.
const onboardingDoneKey = 'onboarding_done_v2';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _page = PageController();
  int _index = 0;

  static const _pages = <_OnboardPage>[
    _OnboardPage(
      icon: Icons.shield_rounded,
      title: 'Private by design',
      subtitle:
          'Your money data stays on this phone. No account, no cloud, no tracking.',
      color: Color(0xFF00C853),
      points: [
        _OnboardPoint(
          Icons.lock_rounded,
          'Full privacy',
          'Expenses, loans & balances never leave your device',
        ),
        _OnboardPoint(
          Icons.wifi_off_rounded,
          'Works offline',
          'No internet required to use the app day to day',
        ),
        _OnboardPoint(
          Icons.cloud_off_rounded,
          'No cloud sync',
          'Nothing is uploaded to our servers — we don’t have any',
        ),
        _OnboardPoint(
          Icons.person_off_rounded,
          'No sign-in',
          'No email, Google, or password. Open and start tracking',
        ),
      ],
    ),
    _OnboardPage(
      icon: Icons.account_balance_wallet_rounded,
      title: 'See everything you have',
      subtitle:
          'Cash, bank, JazzCash, EasyPaisa — one clean balance. Know your money at a glance.',
      color: Color(0xFF00BFA5),
    ),
    _OnboardPage(
      icon: Icons.receipt_long_rounded,
      title: 'Track spend in seconds',
      subtitle:
          'Add expenses & income, paste bank SMS, tag trips and events. Fast and local.',
      color: Color(0xFF26A69A),
    ),
    _OnboardPage(
      icon: Icons.handshake_rounded,
      title: 'Loans, reports & backup',
      subtitle:
          'Manage udhaar, filter reports, and export a file yourself when you change phones — you control the backup.',
      color: Color(0xFF448AFF),
    ),
  ];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(onboardingDoneKey, true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const ShellScreen(),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 420),
      ),
    );
  }

  void _next() {
    if (_index >= _pages.length - 1) {
      _finish();
    } else {
      _page.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isLast = _index == _pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  const AppLogo(size: 36),
                  const SizedBox(width: 10),
                  Text(
                    'Expens',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const Spacer(),
                  if (!isLast)
                    TextButton(
                      onPressed: _finish,
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.55),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _page,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final p = _pages[i];
                  final hasPoints = p.points.isNotEmpty;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: hasPoints
                          ? MainAxisAlignment.start
                          : MainAxisAlignment.center,
                      children: [
                        if (hasPoints) const SizedBox(height: 12),
                        Container(
                          width: hasPoints ? 104 : 148,
                          height: hasPoints ? 104 : 148,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                p.color.withValues(alpha: 0.22),
                                p.color.withValues(alpha: 0.08),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: p.color.withValues(alpha: 0.2),
                                blurRadius: 32,
                                offset: const Offset(0, 14),
                              ),
                            ],
                          ),
                          child: Icon(
                            p.icon,
                            size: hasPoints ? 48 : 64,
                            color: p.color,
                          ),
                        ),
                        SizedBox(height: hasPoints ? 20 : 36),
                        Text(
                          p.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                                height: 1.2,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          p.subtitle,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: cs.onSurface.withValues(alpha: 0.55),
                                    height: 1.45,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                        if (hasPoints) ...[
                          const SizedBox(height: 22),
                          ...p.points.map(
                            (pt) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _PrivacyTile(
                                icon: pt.icon,
                                title: pt.title,
                                subtitle: pt.subtitle,
                                color: p.color,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
            // Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                final on = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: on ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: on
                        ? AppColors.primary
                        : cs.onSurface.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              }),
            ),
            const SizedBox(height: 18),
            if (isLast)
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 8),
                child: Text(
                  'By continuing you keep full control — data stays on this device.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.45),
                        height: 1.35,
                      ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: FilledButton(
                onPressed: _next,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  isLast ? 'Get started — stay private' : 'Continue',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _PrivacyTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.3,
                    color: cs.onSurface.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w500,
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

class _OnboardPoint {
  final IconData icon;
  final String title;
  final String subtitle;

  const _OnboardPoint(this.icon, this.title, this.subtitle);
}

class _OnboardPage {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final List<_OnboardPoint> points;

  const _OnboardPage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.points = const [],
  });
}

/// Splash while prefs load, then routes to onboarding or shell.
class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  bool? _showOnboarding;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getBool(onboardingDoneKey) ?? false;
    if (!mounted) return;
    setState(() => _showOnboarding = !done);
  }

  @override
  Widget build(BuildContext context) {
    if (_showOnboarding == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppLogo(size: 88, glow: true),
              const SizedBox(height: 20),
              Text(
                'Expens',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Private · Offline · On your phone',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.45),
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 24),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ],
          ),
        ),
      );
    }
    if (_showOnboarding!) {
      return const OnboardingScreen();
    }
    return const ShellScreen();
  }
}
