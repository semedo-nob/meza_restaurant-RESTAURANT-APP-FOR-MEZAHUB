import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive_layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailPhoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailPhoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);

    final success = await userProvider.login(
      _emailPhoneController.text.trim(),
      _passwordController.text.trim(),
    );

    if (success && mounted) {
      context.go('/home');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login successful!')),
      );
    }
    // Error is handled by the provider and displayed in the UI
  }

  void _resetPassword() {
    if (_emailPhoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email address')),
      );
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    userProvider.resetPassword(_emailPhoneController.text.trim()).then((success) {
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email sent')),
        );
      }
    });
  }

  void _navigateToSignUp() {
    context.go('/sign_up');
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: ResponsiveLayout(
          builder: (context, constraints) {
            final bool isLargeScreen = constraints.maxWidth > 600;
            final double maxWidth = isLargeScreen ? 400 : double.infinity;
            final double borderRadius = _getBorderRadiusValue(constraints);
            final EdgeInsets contentPadding = _getContentPaddingValue(constraints);

            return SingleChildScrollView(
              child: ResponsivePadding(
                mobilePadding: 16.0,
                tabletPadding: 24.0,
                desktopPadding: 32.0,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // App Logo
                          ResponsiveValue<double>(
                            mobileValue: 64.0,
                            tabletValue: 80.0,
                            desktopValue: 96.0,
                            builder: (logoSize) => Container(
                              width: logoSize,
                              height: logoSize,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(logoSize * 0.25),
                              ),
                              child: ResponsiveValue<double>(
                                mobileValue: 32.0,
                                tabletValue: 40.0,
                                desktopValue: 48.0,
                                builder: (iconSize) => Icon(
                                  Icons.restaurant,
                                  color: AppColors.primary,
                                  size: iconSize,
                                ),
                              ),
                            ),
                          ),

                          // Headline Text
                          ResponsiveValue<double>(
                            mobileValue: 32.0,
                            tabletValue: 40.0,
                            desktopValue: 48.0,
                            builder: (spacing) => SizedBox(height: spacing),
                          ),
                          ResponsiveValue<TextStyle>(
                            mobileValue: theme.textTheme.displaySmall!.copyWith(
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              fontWeight: FontWeight.w700,
                            ),
                            tabletValue: theme.textTheme.displayMedium!.copyWith(
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              fontWeight: FontWeight.w700,
                            ),
                            desktopValue: theme.textTheme.displayLarge!.copyWith(
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              fontWeight: FontWeight.w700,
                            ),
                            builder: (textStyle) => Text(
                              'Welcome Back',
                              style: textStyle,
                              textAlign: TextAlign.center,
                            ),
                          ),

                          // Body Text
                          ResponsiveValue<double>(
                            mobileValue: 8.0,
                            tabletValue: 12.0,
                            desktopValue: 16.0,
                            builder: (spacing) => SizedBox(height: spacing),
                          ),
                          ResponsiveValue<TextStyle>(
                            mobileValue: theme.textTheme.bodyMedium!.copyWith(
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                            tabletValue: theme.textTheme.bodyLarge!.copyWith(
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                            desktopValue: theme.textTheme.bodyLarge!.copyWith(
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              fontSize: 18,
                            ),
                            builder: (textStyle) => Text(
                              'Log in to your account to manage orders.',
                              style: textStyle,
                              textAlign: TextAlign.center,
                            ),
                          ),

                          // Error Message
                          if (userProvider.error != null) ...[
                            ResponsiveValue<double>(
                              mobileValue: 24.0,
                              tabletValue: 32.0,
                              desktopValue: 40.0,
                              builder: (spacing) => SizedBox(height: spacing),
                            ),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(borderRadius),
                                border: Border.all(color: Colors.red),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error, color: Colors.red),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      userProvider.error!,
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 16),
                                    onPressed: userProvider.clearError,
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Form Fields
                          ResponsiveValue<double>(
                            mobileValue: 32.0,
                            tabletValue: 40.0,
                            desktopValue: 48.0,
                            builder: (spacing) => SizedBox(height: spacing),
                          ),
                          Column(
                            children: [
                              // Email Field
                              _buildTextField(
                                context: context,
                                label: 'Email',
                                hintText: 'Enter your email address',
                                controller: _emailPhoneController,
                                borderRadius: borderRadius,
                                contentPadding: contentPadding,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter email address';
                                  }
                                  if (!value.contains('@')) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                              ),

                              ResponsiveValue<double>(
                                mobileValue: 16.0,
                                tabletValue: 20.0,
                                desktopValue: 24.0,
                                builder: (spacing) => SizedBox(height: spacing),
                              ),

                              // Password Field
                              _buildPasswordField(
                                context: context,
                                label: 'Password',
                                hintText: 'Enter your password',
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                borderRadius: borderRadius,
                                contentPadding: contentPadding,
                                onToggleVisibility: _togglePasswordVisibility,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter password';
                                  }
                                  if (value.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),

                          // Login Button
                          ResponsiveValue<double>(
                            mobileValue: 24.0,
                            tabletValue: 32.0,
                            desktopValue: 40.0,
                            builder: (spacing) => SizedBox(height: spacing),
                          ),
                          ResponsiveValue<double>(
                            mobileValue: 48.0,
                            tabletValue: 56.0,
                            desktopValue: 64.0,
                            builder: (buttonHeight) => SizedBox(
                              width: double.infinity,
                              height: buttonHeight,
                              child: ElevatedButton(
                                onPressed: userProvider.isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.backgroundDark,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(borderRadius),
                                  ),
                                  elevation: 0,
                                ),
                                child: userProvider.isLoading
                                    ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(Colors.white),
                                  ),
                                )
                                    : ResponsiveValue<double>(
                                  mobileValue: 16.0,
                                  tabletValue: 18.0,
                                  desktopValue: 20.0,
                                  builder: (fontSize) => Text(
                                    'Login',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.backgroundDark,
                                      fontSize: fontSize,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Secondary Links
                          ResponsiveValue<double>(
                            mobileValue: 24.0,
                            tabletValue: 32.0,
                            desktopValue: 40.0,
                            builder: (spacing) => SizedBox(height: spacing),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: _resetPassword,
                                child: ResponsiveValue<double>(
                                  mobileValue: 14.0,
                                  tabletValue: 16.0,
                                  desktopValue: 18.0,
                                  builder: (fontSize) => Text(
                                    'Forgot Password?',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w500,
                                      fontSize: fontSize,
                                    ),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: _navigateToSignUp,
                                child: ResponsiveValue<double>(
                                  mobileValue: 14.0,
                                  tabletValue: 16.0,
                                  desktopValue: 18.0,
                                  builder: (fontSize) => Text(
                                    'Create Account',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w500,
                                      fontSize: fontSize,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  double _getBorderRadiusValue(BoxConstraints constraints) {
    if (constraints.maxWidth >= 1200) {
      return 16.0;
    } else if (constraints.maxWidth >= 600) {
      return 12.0;
    } else {
      return 8.0;
    }
  }

  EdgeInsets _getContentPaddingValue(BoxConstraints constraints) {
    if (constraints.maxWidth >= 1200) {
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 18);
    } else if (constraints.maxWidth >= 600) {
      return const EdgeInsets.symmetric(horizontal: 20, vertical: 16);
    } else {
      return const EdgeInsets.symmetric(horizontal: 16, vertical: 14);
    }
  }

  Widget _buildTextField({
    required BuildContext context,
    required String label,
    required String hintText,
    required TextEditingController controller,
    required double borderRadius,
    required EdgeInsets contentPadding,
    required String? Function(String?) validator,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveValue<double>(
          mobileValue: 14.0,
          tabletValue: 16.0,
          desktopValue: 18.0,
          builder: (fontSize) => Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              fontSize: fontSize,
            ),
          ),
        ),
        ResponsiveValue<double>(
          mobileValue: 8.0,
          tabletValue: 12.0,
          desktopValue: 16.0,
          builder: (spacing) => SizedBox(height: spacing),
        ),
        TextFormField(
          controller: controller,
          validator: validator,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? const Color(0xFF93C8B6) : AppColors.textDisabledLight,
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF1A322A) : const Color(0xFFF1F5F9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF346555) : const Color(0xFFCBD5E1),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF346555) : const Color(0xFFCBD5E1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(
                color: AppColors.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: const BorderSide(
                color: AppColors.error,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: const BorderSide(
                color: AppColors.error,
                width: 2,
              ),
            ),
            contentPadding: contentPadding,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required BuildContext context,
    required String label,
    required String hintText,
    required TextEditingController controller,
    required bool obscureText,
    required double borderRadius,
    required EdgeInsets contentPadding,
    required VoidCallback onToggleVisibility,
    required String? Function(String?) validator,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ResponsiveLayout(
      builder: (context, constraints) {
        final double iconSize = _getIconSizeValue(constraints);
        final double constraintSize = _getConstraintSizeValue(constraints);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveValue<double>(
              mobileValue: 14.0,
              tabletValue: 16.0,
              desktopValue: 18.0,
              builder: (fontSize) => Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  fontSize: fontSize,
                ),
              ),
            ),
            ResponsiveValue<double>(
              mobileValue: 8.0,
              tabletValue: 12.0,
              desktopValue: 16.0,
              builder: (spacing) => SizedBox(height: spacing),
            ),
            TextFormField(
              controller: controller,
              obscureText: obscureText,
              validator: validator,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? const Color(0xFF93C8B6) : AppColors.textDisabledLight,
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF1A322A) : const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF346555) : const Color(0xFFCBD5E1),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF346555) : const Color(0xFFCBD5E1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                  borderSide: BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                  borderSide: const BorderSide(
                    color: AppColors.error,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                  borderSide: const BorderSide(
                    color: AppColors.error,
                    width: 2,
                  ),
                ),
                contentPadding: EdgeInsets.fromLTRB(
                  contentPadding.left,
                  contentPadding.top,
                  contentPadding.right + constraintSize - 8, // Account for icon space
                  contentPadding.bottom,
                ),
                suffixIcon: Padding(
                  padding: EdgeInsets.only(right: contentPadding.right - 8),
                  child: IconButton(
                    onPressed: onToggleVisibility,
                    icon: Icon(
                      obscureText ? Icons.visibility : Icons.visibility_off,
                      color: isDark ? const Color(0xFF93C8B6) : AppColors.textDisabledLight,
                      size: iconSize,
                    ),
                    splashRadius: iconSize * 0.6,
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(
                      minWidth: constraintSize,
                      minHeight: constraintSize,
                    ),
                  ),
                ),
                suffixIconConstraints: BoxConstraints(
                  minWidth: constraintSize,
                  minHeight: constraintSize,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  double _getIconSizeValue(BoxConstraints constraints) {
    if (constraints.maxWidth >= 1200) {
      return 28.0;
    } else if (constraints.maxWidth >= 600) {
      return 24.0;
    } else {
      return 20.0;
    }
  }

  double _getConstraintSizeValue(BoxConstraints constraints) {
    if (constraints.maxWidth >= 1200) {
      return 56.0;
    } else if (constraints.maxWidth >= 600) {
      return 48.0;
    } else {
      return 40.0;
    }
  }
}