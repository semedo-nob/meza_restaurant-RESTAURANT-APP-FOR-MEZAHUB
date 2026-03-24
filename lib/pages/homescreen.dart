// lib/pages/homescreen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:meza_restaurant/pages/profile.dart';
import 'package:meza_restaurant/pages/settings.dart';
import 'package:meza_restaurant/pages/upload_dish.dart';
import 'package:provider/provider.dart';
import '../widgets/floating_bottom_navbar.dart';
import '../widgets/app_drawer.dart';
import '../widgets/responsive_layout.dart';
import '../theme/app_colors.dart';
import '../providers/theme_provider.dart';
import '../providers/orders_provider.dart';
import '../models/order.dart';
import '../services/backend_api.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const OrdersPage(),
    const UploadDishScreen(),
    const ProfileScreen(),
    const SettingsScreen(),
  ];

  final List<String> _titles = ['Orders', 'Upload Dish', 'Profile', 'Settings'];

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return ResponsiveLayout(
      builder: (context, constraints) {
        final bool isLargeScreen = constraints.maxWidth > 600;
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return Scaffold(
          backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
          appBar: AppBar(
            backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
            elevation: 0,
            title: Text(
              _titles[_currentIndex],
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            leading: Builder(
              builder: (context) => IconButton(
                icon: Icon(
                  Icons.menu,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  size: isLargeScreen ? 28 : 24,
                ),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            actions: _currentIndex == 0
                ? [
              Stack(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.notifications_outlined,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      size: isLargeScreen ? 28 : 24,
                    ),
                    onPressed: () {
                      // Navigate to notifications using GoRouter
                      // context.go('/notifications');
                    },
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: isLargeScreen ? 12 : 10,
                      height: isLargeScreen ? 12 : 10,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ]
                : null,
          ),
          drawer: const AppDrawer(),
          body: ResponsivePadding(
            mobilePadding: 16.0,
            tabletPadding: 24.0,
            desktopPadding: 32.0,
            child: _pages[_currentIndex],
          ),
          bottomNavigationBar: FloatingBottomNavbar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
          ),
        );
      },
    );
  }
}

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _ordersRefreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrdersProvider>(context, listen: false).loadOrders();
    });
    // Refresh orders every 15s so new customer orders appear quickly without manual pull
    _ordersRefreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) {
        Provider.of<OrdersProvider>(context, listen: false).loadOrders();
      }
    });
  }

  @override
  void dispose() {
    _ordersRefreshTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _updateOrderStatus(String orderId, OrderStatus newStatus) async {
    final provider = Provider.of<OrdersProvider>(context, listen: false);
    final ok = await provider.updateStatus(orderId, newStatus);
    if (ok && mounted) _navigateToTabForStatus(newStatus);
  }

  void _navigateToTabForStatus(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        _tabController.animateTo(0);
        break;
      case OrderStatus.accepted:
      case OrderStatus.preparing:
        _tabController.animateTo(1);
        break;
      case OrderStatus.ready:
        _tabController.animateTo(2);
        break;
      case OrderStatus.outForDelivery:
        _tabController.animateTo(3);
        break;
      case OrderStatus.completed:
        _tabController.animateTo(4);
        break;
      case OrderStatus.cancelled:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  void _assignToDelivery(String orderId) async {
    try {
      final riders = await BackendApi.getRiders();
      if (!mounted) return;
      if (riders.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No riders available')),
        );
        return;
      }
      int? selectedRiderId;
      final names = riders.map((r) {
        final m = Map<String, dynamic>.from(r as Map);
        return {'id': m['id'] as int, 'name': m['name']?.toString() ?? 'Rider #${m['id']}'};
      }).toList();
      showDialog(
        context: context,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setDialogState) {
              return AlertDialog(
                title: const Text('Assign to Delivery'),
                content: DropdownButtonFormField<int>(
                  value: selectedRiderId,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Delivery Person',
                  ),
                  items: names.map((e) => DropdownMenuItem(value: e['id'] as int, child: Text(e['name'] as String))).toList(),
                  onChanged: (value) => setDialogState(() => selectedRiderId = value),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                  ElevatedButton(
                    onPressed: selectedRiderId == null ? null : () async {
                      Navigator.pop(ctx);
                      final ok = await Provider.of<OrdersProvider>(context, listen: false).assignRider(orderId, selectedRiderId!);
                      if (mounted) {
                        if (ok) _tabController.animateTo(3);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(ok ? 'Rider assigned' : 'Failed to assign rider')),
                        );
                      }
                    },
                    child: const Text('Assign'),
                  ),
                ],
              );
            },
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load riders: $e')),
        );
      }
    }
  }

  void _completeDeliveryOrder(String orderId) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Complete Delivery'),
          content: const Text('Mark this delivery as completed and delivered to customer?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _updateOrderStatus(orderId, OrderStatus.completed);
                if (mounted) _tabController.animateTo(4);
              },
              child: const Text('Mark Delivered'),
            ),
          ],
        );
      },
    );
  }

  void _completeRegularOrder(String orderId) {
    _updateOrderStatus(orderId, OrderStatus.completed);
    _tabController.animateTo(4);
  }

  List<Order> _getOrdersByStatus(OrderStatus status) {
    return Provider.of<OrdersProvider>(context, listen: true).getByStatus(status);
  }

  List<Order> _getPreparingOrders() {
    return Provider.of<OrdersProvider>(context, listen: true).preparingOrders;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrdersProvider>(
      builder: (context, ordersProvider, _) {
        if (ordersProvider.loading && ordersProvider.orders.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (ordersProvider.error != null && ordersProvider.orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(ordersProvider.error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () { ordersProvider.loadOrders(); },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        return ResponsiveLayout(
          builder: (context, constraints) {
            final theme = Theme.of(context);
            final isDark = theme.brightness == Brightness.dark;

            return Column(
              children: [
                // Tab Bar
                Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                indicatorColor: AppColors.primary,
                labelStyle: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                isScrollable: true,
                tabs: const [
                  Tab(text: 'Pending'),
                  Tab(text: 'Preparing'),
                  Tab(text: 'Ready'),
                  Tab(text: 'Delivery'),
                  Tab(text: 'Completed'),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOrderList(context, _getOrdersByStatus(OrderStatus.pending), 'Pending Orders'),
                  _buildOrderList(context, _getPreparingOrders(), 'Preparing Orders'),
                  _buildOrderList(context, _getOrdersByStatus(OrderStatus.ready), 'Ready Orders'),
                  _buildOrderList(context, _getOrdersByStatus(OrderStatus.outForDelivery), 'Out for Delivery'),
                  _buildOrderList(context, _getOrdersByStatus(OrderStatus.completed), 'Completed Orders'),
                ],
              ),
            ),
          ],
        );
      },
    );
      },
    );
  }

  Widget _buildOrderList(BuildContext context, List<Order> orders, String emptyMessage) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Future<void> onRefresh() async {
      await Provider.of<OrdersProvider>(context, listen: false).loadOrders();
    }

    if (orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 64,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No $emptyMessage',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pull down to refresh • New orders will appear here',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          return _buildOrderCard(context, orders[index]);
        },
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Order order) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: isDark ? AppColors.cardDark : AppColors.cardLight,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Header - FIXED: Made responsive
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.id,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        order.customerName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusChip(order.status),
              ],
            ),

            const SizedBox(height: 12),

            // Order Details
            Row(
              children: [
                Icon(
                  _getOrderTypeIcon(order.orderType),
                  size: 16,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.tableNumber,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            // Time and Delivery Info - FIXED: Made responsive
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Text(
                  '${_formatTime(order.orderTime)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                if (order.estimatedTime > 0) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer,
                        size: 14,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${order.estimatedTime}min',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ],
                if (order.deliveryPerson != null) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.person,
                        size: 14,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          order.deliveryPerson!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),

            const SizedBox(height: 12),

            // Order Items
            ...order.items.take(2).map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                '${item.quantity}x ${item.name}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            )).toList(),

            if (order.items.length > 2)
              Text(
                '+ ${order.items.length - 2} more items',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),

            const SizedBox(height: 12),

            // Order Footer - FIXED: Made buttons responsive
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${order.totalAmount.toStringAsFixed(2)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Action Buttons based on status - Made responsive
                _buildActionButtons(order),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(OrderStatus status) {
    final Color backgroundColor;
    final Color textColor;
    final String statusText;

    switch (status) {
      case OrderStatus.pending:
        backgroundColor = Colors.orange.withOpacity(0.2);
        textColor = Colors.orange;
        statusText = 'Pending';
        break;
      case OrderStatus.accepted:
        backgroundColor = Colors.blue.withOpacity(0.2);
        textColor = Colors.blue;
        statusText = 'Accepted';
        break;
      case OrderStatus.preparing:
        backgroundColor = Colors.purple.withOpacity(0.2);
        textColor = Colors.purple;
        statusText = 'Preparing';
        break;
      case OrderStatus.ready:
        backgroundColor = Colors.green.withOpacity(0.2);
        textColor = Colors.green;
        statusText = 'Ready';
        break;
      case OrderStatus.outForDelivery:
        backgroundColor = Colors.teal.withOpacity(0.2);
        textColor = Colors.teal;
        statusText = 'Out for Delivery';
        break;
      case OrderStatus.completed:
        backgroundColor = Colors.grey.withOpacity(0.2);
        textColor = Colors.grey;
        statusText = 'Completed';
        break;
      case OrderStatus.cancelled:
        backgroundColor = Colors.red.withOpacity(0.2);
        textColor = Colors.red;
        statusText = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildActionButtons(Order order) {
    switch (order.status) {
      case OrderStatus.pending:
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton(
              onPressed: () => _updateOrderStatus(order.id, OrderStatus.accepted),
              child: const Text('Accept'),
            ),
            OutlinedButton(
              onPressed: () => _updateOrderStatus(order.id, OrderStatus.cancelled),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
              child: const Text('Reject'),
            ),
          ],
        );

      case OrderStatus.accepted:
        return OutlinedButton(
          onPressed: () => _updateOrderStatus(order.id, OrderStatus.preparing),
          child: const Text('Start Preparing'),
        );

      case OrderStatus.preparing:
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (order.orderType == OrderType.delivery)
              OutlinedButton(
                onPressed: () => _assignToDelivery(order.id),
                child: const Text('Assign Delivery'),
              ),
            ElevatedButton(
              onPressed: () => _updateOrderStatus(order.id, OrderStatus.ready),
              child: const Text('Mark Ready'),
            ),
          ],
        );

      case OrderStatus.ready:
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (order.orderType == OrderType.delivery)
              OutlinedButton(
                onPressed: () => _assignToDelivery(order.id),
                child: const Text('Assign Delivery'),
              ),
            ElevatedButton(
              onPressed: () {
                if (order.orderType == OrderType.delivery) {
                  _assignToDelivery(order.id);
                } else {
                  _completeRegularOrder(order.id);
                }
              },
              child: Text(
                order.orderType == OrderType.delivery ? 'Assign Delivery' : 'Complete Order',
              ),
            ),
          ],
        );

      case OrderStatus.outForDelivery:
        return ElevatedButton(
          onPressed: () => _completeDeliveryOrder(order.id),
          child: const Text('Mark Delivered'),
        );

      case OrderStatus.completed:
        return Text(
          'Completed',
          style: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        );
      case OrderStatus.cancelled:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  IconData _getOrderTypeIcon(OrderType type) {
    switch (type) {
      case OrderType.dineIn:
        return Icons.table_restaurant;
      case OrderType.takeaway:
        return Icons.takeout_dining;
      case OrderType.delivery:
        return Icons.delivery_dining;
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}