import 'package:flutter/material.dart';

import '../widgets/animated_nav_bar.dart';
import 'add_transaction_flow.dart';
import 'home_dashboard.dart';
import 'insight_screen.dart';
import 'loans_screen.dart';
import 'money_screen.dart';

/// Bottom nav: Home | Money | + | Loans | Insight
class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  late final AnimationController _pageAnim;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  static const _items = <NavBarItem>[
    NavBarItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
    ),
    NavBarItem(
      icon: Icons.account_balance_wallet_outlined,
      activeIcon: Icons.account_balance_wallet_rounded,
      label: 'Money',
    ),
    NavBarItem(
      icon: Icons.handshake_outlined,
      activeIcon: Icons.handshake_rounded,
      label: 'Loans',
    ),
    NavBarItem(
      icon: Icons.insights_outlined,
      activeIcon: Icons.insights_rounded,
      label: 'Insight',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fade = CurvedAnimation(parent: _pageAnim, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.018),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _pageAnim, curve: Curves.easeOutCubic),
    );
    _pageAnim.value = 1;
  }

  @override
  void dispose() {
    _pageAnim.dispose();
    super.dispose();
  }

  Future<void> _selectTab(int i) async {
    if (i == _index) return;
    setState(() => _index = i);
    await _pageAnim.forward(from: 0);
  }

  void _openAdd() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, _) => const AddTransactionFlow(),
        transitionsBuilder: (_, anim, _, child) {
          final curved = CurvedAnimation(
            parent: anim,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.08),
                end: Offset.zero,
              ).animate(curved),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.97, end: 1).animate(curved),
                child: child,
              ),
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 340),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Stack body + floating bar so the center FAB can overflow freely.
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: IndexedStack(
                  index: _index,
                  children: const [
                    HomeDashboard(),
                    MoneyScreen(),
                    LoansScreen(),
                    InsightScreen(),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedNavBar(
              selectedIndex: _index,
              items: _items,
              onSelect: _selectTab,
              onCenterTap: _openAdd,
            ),
          ),
        ],
      ),
    );
  }
}
