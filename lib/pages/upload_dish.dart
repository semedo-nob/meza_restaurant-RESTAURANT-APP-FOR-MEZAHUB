import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../services/backend_api.dart';

/// One category from backend (id + name) or a static name for creating new.
class _CategoryChoice {
  final int? id;
  final String name;
  _CategoryChoice({this.id, required this.name});
}

class UploadDishScreen extends StatefulWidget {
  const UploadDishScreen({super.key});

  @override
  State<UploadDishScreen> createState() => _UploadDishScreenState();
}

class _UploadDishScreenState extends State<UploadDishScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  _CategoryChoice? _selectedCategory;
  File? _selectedImage;
  bool _isUploading = false;
  bool _isLoading = false;
  String? _loadError;
  int? _restaurantId;
  List<_CategoryChoice> _categories = [];
  String _menuSummary = '';

  /// Enforced to match customer Discover page categories (All, Pizza, Burger, Sushi, Drinks, Desserts) minus All.
  static const List<String> _defaultCategoryNames = [
    'Pizza',
    'Burger',
    'Sushi',
    'Drinks',
    'Desserts',
  ];

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Form is always visible: start with default categories so the dropdown is never empty
    _categories = _defaultCategoryNames.map((name) => _CategoryChoice(id: null, name: name)).toList();
    _selectedCategory = _categories.isNotEmpty ? _categories.first : null;
    WidgetsBinding.instance.addPostFrameCallback((_) { _loadRestaurantAndCategories(); });
  }

  Future<void> _loadRestaurantAndCategories() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final restaurants = await BackendApi.getMyRestaurants();
      if (restaurants.isEmpty) {
        setState(() {
          _loadError = 'No restaurant found. Create one in profile or contact support.';
          _isLoading = false;
        });
        return;
      }
      final first = restaurants.first as Map<String, dynamic>;
      final rid = (first['id'] as num?)?.toInt();
      if (rid == null) {
        setState(() {
          _loadError = 'Invalid restaurant data.';
          _isLoading = false;
        });
        return;
      }
      List<_CategoryChoice> choices = [];
      String summary = 'No dishes yet';
      try {
        final menu = await BackendApi.getRestaurantMenu(rid);
        final cats = menu['categories'] as List<dynamic>? ?? [];
        int totalItems = 0;
        for (final c in cats) {
          final m = Map<String, dynamic>.from(c as Map);
          final id = (m['id'] as num?)?.toInt();
          final name = m['name'] as String? ?? '';
          final items = m['items'] as List<dynamic>? ?? [];
          totalItems += items.length;
          if (id != null && name.isNotEmpty) {
            choices.add(_CategoryChoice(id: id, name: name));
          }
        }
        if (cats.isNotEmpty || totalItems > 0) {
          summary = '${choices.length} categor${choices.length == 1 ? 'y' : 'ies'}, $totalItems dish${totalItems == 1 ? '' : 'es'}';
        }
      } catch (_) {
        // menu might be empty
      }
      if (choices.isEmpty) {
        for (final name in _defaultCategoryNames) {
          choices.add(_CategoryChoice(id: null, name: name));
        }
      }
      if (!mounted) return;
      setState(() {
        _restaurantId = rid;
        _categories = choices;
        _selectedCategory = choices.isNotEmpty ? choices.first : null;
        _menuSummary = summary;
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
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 400,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  Future<void> _takePhotoWithCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 400,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to take photo: $e');
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Choose Image Source',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _takePhotoWithCamera();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleImageDrop(List<File> files) {
    if (files.isNotEmpty) {
      setState(() {
        _selectedImage = files.first;
      });
    }
  }

  Future<void> _uploadDishToCustomerApp() async {
    if (_restaurantId == null) {
      _showErrorSnackBar('No restaurant loaded. Try again.');
      return;
    }
    if (_nameController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter a dish name');
      return;
    }
    final priceText = _priceController.text.trim();
    if (priceText.isEmpty) {
      _showErrorSnackBar('Please enter a price');
      return;
    }
    final price = double.tryParse(priceText);
    if (price == null || price <= 0) {
      _showErrorSnackBar('Please enter a valid price');
      return;
    }
    if (_selectedCategory == null) {
      _showErrorSnackBar('Please select a category');
      return;
    }

    setState(() => _isUploading = true);

    try {
      int categoryId = _selectedCategory!.id ?? -1;
      if (categoryId <= 0) {
        final created = await BackendApi.createMenuCategory(
          _restaurantId!,
          name: _selectedCategory!.name,
        );
        categoryId = (created['id'] as num).toInt();
      }
      final createdItem = await BackendApi.createMenuItem(
        _restaurantId!,
        categoryId: categoryId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        price: price,
        preparationTime: 10,
        available: true,
      );
      if (_selectedImage != null) {
        await BackendApi.uploadMenuItemImage(
          _restaurantId!,
          (createdItem['id'] as num).toInt(),
          _selectedImage!,
        );
      }
      if (mounted) {
        _showSuccessSnackBar(
          _selectedImage != null
              ? 'Dish added to menu! Customers can see it in the app.'
              : 'Dish added to menu (without photo). Customers can see it in the app.',
        );
        _clearForm();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to add dish: ${e.toString().replaceFirst('Exception: ', '')}');
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _clearForm() {
    setState(() {
      _nameController.clear();
      _priceController.clear();
      _descriptionController.clear();
      _selectedCategory = _categories.isNotEmpty ? _categories.first : null;
      _selectedImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final canSubmit = _restaurantId != null && !_isUploading;

    // Consistent form state: restaurant staff always see the same form to add dishes → backend → customers see items and order
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(theme),
            if (_isLoading) const LinearProgressIndicator(),
            if (_loadError != null) _buildBanner(theme),
            Expanded(
              child: _buildContent(theme, isDark),
            ),
            _buildBottomButtons(theme, isDark, canSubmit),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner(ThemeData theme) {
    final isNoRestaurant = _loadError!.toLowerCase().contains('no restaurant');
    return Material(
      color: isNoRestaurant
          ? theme.colorScheme.primaryContainer.withOpacity(0.5)
          : theme.colorScheme.errorContainer.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              isNoRestaurant ? Icons.info_outline : Icons.error_outline,
              size: 22,
              color: theme.colorScheme.onSurface,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_loadError!, style: theme.textTheme.bodyMedium),
                  if (isNoRestaurant)
                    Text(
                      'Set up your restaurant in Profile first.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            TextButton(
              onPressed: () { _loadRestaurantAndCategories(); },
              child: const Text('Retry'),
            ),
            if (isNoRestaurant)
              TextButton(
                onPressed: () => context.push('/profile'),
                child: const Text('Profile'),
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
              onPressed: () => context.pop(),
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: theme.colorScheme.onBackground,
                size: 20,
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
                'Upload New Dish',
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Your menu summary (real data from backend)
          if (_menuSummary.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.restaurant_menu, color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Your menu: $_menuSummary',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          // Photo Upload Section
          _buildPhotoUpload(theme, isDark),
          const SizedBox(height: 24),
          // Food Name
          _buildFoodNameField(theme, isDark),
          const SizedBox(height: 16),
          // Price
          _buildPriceField(theme, isDark),
          const SizedBox(height: 16),
          // Description
          _buildDescriptionField(theme, isDark),
          const SizedBox(height: 16),
          // Category
          _buildCategoryField(theme, isDark),
        ],
      ),
    );
  }

  Widget _buildPhotoUpload(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dish Photo',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.9),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        // Drag and Drop Area
        GestureDetector(
          onTap: _showImageSourceDialog,
          child: DragTarget<File>(
            onAccept: (File file) {
              _handleImageDrop([file]);
            },
            builder: (context, candidateData, rejectedData) {
              return CustomPaint(
                painter: DashedBorderPainter(
                  color: theme.colorScheme.outline.withOpacity(0.3),
                ),
                child: Container(
                  width: double.infinity,
                  height: 160,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _selectedImage != null
                      ? _buildImagePreview(theme)
                      : _buildUploadPlaceholder(theme, isDark),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tap to choose or drag & drop an image',
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDark ? AppColors.darkPlaceholder : AppColors.gray500,
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview(ThemeData theme) {
    return Stack(
      children: [
        // Image
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            _selectedImage!,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        // Change Photo Button
        Positioned(
          bottom: 8,
          right: 8,
          child: GestureDetector(
            onTap: _showImageSourceDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.background.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.edit,
                    size: 16,
                    color: theme.colorScheme.onBackground,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Change',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onBackground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadPlaceholder(ThemeData theme, bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.cloud_upload,
          size: 48,
          color: isDark ? AppColors.darkPlaceholder : AppColors.gray400,
        ),
        const SizedBox(height: 8),
        Text(
          'Click to upload or drag and drop',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark ? AppColors.darkPlaceholder : AppColors.gray500,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'SVG, PNG, JPG (MAX. 800x400px)',
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDark
                ? AppColors.darkPlaceholder.withOpacity(0.8)
                : AppColors.gray400,
          ),
        ),
      ],
    );
  }

  Widget _buildFoodNameField(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Food Name',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.9),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: theme.colorScheme.surfaceVariant,
            hintText: 'e.g. Classic Bruschetta',
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.darkPlaceholder : AppColors.gray500,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.colorScheme.primary),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceField(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Price',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.9),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _priceController,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            filled: true,
            fillColor: theme.colorScheme.surfaceVariant,
            hintText: '0.00',
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.darkPlaceholder : AppColors.gray500,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 16, right: 8),
              child: Text(
                '\$',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.darkPlaceholder : AppColors.gray500,
                ),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.colorScheme.primary),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionField(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.9),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _descriptionController,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
          maxLines: 4,
          decoration: InputDecoration(
            filled: true,
            fillColor: theme.colorScheme.surfaceVariant,
            hintText: 'Describe the dish, ingredients, and any special notes...',
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.darkPlaceholder : AppColors.gray500,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.colorScheme.primary),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryField(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.9),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonFormField<_CategoryChoice>(
            value: _selectedCategory,
            onChanged: (_CategoryChoice? newValue) {
              setState(() {
                _selectedCategory = newValue;
              });
            },
            dropdownColor: theme.colorScheme.surfaceVariant,
            icon: Icon(
              Icons.expand_more,
              color: isDark ? AppColors.darkPlaceholder : AppColors.gray500,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.transparent,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.colorScheme.primary),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
            items: _categories.map((_CategoryChoice c) {
              return DropdownMenuItem<_CategoryChoice>(
                value: c,
                child: Text(c.name),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButtons(ThemeData theme, bool isDark, bool canSubmit) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.background,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.1),
          ),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isUploading ? null : _clearForm,
              style: OutlinedButton.styleFrom(
                backgroundColor: theme.colorScheme.surfaceVariant,
                foregroundColor: theme.colorScheme.onSurfaceVariant,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                side: BorderSide.none,
              ),
              child: Text(
                'Clear',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: canSubmit ? _uploadDishToCustomerApp : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isUploading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
                  : Text(
                'Upload to Menu',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  DashedBorderPainter({
    this.color = Colors.white,
    this.strokeWidth = 2.0,
    this.dashWidth = 5.0,
    this.dashSpace = 3.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(12),
      ));

    final PathMetric pathMetric = path.computeMetrics().first;
    double start = 0;
    while (start < pathMetric.length) {
      double end = start + dashWidth;
      canvas.drawPath(
        pathMetric.extractPath(start, end),
        paint,
      );
      start += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
