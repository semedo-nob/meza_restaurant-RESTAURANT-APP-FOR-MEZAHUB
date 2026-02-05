// lib/pages/order_history.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';
import '../widgets/responsive_layout.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<OrderStatus> _statusFilters = OrderStatus.values;
  final List<String> _typeFilters = ['All', 'Dine-in', 'Takeaway', 'Delivery'];
  final List<String> _dateRangeFilters = ['All Time', 'Today', 'Yesterday', 'This Week', 'This Month'];

  OrderStatus _selectedStatus = OrderStatus.all;
  String _selectedType = 'All';
  String _selectedDateRange = 'All Time';
  DateTimeRange? _customDateRange;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showStatusFilter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Filter by Status',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              ..._statusFilters.map((status) {
                return ListTile(
                  leading: _buildStatusDot(status, 20),
                  title: Text(
                    _getStatusText(status),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  trailing: _selectedStatus == status
                      ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedStatus = status;
                    });
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  void _showTypeFilter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Filter by Type',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              ..._typeFilters.map((type) {
                return ListTile(
                  title: Text(
                    type,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  trailing: _selectedType == type
                      ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedType = type;
                    });
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showDateRangePicker(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      currentDate: DateTime.now(),
      saveText: 'Apply',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).brightness == Brightness.dark
              ? AppTheme.darkTheme
              : AppTheme.lightTheme,
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _selectedDateRange = 'Custom';
      });
    }
  }

  void _showDateRangeFilter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Filter by Date Range',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              ..._dateRangeFilters.map((range) {
                return ListTile(
                  title: Text(
                    range,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  trailing: _selectedDateRange == range
                      ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                      : null,
                  onTap: () {
                    if (range == 'Custom') {
                      Navigator.pop(context);
                      _showDateRangePicker(context);
                    } else {
                      setState(() {
                        _selectedDateRange = range;
                        _customDateRange = null;
                      });
                      Navigator.pop(context);
                    }
                  },
                );
              }).toList(),
              ListTile(
                title: Text(
                  'Custom Range',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                trailing: _selectedDateRange == 'Custom'
                    ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  _showDateRangePicker(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _clearAllFilters() {
    setState(() {
      _searchController.clear();
      _selectedStatus = OrderStatus.all;
      _selectedType = 'All';
      _selectedDateRange = 'All Time';
      _customDateRange = null;
    });
  }

  List<Order> _getFilteredOrders() {
    List<Order> orders = [
      Order(
        id: '#OD-12457',
        timeAgo: '15 minutes ago',
        status: OrderStatus.completed,
        location: 'Table 5',
        itemCount: 2,
        totalAmount: 45.50,
        orderType: 'Dine-in',
        orderDate: DateTime.now().subtract(const Duration(minutes: 15)),
        items: [
          OrderItem(name: 'Margherita Pizza', quantity: 1, price: 18.50),
          OrderItem(name: 'Caesar Salad', quantity: 1, price: 12.00),
          OrderItem(name: 'Coke', quantity: 2, price: 7.50),
        ],
      ),
      Order(
        id: '#OD-12456',
        timeAgo: '1 hour ago',
        status: OrderStatus.completed,
        location: 'Takeaway',
        itemCount: 4,
        totalAmount: 82.00,
        orderType: 'Takeaway',
        orderDate: DateTime.now().subtract(const Duration(hours: 1)),
        items: [
          OrderItem(name: 'Pepperoni Pizza', quantity: 1, price: 20.00),
          OrderItem(name: 'Garlic Bread', quantity: 2, price: 16.00),
          OrderItem(name: 'Pasta Carbonara', quantity: 1, price: 16.00),
          OrderItem(name: 'Tiramisu', quantity: 1, price: 8.00),
        ],
      ),
      Order(
        id: '#OD-12455',
        timeAgo: '2 hours ago',
        status: OrderStatus.canceled,
        location: 'Table 2',
        itemCount: 3,
        totalAmount: 61.25,
        orderType: 'Dine-in',
        orderDate: DateTime.now().subtract(const Duration(hours: 2)),
        items: [
          OrderItem(name: 'BBQ Chicken Pizza', quantity: 1, price: 22.00),
          OrderItem(name: 'Onion Rings', quantity: 2, price: 14.00),
          OrderItem(name: 'Chocolate Cake', quantity: 1, price: 8.25),
        ],
      ),
      Order(
        id: '#OD-12454',
        timeAgo: 'Yesterday',
        status: OrderStatus.completed,
        location: 'Delivery',
        itemCount: 5,
        totalAmount: 112.70,
        orderType: 'Delivery',
        orderDate: DateTime.now().subtract(const Duration(days: 1)),
        items: [
          OrderItem(name: 'Family Pizza', quantity: 1, price: 35.00),
          OrderItem(name: 'Chicken Wings', quantity: 2, price: 24.00),
          OrderItem(name: 'Greek Salad', quantity: 1, price: 14.00),
          OrderItem(name: 'Brownie', quantity: 2, price: 16.00),
          OrderItem(name: 'Drinks', quantity: 4, price: 23.70),
        ],
      ),
      Order(
        id: '#OD-12453',
        timeAgo: '2 days ago',
        status: OrderStatus.pending,
        location: 'Table 8',
        itemCount: 2,
        totalAmount: 34.50,
        orderType: 'Dine-in',
        orderDate: DateTime.now().subtract(const Duration(days: 2)),
        items: [
          OrderItem(name: 'Veggie Pizza', quantity: 1, price: 16.50),
          OrderItem(name: 'Fries', quantity: 1, price: 6.00),
          OrderItem(name: 'Lemonade', quantity: 2, price: 12.00),
        ],
      ),
    ];

    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      orders = orders.where((order) =>
      order.id.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          order.location.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          order.items.any((item) => item.name.toLowerCase().contains(_searchController.text.toLowerCase()))
      ).toList();
    }

    // Apply status filter
    if (_selectedStatus != OrderStatus.all) {
      orders = orders.where((order) => order.status == _selectedStatus).toList();
    }

    // Apply type filter
    if (_selectedType != 'All') {
      orders = orders.where((order) => order.orderType == _selectedType).toList();
    }

    // Apply date range filter
    if (_selectedDateRange != 'All Time') {
      final now = DateTime.now();
      switch (_selectedDateRange) {
        case 'Today':
          orders = orders.where((order) =>
          order.orderDate.year == now.year &&
              order.orderDate.month == now.month &&
              order.orderDate.day == now.day).toList();
          break;
        case 'Yesterday':
          final yesterday = now.subtract(const Duration(days: 1));
          orders = orders.where((order) =>
          order.orderDate.year == yesterday.year &&
              order.orderDate.month == yesterday.month &&
              order.orderDate.day == yesterday.day).toList();
          break;
        case 'This Week':
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          orders = orders.where((order) => order.orderDate.isAfter(startOfWeek)).toList();
          break;
        case 'This Month':
          orders = orders.where((order) =>
          order.orderDate.year == now.year &&
              order.orderDate.month == now.month).toList();
          break;
        case 'Custom':
          if (_customDateRange != null) {
            orders = orders.where((order) =>
            order.orderDate.isAfter(_customDateRange!.start) &&
                order.orderDate.isBefore(_customDateRange!.end.add(const Duration(days: 1)))).toList();
          }
          break;
      }
    }

    return orders;
  }

  void _showOrderDetails(BuildContext context, Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order Details',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Order Info
              _buildOrderDetailRow('Order ID', order.id),
              _buildOrderDetailRow('Date', '${_formatDate(order.orderDate)} at ${_formatTime(order.orderDate)}'),
              _buildOrderDetailRow('Type', order.orderType),
              _buildOrderDetailRow('Location', order.location),
              _buildOrderDetailRow('Status', _getStatusText(order.status),
                  status: order.status),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              // Order Items
              Text(
                'Order Items',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),

              ...order.items.map((item) =>
                  _buildOrderItemRow(context, item)
              ).toList(),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              // Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Amount',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '\$${order.totalAmount.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Actions
              if (order.status == OrderStatus.pending)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          // Handle cancel order
                          setState(() {
                            // Update order status to canceled
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Cancel Order'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Handle mark as completed
                          setState(() {
                            // Update order status to completed
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Mark Completed'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrderDetailRow(String label, String value, {OrderStatus? status}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          if (status != null)
            _buildStatusChip(context, status, false)
          else
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
        ],
      ),
    );
  }

  Widget _buildOrderItemRow(BuildContext context, OrderItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Qty: ${item.quantity}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '\$${(item.price * item.quantity).toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.all:
        return 'All';
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.canceled:
        return 'Canceled';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: ResponsiveLayout(
          builder: (context, constraints) {
            final bool isLargeScreen = constraints.maxWidth > 600;

            return Column(
              children: [
                // Top App Bar
                _buildAppBar(context, isLargeScreen),
                // Search Bar
                _buildSearchBar(context, isLargeScreen),
                // Filter Chips
                _buildFilterChips(context, isLargeScreen),
                // Order List
                Expanded(
                  child: _buildOrderList(context, isLargeScreen),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isLargeScreen) {
    final theme = Theme.of(context);

    return ResponsivePadding(
      mobilePadding: 16.0,
      tabletPadding: 24.0,
      desktopPadding: 32.0,
      child: Container(
        color: theme.colorScheme.background,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: isLargeScreen ? 20.0 : 16.0),
          child: Row(
            children: [
              IconButton(
                onPressed: () => context.push('/home'),
                icon: Icon(
                  Icons.arrow_back,
                  color: theme.colorScheme.onBackground,
                  size: isLargeScreen ? 32 : 28,
                ),
              ),
              Expanded(
                child: Text(
                  'Order History',
                  textAlign: TextAlign.center,
                  style: isLargeScreen
                      ? theme.textTheme.headlineLarge!.copyWith(
                    fontWeight: FontWeight.w700,
                  )
                      : theme.textTheme.headlineMedium!.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: _clearAllFilters,
                icon: Icon(
                  Icons.filter_alt_off,
                  color: theme.colorScheme.primary,
                  size: isLargeScreen ? 28 : 24,
                ),
                tooltip: 'Clear Filters',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, bool isLargeScreen) {
    final theme = Theme.of(context);

    return ResponsivePadding(
      mobilePadding: 16.0,
      tabletPadding: 24.0,
      desktopPadding: 32.0,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: isLargeScreen ? 16.0 : 12.0),
        child: Container(
          height: isLargeScreen ? 56 : 48,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(isLargeScreen ? 16 : 12),
            border: Border.all(
              color: theme.colorScheme.outline,
            ),
          ),
          child: Row(
            children: [
              Padding(
                padding: EdgeInsets.only(left: isLargeScreen ? 20.0 : 16.0),
                child: Icon(
                  Icons.search,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: isLargeScreen ? 24 : 20,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() {}),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    hintText: 'Search by Order ID, Table, Items...',
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    contentPadding: EdgeInsets.only(
                      left: isLargeScreen ? 16 : 12,
                      right: isLargeScreen ? 20 : 16,
                    ),
                  ),
                ),
              ),
              if (_searchController.text.isNotEmpty)
                IconButton(
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                    });
                  },
                  icon: Icon(
                    Icons.clear,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: isLargeScreen ? 20 : 18,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context, bool isLargeScreen) {
    return ResponsivePadding(
      mobilePadding: 16.0,
      tabletPadding: 24.0,
      desktopPadding: 32.0,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: isLargeScreen ? 12.0 : 8.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip(
                context,
                icon: Icons.calendar_today,
                text: _selectedDateRange == 'Custom' && _customDateRange != null
                    ? '${_formatDate(_customDateRange!.start)} - ${_formatDate(_customDateRange!.end)}'
                    : _selectedDateRange,
                hasDropdown: true,
                isLargeScreen: isLargeScreen,
                onTap: () => _showDateRangeFilter(context),
              ),
              SizedBox(width: isLargeScreen ? 16 : 12),
              _buildFilterChip(
                context,
                icon: Icons.filter_list,
                text: 'Status: ${_getStatusText(_selectedStatus)}',
                hasDropdown: true,
                isLargeScreen: isLargeScreen,
                onTap: () => _showStatusFilter(context),
              ),
              SizedBox(width: isLargeScreen ? 16 : 12),
              _buildFilterChip(
                context,
                text: 'Type: $_selectedType',
                hasDropdown: true,
                isLargeScreen: isLargeScreen,
                onTap: () => _showTypeFilter(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(
      BuildContext context, {
        IconData? icon,
        required String text,
        required bool hasDropdown,
        required bool isLargeScreen,
        VoidCallback? onTap,
      }) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: isLargeScreen ? 40 : 32,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(isLargeScreen ? 12 : 8),
          border: Border.all(
            color: theme.colorScheme.outline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Padding(
                padding: EdgeInsets.only(left: isLargeScreen ? 16.0 : 12.0),
                child: Icon(
                  icon,
                  color: theme.colorScheme.onSurface,
                  size: isLargeScreen ? 20 : 18,
                ),
              ),
              SizedBox(width: isLargeScreen ? 8 : 4),
            ],
            Padding(
              padding: EdgeInsets.only(
                left: icon == null ? (isLargeScreen ? 16.0 : 12.0) : 0,
                right: isLargeScreen ? 8 : 4,
              ),
              child: Text(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: isLargeScreen ? 16 : 14,
                ),
              ),
            ),
            if (hasDropdown) ...[
              Icon(
                Icons.arrow_drop_down,
                color: theme.colorScheme.onSurface,
                size: isLargeScreen ? 24 : 18,
              ),
              SizedBox(width: isLargeScreen ? 12 : 8),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList(BuildContext context, bool isLargeScreen) {
    final orders = _getFilteredOrders();

    return ResponsiveLayout(
      builder: (context, constraints) {
        final double horizontalPadding = isLargeScreen ? constraints.maxWidth * 0.1 : 16.0;

        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  'No orders found',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Try adjusting your filters or search terms',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(bottom: horizontalPadding * 0.5),
                child: _buildOrderCard(context, orders[index], isLargeScreen),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildOrderCard(BuildContext context, Order order, bool isLargeScreen) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => _showOrderDetails(context, order),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(isLargeScreen ? 20 : 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(isLargeScreen ? 16 : 12),
          border: Border.all(
            color: theme.colorScheme.outline,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${order.id} - ${order.timeAgo}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildStatusChip(context, order.status, isLargeScreen),
              ],
            ),
            SizedBox(height: isLargeScreen ? 12 : 8),
            Text(
              order.location,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: isLargeScreen ? 22 : 18,
              ),
            ),
            SizedBox(height: isLargeScreen ? 8 : 4),
            Text(
              order.orderType,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: isLargeScreen ? 12 : 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${order.itemCount} Items',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '\$${order.totalAmount.toStringAsFixed(2)}',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: isLargeScreen ? 18 : 16,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  width: isLargeScreen ? 120 : 100,
                  height: isLargeScreen ? 48 : 40,
                  child: ElevatedButton(
                    onPressed: () => _showOrderDetails(context, order),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(isLargeScreen ? 12 : 8),
                      ),
                    ),
                    child: Text(
                      'View Details',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontSize: isLargeScreen ? 16 : 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, OrderStatus status, bool isLargeScreen) {
    final theme = Theme.of(context);
    final Color backgroundColor;
    final Color textColor;
    final Color dotColor;

    switch (status) {
      case OrderStatus.completed:
        backgroundColor = Colors.green.withOpacity(0.2);
        textColor = Colors.green;
        dotColor = Colors.green;
        break;
      case OrderStatus.canceled:
        backgroundColor = Colors.red.withOpacity(0.2);
        textColor = Colors.red;
        dotColor = Colors.red;
        break;
      case OrderStatus.pending:
        backgroundColor = Colors.orange.withOpacity(0.2);
        textColor = Colors.orange;
        dotColor = Colors.orange;
        break;
      case OrderStatus.all:
        backgroundColor = Colors.grey.withOpacity(0.2);
        textColor = Colors.grey;
        dotColor = Colors.grey;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLargeScreen ? 12 : 8,
        vertical: isLargeScreen ? 6 : 4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(isLargeScreen ? 16 : 12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isLargeScreen ? 10 : 8,
            height: isLargeScreen ? 10 : 8,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: isLargeScreen ? 8 : 6),
          Text(
            _getStatusText(status),
            style: theme.textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w500,
              fontSize: isLargeScreen ? 14 : 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDot(OrderStatus status, double size) {
    final Color color;
    switch (status) {
      case OrderStatus.completed:
        color = Colors.green;
        break;
      case OrderStatus.canceled:
        color = Colors.red;
        break;
      case OrderStatus.pending:
        color = Colors.orange;
        break;
      case OrderStatus.all:
        color = Colors.grey;
        break;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class Order {
  final String id;
  final String timeAgo;
  final OrderStatus status;
  final String location;
  final int itemCount;
  final double totalAmount;
  final String orderType;
  final DateTime orderDate;
  final List<OrderItem> items;

  Order({
    required this.id,
    required this.timeAgo,
    required this.status,
    required this.location,
    required this.itemCount,
    required this.totalAmount,
    required this.orderType,
    required this.orderDate,
    required this.items,
  });
}

class OrderItem {
  final String name;
  final int quantity;
  final double price;

  OrderItem({
    required this.name,
    required this.quantity,
    required this.price,
  });
}

enum OrderStatus {
  all,
  pending,
  completed,
  canceled,
}