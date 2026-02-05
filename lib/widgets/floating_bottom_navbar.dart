// lib/widgets/floating_bottom_navbar.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/responsive_layout.dart';

class FloatingBottomNavbar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const FloatingBottomNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      builder: (context, constraints) {
        final bool isLargeScreen = constraints.maxWidth > 600;
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return Container(
          margin: EdgeInsets.fromLTRB(
            isLargeScreen ? 32 : 16,
            isLargeScreen ? 16 : 8,
            isLargeScreen ? 32 : 16,
            isLargeScreen ? 32 : 24,
          ),
          height: isLargeScreen ? 80 : 70,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF152E26) : Colors.white,
            borderRadius: BorderRadius.circular(isLargeScreen ? 35 : 30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              _buildNavItem(
                context,
                icon: Icons.home_outlined,
                label: 'Home',
                index: 0,
                isLargeScreen: isLargeScreen,
              ),
              _buildNavItem(
                context,
                icon: Icons.add_circle_outline,
                label: 'Upload',
                index: 1,
                isLargeScreen: isLargeScreen,
              ),
              _buildNavItem(
                context,
                icon: Icons.person_outline,
                label: 'Profile',
                index: 2,
                isLargeScreen: isLargeScreen,
              ),
              _buildNavItem(
                context,
                icon: Icons.settings_outlined,
                label: 'Settings',
                index: 3,
                isLargeScreen: isLargeScreen,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavItem(
      BuildContext context, {
        required IconData icon,
        required String label,
        required int index,
        required bool isLargeScreen,
      }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isActive = currentIndex == index;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(isLargeScreen ? 30 : 25),
          onTap: () => onTap(index),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: isLargeScreen ? 28 : 24,
                color: isActive
                    ? AppColors.primary
                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
              SizedBox(height: isLargeScreen ? 6 : 4),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isActive
                      ? AppColors.primary
                      : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  fontSize: isLargeScreen ? 14 : 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}