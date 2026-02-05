// lib/widgets/app_drawer.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_colors.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Drawer(
      backgroundColor: theme.colorScheme.background,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header Section
          _buildHeader(context, theme, isDark),

          // Navigation Items
          _buildNavigationItems(context),

          // Theme Toggle
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return _buildThemeToggleItem(context, themeProvider);
            },
          ),

          // Settings
          _buildItem(
            context,
            Icons.settings_outlined,
            'Settings',
                () => context.go('/settings'),
          ),

          const Divider(height: 32),

          // Logout
          _buildItem(
            context,
            Icons.logout_outlined,
            'Logout',
                () => _showLogoutDialog(context),
            color: AppColors.error,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
                Icons.restaurant_menu,
                color: theme.colorScheme.primary,
                size: 40
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Bella Italia',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Italian Restaurant',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationItems(BuildContext context) {
    return Column(
      children: [
        _buildItem(
          context,
          Icons.person_outline,
          'Profile',
              () => context.go('/profile'),
        ),
        _buildItem(
          context,
          Icons.history,
          'Order History',
              () => context.go('/orderhistory'),
        ),
        _buildItem(
          context,
          Icons.account_balance_wallet_outlined,
          'Wallet',
              () => context.go('/wallet'),
        ),
        _buildItem(
          context,
          Icons.bar_chart_outlined,
          'Sales & Analytics',
              () => context.go('/analytics'),
        ),
      ],
    );
  }

  Widget _buildItem(BuildContext context, IconData icon, String title, VoidCallback onTap, {Color? color}) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(
        icon,
        color: color ?? theme.colorScheme.onSurface.withOpacity(0.8),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: color ?? theme.colorScheme.onSurface,
        ),
      ),
      onTap: () {
        context.pop(); // Close drawer first
        onTap(); // Then navigate
      },
    );
  }

  Widget _buildThemeToggleItem(BuildContext context, ThemeProvider themeProvider) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          _getThemeIcon(themeProvider.themeMode),
          color: theme.colorScheme.primary,
          size: 20,
        ),
      ),
      title: Text(
        'Theme',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
      ),
      trailing: DropdownButton<ThemeMode>(
        value: themeProvider.themeMode,
        onChanged: (ThemeMode? newTheme) {
          if (newTheme != null) {
            themeProvider.setTheme(newTheme);
          }
        },
        dropdownColor: theme.colorScheme.surfaceVariant,
        icon: Icon(
          Icons.arrow_drop_down,
          color: theme.colorScheme.onSurface,
        ),
        underline: const SizedBox(),
        items: [
          _buildDropdownItem('🌙 Dark', ThemeMode.dark, context),
          _buildDropdownItem('☀️ Light', ThemeMode.light, context),
          _buildDropdownItem('⚡ Auto', ThemeMode.system, context),
        ],
      ),
    );
  }

  DropdownMenuItem<ThemeMode> _buildDropdownItem(String text, ThemeMode themeMode, BuildContext context) {
    final theme = Theme.of(context);

    return DropdownMenuItem<ThemeMode>(
      value: themeMode,
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  IconData _getThemeIcon(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }

  void _showLogoutDialog(BuildContext context) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surfaceVariant,
          surfaceTintColor: AppColors.transparent,
          title: Text(
            'Log Out',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          content: Text(
            'Are you sure you want to log out?',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Handle logout logic here
                context.go('/login'); // Navigate to login screen
              },
              child: Text(
                'Log Out',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}