import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive_layout.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController(text: 'The Golden Spoon');
  final TextEditingController _phoneController = TextEditingController(text: '(123) 456-7890');
  final TextEditingController _emailController = TextEditingController(text: 'contact@thegoldenspoon.com');
  final TextEditingController _websiteController = TextEditingController(text: 'www.thegoldenspoon.com');
  final TextEditingController _addressController = TextEditingController(text: '123 Culinary Lane, Foodie City');

  final List<OperatingHour> _operatingHours = [
    OperatingHour(day: 'Monday', hours: '9:00 AM - 10:00 PM'),
    OperatingHour(day: 'Tuesday', hours: '9:00 AM - 10:00 PM'),
    OperatingHour(day: 'Wednesday', hours: '9:00 AM - 10:00 PM'),
    OperatingHour(day: 'Thursday', hours: '9:00 AM - 10:00 PM'),
    OperatingHour(day: 'Friday', hours: '9:00 AM - 11:00 PM'),
    OperatingHour(day: 'Saturday', hours: '10:00 AM - 11:00 PM'),
    OperatingHour(day: 'Sunday', hours: 'Closed'),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    super.dispose();
  }

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
      // Bottom Save Button
      bottomNavigationBar: _buildBottomButton(theme),
    );
  }

  Widget _buildAppBar(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.background,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline,
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
                'Restaurant Profile',
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
          // Profile Header
          _buildProfileHeader(theme, isDark),
          const SizedBox(height: 24),
          // Text Input Fields
          _buildInputFields(theme, isDark),
          const SizedBox(height: 24),
          // Address Section
          _buildAddressSection(theme, isDark),
          const SizedBox(height: 24),
          // Operating Hours
          _buildOperatingHours(theme, isDark),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme, bool isDark) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: const DecorationImage(
                  image: NetworkImage(
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuB8XnIBCACDcwN4hYLZBtfLvNlN6pD1EqPfYvSRIOUYe8gB3WujDDq28Df_u1g02xzBUNctz5xVg8pymztZhHPTzqGQ0E9HGtj7dEwskzsCT0InGwOJ9UZSUslLE5H_0YE9nQDt9cUj_b8_anFZXxiIPFISpe4mzjVqvMFWXaNlKp-fGB_eMf3TXhoUEwr35Lq4LxFqP0UiHDoZRs7QClbZNmlAPMgfbQHRBcBPauWkFpFweORpR8XboR6yTr7To6wy18HkHZnjkpQ',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.background,
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.edit,
                  color: theme.colorScheme.onPrimary,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'The Golden Spoon',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'contact@thegoldenspoon.com',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildInputFields(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          theme: theme,
          isDark: isDark,
          label: 'Restaurant Name',
          controller: _nameController,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          theme: theme,
          isDark: isDark,
          label: 'Phone Number',
          controller: _phoneController,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          theme: theme,
          isDark: isDark,
          label: 'Email Address',
          controller: _emailController,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          theme: theme,
          isDark: isDark,
          label: 'Website (Optional)',
          controller: _websiteController,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required ThemeData theme,
    required bool isDark,
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: theme.colorScheme.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.colorScheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.colorScheme.primary),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddressSection(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Address',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        _buildTextField(
          theme: theme,
          isDark: isDark,
          label: 'Street Address',
          controller: _addressController,
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () {
            // Handle view on map
          },
          style: OutlinedButton.styleFrom(
            backgroundColor: theme.colorScheme.surfaceVariant,
            foregroundColor: theme.colorScheme.primary,
            side: BorderSide(color: theme.colorScheme.outline),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            minimumSize: const Size(double.infinity, 40),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.map,
                color: theme.colorScheme.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'View on Map',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOperatingHours(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Operating Hours',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: _operatingHours.map((hour) => _buildOperatingHourRow(hour, theme)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildOperatingHourRow(OperatingHour hour, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Day column - fixed width to prevent overflow
          SizedBox(
            width: 100,
            child: Text(
              hour.day,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Hours and edit button - flexible
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Hours text - flexible
                Expanded(
                  child: Text(
                    hour.hours,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),

                // Edit button - fixed width
                IconButton(
                  onPressed: () {
                    // Handle edit operating hours
                  },
                  icon: Icon(
                    Icons.edit,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  padding: const EdgeInsets.only(left: 8),
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.background.withOpacity(0.8),
      ),
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          disabledBackgroundColor: theme.colorScheme.primary.withOpacity(0.5),
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: Text(
          'Save Changes',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class OperatingHour {
  final String day;
  final String hours;

  OperatingHour({
    required this.day,
    required this.hours,
  });
}