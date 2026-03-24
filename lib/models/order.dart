/// Unified order model for restaurant app – maps backend API response.
/// Backend status: pending, confirmed, preparing, ready, assigned, on_the_way, delivered, cancelled.
enum OrderStatus {
  pending,
  accepted,   // confirmed
  preparing,
  ready,
  outForDelivery, // assigned, on_the_way
  completed,  // delivered
  cancelled,
}

enum OrderType {
  dineIn,
  takeaway,
  delivery,
}

class OrderItem {
  final String name;
  final int quantity;
  final double price;
  final int? menuItemId;

  OrderItem({
    required this.name,
    required this.quantity,
    required this.price,
    this.menuItemId,
  });
}

class Order {
  final String id;
  final String customerName;
  final String tableNumber; // delivery_address or "Store Pickup" / table
  final OrderType orderType;
  OrderStatus status;
  final List<OrderItem> items;
  final double totalAmount;
  final DateTime orderTime;
  final int estimatedTime;
  bool assignedToDelivery;
  String? deliveryPerson;
  final int? restaurantId;
  final String? contactPhone;

  Order({
    required this.id,
    required this.customerName,
    required this.tableNumber,
    required this.orderType,
    required this.status,
    required this.items,
    required this.totalAmount,
    required this.orderTime,
    required this.estimatedTime,
    this.assignedToDelivery = false,
    this.deliveryPerson,
    this.restaurantId,
    this.contactPhone,
  });

  static OrderStatus _statusFromString(String? s) {
    if (s == null || s.isEmpty) return OrderStatus.pending;
    final n = s.toLowerCase().replaceAll(' ', '_');
    switch (n) {
      case 'confirmed':
        return OrderStatus.accepted;
      case 'preparing':
        return OrderStatus.preparing;
      case 'ready':
        return OrderStatus.ready;
      case 'assigned':
      case 'on_the_way':
        return OrderStatus.outForDelivery;
      case 'delivered':
        return OrderStatus.completed;
      case 'cancelled':
      case 'canceled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }

  static OrderType _orderTypeFromAddress(String? address) {
    if (address == null || address.isEmpty) return OrderType.dineIn;
    final a = address.toLowerCase();
    if (a.contains('store pickup') || a.contains('pickup')) return OrderType.takeaway;
    if (a.contains('store') && !a.contains('street')) return OrderType.takeaway;
    return OrderType.delivery;
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'] as List<dynamic>? ?? [];
    final items = itemsRaw.map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      final name = m['name'] as String? ?? 'Item #${m['menu_item_id'] ?? ''}';
      final qty = (m['quantity'] as num?)?.toInt() ?? 1;
      final unitPrice = (m['unit_price'] as num?)?.toDouble();
      final subtotal = (m['subtotal'] as num?)?.toDouble();
      final price = unitPrice ?? (subtotal != null && qty > 0 ? subtotal / qty : 0.0);
      return OrderItem(
        name: name,
        quantity: qty,
        price: price,
        menuItemId: (m['menu_item_id'] as num?)?.toInt(),
      );
    }).toList();

    final statusStr = json['status'] as String? ?? 'pending';
    final status = _statusFromString(statusStr);
    final deliveryAddress = json['delivery_address'] as String? ?? '';
    final orderType = _orderTypeFromAddress(deliveryAddress);
    final contactName = json['contact_name'] as String? ?? '';
    final customerName = contactName.isNotEmpty ? contactName : 'Customer #${json['customer_id'] ?? ''}';

    return Order(
      id: (json['id'] as num?)?.toInt().toString() ?? json['id']?.toString() ?? '',
      customerName: customerName,
      tableNumber: deliveryAddress.isNotEmpty ? deliveryAddress : 'Store Pickup',
      orderType: orderType,
      status: status,
      items: items,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
      orderTime: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      estimatedTime: 0,
      assignedToDelivery: status == OrderStatus.outForDelivery || statusStr == 'assigned' || statusStr == 'on_the_way',
      deliveryPerson: null,
      restaurantId: (json['restaurant_id'] as num?)?.toInt(),
      contactPhone: json['contact_phone'] as String?,
    );
  }

  String get statusString {
    switch (status) {
      case OrderStatus.pending:
        return 'pending';
      case OrderStatus.accepted:
        return 'confirmed';
      case OrderStatus.preparing:
        return 'preparing';
      case OrderStatus.ready:
        return 'ready';
      case OrderStatus.outForDelivery:
        return 'on_the_way';
      case OrderStatus.completed:
        return 'delivered';
      case OrderStatus.cancelled:
        return 'cancelled';
    }
  }
}
