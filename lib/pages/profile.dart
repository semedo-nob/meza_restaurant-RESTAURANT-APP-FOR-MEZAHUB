import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive_layout.dart';
import '../providers/user_provider.dart';
import '../services/backend_api.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool _isLoading = true;
  String? _loadError;
  bool _saving = false;
  int? _restaurantId;
  double? _latitude;
  double? _longitude;
  bool _locationLoading = false;
  String? _coverImageUrl;
  String? _logoImageUrl;
  String? _profileImageUrl;
  bool _coverUploading = false;
  bool _logoUploading = false;
  bool _profileUploading = false;

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) { _loadProfileData(); });
  }

  Future<void> _loadProfileData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.user;
      if (user == null) {
        setState(() {
          _loadError = 'Not signed in.';
          _isLoading = false;
        });
        return;
      }
      _nameController.text = user.restaurantName.isNotEmpty ? user.restaurantName : '';
      _phoneController.text = user.phoneNumber.isNotEmpty ? user.phoneNumber : '';
      _emailController.text = user.email.isNotEmpty ? user.email : '';
      _profileImageUrl = user.profileImage.isNotEmpty ? user.profileImage : null;
      _websiteController.text = '';
      _addressController.text = '';

      try {
        final restaurants = await BackendApi.getMyRestaurants();
        if (restaurants.isNotEmpty) {
          final first = restaurants.first as Map<String, dynamic>;
          _restaurantId = (first['id'] as num?)?.toInt();
          final name = first['name'] as String? ?? '';
          final phone = first['phone'] as String? ?? '';
          final address = first['address'] as String? ?? '';
          final lat = first['latitude'];
          final lng = first['longitude'];
          final logo = first['logo_image'];
          final cover = first['cover_image'];
          if (name.isNotEmpty) _nameController.text = name;
          if (phone.isNotEmpty) _phoneController.text = phone;
          if (address.isNotEmpty) _addressController.text = address;
          _latitude = lat is num ? lat.toDouble() : null;
          _longitude = lng is num ? lng.toDouble() : null;
          _logoImageUrl = logo is String && logo.isNotEmpty ? logo : null;
          _coverImageUrl = cover is String && cover.isNotEmpty ? cover : null;
        }
      } catch (_) {
        // No restaurant yet or API error – keep user data in fields
      }
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadError = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locationLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enable location services.'), behavior: SnackBarBehavior.floating),
        );
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission is required.'), behavior: SnackBarBehavior.floating),
          );
        }
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          if (_addressController.text.trim().isEmpty) {
            _addressController.text =
                '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location updated. Tap Save to store.'), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get location: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _locationLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;
    if (user == null) return;
    setState(() => _saving = true);
    try {
      await BackendApi.updateProfile(
        name: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      );
      if (_restaurantId != null) {
        await BackendApi.updateRestaurant(
          _restaurantId!,
          name: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
          coverImage: _coverImageUrl,
          latitude: _latitude,
          longitude: _longitude,
        );
      } else {
        await BackendApi.createRestaurant(
          name: _nameController.text.trim().isEmpty ? user.restaurantName : _nameController.text.trim(),
          phone: _phoneController.text.trim().isEmpty ? user.phoneNumber : _phoneController.text.trim(),
          address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
          coverImage: _coverImageUrl,
          latitude: _latitude,
          longitude: _longitude,
        );
        await _loadProfileData();
      }
      await userProvider.initialize();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = Provider.of<UserProvider>(context).user;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.colorScheme.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_loadError != null) {
      return Scaffold(
        backgroundColor: theme.colorScheme.background,
        appBar: AppBar(title: const Text('Restaurant Profile')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_loadError!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () { _loadProfileData(); },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(theme),
            Expanded(
              child: _buildContent(theme, isDark, user),
            ),
          ],
        ),
      ),
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

  Widget _buildContent(ThemeData theme, bool isDark, dynamic user) {
    final displayName = _nameController.text.trim().isNotEmpty
        ? _nameController.text
        : (user?.restaurantName ?? 'Restaurant');
    final displayEmail = _emailController.text.trim().isNotEmpty
        ? _emailController.text
        : (user?.email ?? '');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildProfileHeader(theme, isDark, displayName, displayEmail),
          const SizedBox(height: 24),
          _buildInputFields(theme, isDark),
          const SizedBox(height: 24),
          _buildAddressSection(theme, isDark),
          const SizedBox(height: 24),
          _buildOperatingHours(theme, isDark),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadRestaurantPhoto() async {
    if (_coverUploading) return;
    if (_restaurantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Save the restaurant first, then upload a cover image.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 85);
    if (xFile == null || !mounted) return;
    setState(() => _coverUploading = true);
    try {
      final restaurant = await BackendApi.uploadRestaurantCoverImage(
        _restaurantId!,
        File(xFile.path),
      );
      final url = restaurant['cover_image'] as String?;
      if (mounted) {
        setState(() {
          _coverImageUrl = url;
          _coverUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo updated. Tap Save to show it on Discover.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _coverUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _pickAndUploadRestaurantLogo() async {
    if (_logoUploading) return;
    if (_restaurantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Save the restaurant first, then upload a logo.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 85);
    if (xFile == null || !mounted) return;
    setState(() => _logoUploading = true);
    try {
      final restaurant = await BackendApi.uploadRestaurantLogoImage(
        _restaurantId!,
        File(xFile.path),
      );
      final url = restaurant['logo_image'] as String?;
      if (mounted) {
        setState(() {
          _logoImageUrl = url;
          _logoUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Restaurant logo updated.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _logoUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logo upload failed: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _pickAndUploadProfileImage() async {
    if (_profileUploading) return;
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 600, imageQuality: 85);
    if (xFile == null || !mounted) return;
    setState(() => _profileUploading = true);
    try {
      final result = await BackendApi.uploadProfileImage(File(xFile.path));
      final url = result['profile_image'] as String?;
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.initialize();
      if (mounted) {
        setState(() {
          _profileImageUrl = url;
          _profileUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile image updated.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _profileUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile image upload failed: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildProfileHeader(ThemeData theme, bool isDark, String displayName, String displayEmail) {
    return Column(
      children: [
        Stack(
          children: [
            GestureDetector(
              onTap: _coverUploading ? null : _pickAndUploadRestaurantPhoto,
              child: Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.surfaceVariant,
                  image: _coverImageUrl != null && _coverImageUrl!.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(_coverImageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _coverImageUrl == null || _coverImageUrl!.isEmpty
                    ? Icon(Icons.restaurant, size: 48, color: theme.colorScheme.onSurfaceVariant)
                    : null,
              ),
            ),
            if (_coverUploading)
              Positioned.fill(
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black38,
                  ),
                  child: const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                ),
              ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _coverUploading ? null : _pickAndUploadRestaurantPhoto,
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
                    Icons.camera_alt,
                    color: theme.colorScheme.onPrimary,
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          displayName,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          displayEmail,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _buildImageActionCard(
                theme: theme,
                title: 'Restaurant Logo',
                subtitle: 'Shown in admin and brand surfaces',
                imageUrl: _logoImageUrl,
                fallbackIcon: Icons.storefront_rounded,
                loading: _logoUploading,
                onTap: _pickAndUploadRestaurantLogo,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildImageActionCard(
                theme: theme,
                title: 'Owner Profile',
                subtitle: 'Shown on admin user profiles',
                imageUrl: _profileImageUrl,
                fallbackIcon: Icons.person_rounded,
                loading: _profileUploading,
                onTap: _pickAndUploadProfileImage,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImageActionCard({
    required ThemeData theme,
    required String title,
    required String subtitle,
    required String? imageUrl,
    required IconData fallbackIcon,
    required bool loading,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: loading ? null : onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                image: imageUrl != null && imageUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: imageUrl == null || imageUrl.isEmpty
                  ? Icon(fallbackIcon, color: theme.colorScheme.onSurfaceVariant)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            loading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.primary,
                    ),
                  )
                : Icon(Icons.edit_rounded, color: theme.colorScheme.primary),
          ],
        ),
      ),
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
          readOnly: true,
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
    bool readOnly = false,
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
          readOnly: readOnly,
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
          'Address & location (for tracking)',
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
        if (_latitude != null && _longitude != null) ...[
          const SizedBox(height: 8),
          Text(
            'Coordinates: ${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _locationLoading ? null : _useCurrentLocation,
            icon: _locationLoading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.primary),
                  )
                : Icon(Icons.my_location, size: 18, color: theme.colorScheme.primary),
            label: Text(
              _locationLoading
                  ? 'Getting location...'
                  : (_latitude != null
                      ? 'Update location (${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)})'
                      : 'Use my current location'),
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: OutlinedButton.styleFrom(
              backgroundColor: theme.colorScheme.surfaceVariant,
              foregroundColor: theme.colorScheme.primary,
              side: BorderSide(color: theme.colorScheme.outline),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              minimumSize: const Size(double.infinity, 40),
            ),
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
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
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
        onPressed: _saving ? null : _saveProfile,
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
        child: _saving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(
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
