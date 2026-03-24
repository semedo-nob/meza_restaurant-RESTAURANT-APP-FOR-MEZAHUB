// lib/pages/order_history.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';
import '../providers/orders_provider.dart';
import '../models/order.dart' as app_order;
import '../widgets/responsive_layout.dart';

/// Filter for history (separate from OrderStatus so we can have "All").
enum HistoryFilter { all, pending, completed, cancelled }

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<HistoryFilter> _statusFilters = HistoryFilter.values;
  final List<String> _typeFilters = ['All', 'Dine-in', 'Takeaway', 'Delivery'];
  final List<String> _dateRangeFilters = ['All Time', 'Today', 'Yesterday', 'This Week', 'This Month'];

  HistoryFilter _selectedStatus = HistoryFilter.all;
  String _selectedType = 'All';
  String _selectedDateRange = 'All Time';
  DateTimeRange? _customDateRange;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<OrdersProvider>(context, listen: false);
      if (provider.orders.isEmpty && !provider.loading) provider.loadOrders();
    });
  }

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
                  leading: _buildHistoryFilterDot(status, 20),
                  title: Text(
                    _getHistoryFilterText(status),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  trailing: _selectedStatus == status
                      ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                      : null,
                  onTap: () {
                    setState(() => _selectedStatus = status);
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
      _selectedStatus = HistoryFilter.all;
      _selectedType = 'All';
      _selectedDateRange = 'All Time';
      _customDateRange = null;
    });
  }

  List<app_order.Order> _getFilteredOrders() {
    List<app_order.Order> orders = Provider.of<OrdersProvider>(context, listen: true).orders;

    if (_searchController.text.isNotEmpty) {
      final q = _searchController.text.toLowerCase();
      orders = orders.where((order) =>
          order.id.toLowerCase().contains(q) ||
          order.customerName.toLowerCase().contains(q) ||
          order.tableNumber.toLowerCase().contains(q) ||
          order.items.any((item) => item.name.toLowerCase().contains(q))).toList();
    }

    if (_selectedStatus != HistoryFilter.all) {
      switch (_selectedStatus) {
        case HistoryFilter.pending:
          orders = orders.where((o) =>
              o.status == app_order.OrderStatus.pending ||
              o.status == app_order.OrderStatus.accepted ||
              o.status == app_order.OrderStatus.preparing ||
              o.status == app_order.OrderStatus.ready ||
              o.status == app_order.OrderStatus.outForDelivery).toList();
          break;
        case HistoryFilter.completed:
          orders = orders.where((o) => o.status == app_order.OrderStatus.completed).toList();
          break;
        case HistoryFilter.cancelled:
          orders = orders.where((o) => o.status == app_order.OrderStatus.cancelled).toList();
          break;
        case HistoryFilter.all:
          break;
      }
    }

    if (_selectedType != 'All') {
      app_order.OrderType? type;
      switch (_selectedType) {
        case 'Dine-in': type = app_order.OrderType.dineIn; break;
        case 'Takeaway': type = app_order.OrderType.takeaway; break;
        case 'Delivery': type = app_order.OrderType.delivery; break;
        default: break;
      }
      if (type != null) orders = orders.where((o) => o.orderType == type).toList();
    }

    if (_selectedDateRange != 'All Time') {
      final now = DateTime.now();
      switch (_selectedDateRange) {
        case 'Today':
          orders = orders.where((o) =>
              o.orderTime.year == now.year && o.orderTime.month == now.month && o.orderTime.day == now.day).toList();
          break;
        case 'Yesterday':
          final yesterday = now.subtract(const Duration(days: 1));
          orders = orders.where((o) =>
              o.orderTime.year == yesterday.year && o.orderTime.month == yesterday.month && o.orderTime.day == yesterday.day).toList();
          break;
        case 'This Week':
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          orders = orders.where((o) => o.orderTime.isAfter(startOfWeek)).toList();
          break;
        case 'This Month':
          orders = orders.where((o) => o.orderTime.year == now.year && o.orderTime.month == now.month).toList();
          break;
        case 'Custom':
          if (_customDateRange != null) {
            orders = orders.where((o) =>
                o.orderTime.isAfter(_customDateRange!.start) &&
                o.orderTime.isBefore(_customDateRange!.end.add(const Duration(days: 1)))).toList();
          }
          break;
        default:
          break;
      }
    }

    return orders;
  }

  String _orderTypeString(app_order.OrderType t) {
    switch (t) {
      case app_order.OrderType.dineIn: return 'Dine-in';
      case app_order.OrderType.takeaway: return 'Takeaway';
      case app_order.OrderType.delivery: return 'Delivery';
    }
  }

  String _timeAgo(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${d.day}/${d.month}/${d.year}';
  }

  void _showOrderDetails(BuildContext context, app_order.Order order) {
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
              _buildOrderDetailRow('Date', '${_formatDate(order.orderTime)} at ${_formatTime(order.orderTime)}'),
              _buildOrderDetailRow('Type', _orderTypeString(order.orderType)),
              _buildOrderDetailRow('Location', order.tableNumber),
              _buildOrderDetailRow('Status', _orderStatusText(order.status),
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
              if (order.status == app_order.OrderStatus.pending)
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

  Widget _buildOrderDetailRow(String label, String value, {app_order.OrderStatus? status}) {
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

  Widget _buildOrderItemRow(BuildContext context, app_order.OrderItem item) {
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

  String _getHistoryFilterText(HistoryFilter status) {
    switch (status) {
      case HistoryFilter.all: return 'All';
      case HistoryFilter.pending: return 'Pending';
      case HistoryFilter.completed: return 'Completed';
      case HistoryFilter.cancelled: return 'Cancelled';
    }
  }

  String _orderStatusText(app_order.OrderStatus status) {
    switch (status) {
      case app_order.OrderStatus.pending: return 'Pending';
      case app_order.OrderStatus.accepted: return 'Accepted';
      case app_order.OrderStatus.preparing: return 'Preparing';
      case app_order.OrderStatus.ready: return 'Ready';
      case app_order.OrderStatus.outForDelivery: return 'Out for Delivery';
      case app_order.OrderStatus.completed: return 'Completed';
      case app_order.OrderStatus.cancelled: return 'Cancelled';
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
                text: 'Status: ${_getHistoryFilterText(_selectedStatus)}',
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

  Widget _buildOrderCard(BuildContext context, app_order.Order order, bool isLargeScreen) {
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
                    '${order.id} - ${_timeAgo(order.orderTime)}',
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
              order.tableNumber,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: isLargeScreen ? 22 : 18,
              ),
            ),
            SizedBox(height: isLargeScreen ? 8 : 4),
            Text(
              _orderTypeString(order.orderType),
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
                      '${order.items.length} Items',
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

  Widget _buildStatusChip(BuildContext context, app_order.OrderStatus status, bool isLargeScreen) {
    final theme = Theme.of(context);
    Color backgroundColor = Colors.grey.withOpacity(0.2);
    Color textColor = Colors.grey;
    Color dotColor = Colors.grey;
    switch (status) {
      case app_order.OrderStatus.completed:
        backgroundColor = Colors.green.withOpacity(0.2);
        textColor = Colors.green;
        dotColor = Colors.green;
        break;
      case app_order.OrderStatus.cancelled:
        backgroundColor = Colors.red.withOpacity(0.2);
        textColor = Colors.red;
        dotColor = Colors.red;
        break;
      case app_order.OrderStatus.pending:
      case app_order.OrderStatus.accepted:
        backgroundColor = Colors.orange.withOpacity(0.2);
        textColor = Colors.orange;
        dotColor = Colors.orange;
        break;
      case app_order.OrderStatus.preparing:
      case app_order.OrderStatus.ready:
        backgroundColor = Colors.blue.withOpacity(0.2);
        textColor = Colors.blue;
        dotColor = Colors.blue;
        break;
      case app_order.OrderStatus.outForDelivery:
        backgroundColor = Colors.teal.withOpacity(0.2);
        textColor = Colors.teal;
        dotColor = Colors.teal;
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
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          SizedBox(width: isLargeScreen ? 8 : 6),
          Text(
            _orderStatusText(status),
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

  Widget _buildHistoryFilterDot(HistoryFilter status, double size) {
    final Color color;
    switch (status) {
      case HistoryFilter.completed: color = Colors.green; break;
      case HistoryFilter.cancelled: color = Colors.red; break;
      case HistoryFilter.pending: color = Colors.orange; break;
      case HistoryFilter.all: color = Colors.grey; break;
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}