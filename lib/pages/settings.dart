import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _newOrderAlerts = true;
  bool _orderUpdateAlerts = false;
  bool _lowStockWarnings = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            _buildAppBar(theme),
            // Content
            Expanded(
              child: _buildContent(theme, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.background,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.1),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            IconButton(
              onPressed: () => context.push('/home'),
              icon: Icon(
                Icons.arrow_back,
                color: theme.colorScheme.onBackground,
                size: 24,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Settings',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Account Settings Section
          _buildAccountSection(theme, isDark),
          const SizedBox(height: 24),
          // Notification Preferences Section
          _buildNotificationSection(theme, isDark),
          const SizedBox(height: 24),
          // Business Information Section
          _buildBusinessSection(theme, isDark),
          const SizedBox(height: 24),
          // App Information Section
          _buildAppSection(theme, isDark),
        ],
      ),
    );
  }

  Widget _buildAccountSection(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'ACCOUNT',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.015,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildSettingsItem(
                theme: theme,
                icon: Icons.person,
                title: 'Edit Profile',
                onTap: () {
                  context.push('/profile');
                },
              ),
              _buildDivider(theme),
              _buildSettingsItem(
                theme: theme,
                icon: Icons.mail,
                title: 'Change Email',
                onTap: () {
                  // Navigate to change email
                },
              ),
              _buildDivider(theme),
              _buildSettingsItem(
                theme: theme,
                icon: Icons.lock,
                title: 'Change Password',
                onTap: () {
                  // Navigate to change password
                },
              ),
              _buildDivider(theme),
              _buildLogoutItem(theme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationSection(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'NOTIFICATIONS',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.015,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildToggleItem(
                theme: theme,
                icon: Icons.notifications,
                title: 'New Order Alerts',
                value: _newOrderAlerts,
                onChanged: (value) {
                  setState(() {
                    _newOrderAlerts = value;
                  });
                },
              ),
              _buildDivider(theme),
              _buildToggleItem(
                theme: theme,
                icon: Icons.update,
                title: 'Order Update Alerts',
                value: _orderUpdateAlerts,
                onChanged: (value) {
                  setState(() {
                    _orderUpdateAlerts = value;
                  });
                },
              ),
              _buildDivider(theme),
              _buildToggleItem(
                theme: theme,
                icon: Icons.inventory,
                title: 'Low Stock Warnings',
                value: _lowStockWarnings,
                onChanged: (value) {
                  setState(() {
                    _lowStockWarnings = value;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBusinessSection(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'BUSINESS INFORMATION',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.015,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildSettingsItem(
                theme: theme,
                icon: Icons.schedule,
                title: 'Restaurant Hours',
                onTap: () {
                  // Navigate to restaurant hours
                },
              ),
              _buildDivider(theme),
              _buildSettingsItem(
                theme: theme,
                icon: Icons.call,
                title: 'Contact Details',
                onTap: () {
                  // Navigate to contact details
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppSection(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'APP',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.015,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildSettingsItem(
                theme: theme,
                icon: Icons.help,
                title: 'Help & Support',
                onTap: () {
                  // Navigate to help & support
                },
              ),
              _buildDivider(theme),
              _buildSettingsItem(
                theme: theme,
                icon: Icons.description,
                title: 'Terms of Service',
                onTap: () {
                  // Navigate to terms of service
                },
              ),
              _buildDivider(theme),
              _buildAppVersionItem(theme, isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsItem({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: theme.colorScheme.primary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: theme.colorScheme.onSurfaceVariant,
        size: 20,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      minLeadingWidth: 0,
    );
  }

  Widget _buildToggleItem({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: theme.colorScheme.primary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: theme.colorScheme.primary,
        inactiveTrackColor: theme.colorScheme.outlineVariant,
        inactiveThumbColor: theme.colorScheme.onSurfaceVariant,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      minLeadingWidth: 0,
    );
  }

  Widget _buildLogoutItem(ThemeData theme) {
    return ListTile(
      onTap: () {
        _showLogoutConfirmation(theme);
      },
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.colorScheme.error.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.logout,
          color: theme.colorScheme.error,
          size: 20,
        ),
      ),
      title: Text(
        'Log Out',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.error,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      minLeadingWidth: 0,
    );
  }

  Widget _buildAppVersionItem(ThemeData theme, bool isDark) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.info,
          color: theme.colorScheme.primary,
          size: 20,
        ),
      ),
      title: Text(
        'App Version',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
      ),
      trailing: Text(
        '1.2.3',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      minLeadingWidth: 0,
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Divider(
      height: 1,
      color: theme.colorScheme.outline.withOpacity(0.1),
      indent: 72,
    );
  }

  void _showLogoutConfirmation(ThemeData theme) {
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
                // Handle logout logic
                context.go('/login');
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