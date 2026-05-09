// lib/shared/widgets/bottom_nav_bar.dart
//
// The main app shell with bottom navigation bar.
// 5 tabs: Home, Scan, Recommend, Learn, Profile
// All key actions reachable within 2 taps from home (design spec).

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/scan/screens/scan_screen.dart';
import '../../features/recommend/screens/recommend_screen.dart';
import '../../features/learn/screens/learn_screen.dart';
import '../../features/profile/screens/profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  // Pages — kept alive so state is preserved when switching tabs
  static const List<Widget> _pages = [
    HomeScreen(),
    ScanScreen(),
    RecommendScreen(),
    LearnScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _GiziOneNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ── Custom styled bottom nav bar ───────────────────────────────────────────

class _GiziOneNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _GiziOneNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    _NavItem(icon: Icons.home_rounded, label: 'Home'),
    _NavItem(icon: Icons.qr_code_scanner_rounded, label: 'Scan'),
    _NavItem(icon: Icons.restaurant_menu_rounded, label: 'Rekomen'),
    _NavItem(icon: Icons.menu_book_rounded, label: 'Pelajari'),
    _NavItem(icon: Icons.person_rounded, label: 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(_items.length, (i) {
              final selected = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // ── Scan tab gets special pill indicator ──
                        if (i == 1)
                          Container(
                            width: 48,
                            height: 36,
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primaryGreen
                                  : AppColors.background,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Icon(
                              _items[i].icon,
                              color:
                                  selected ? Colors.white : AppColors.textGrey,
                              size: 22,
                            ),
                          )
                        else
                          Icon(
                            _items[i].icon,
                            color: selected
                                ? AppColors.primaryGreen
                                : AppColors.textGrey,
                            size: 22,
                          ),
                        const SizedBox(height: 3),
                        Text(
                          _items[i].label,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w400,
                            color: selected
                                ? AppColors.primaryGreen
                                : AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
