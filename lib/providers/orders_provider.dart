import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../services/backend_api.dart';

class OrdersProvider with ChangeNotifier {
  List<Order> _orders = [];
  bool _loading = false;
  String? _error;

  List<Order> get orders => List.unmodifiable(_orders);
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadOrders() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final list = await BackendApi.getOrders(perPage: 100);
      _orders = list
          .map((e) => Order.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      _error = null;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _orders = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> updateStatus(String orderId, OrderStatus newStatus) async {
    final statusStr = _statusToBackend(newStatus);
    try {
      await BackendApi.updateOrderStatus(int.parse(orderId), statusStr);
      final idx = _orders.indexWhere((o) => o.id == orderId);
      if (idx >= 0) _orders[idx].status = newStatus;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> assignRider(String orderId, int riderId) async {
    try {
      await BackendApi.assignRider(int.parse(orderId), riderId);
      final idx = _orders.indexWhere((o) => o.id == orderId);
      if (idx >= 0) {
        _orders[idx].status = OrderStatus.outForDelivery;
        _orders[idx].assignedToDelivery = true;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst(RegExp(r'^Exception:?\s*'), '');
      notifyListeners();
      return false;
    }
  }

  /// Maps app status to backend status. Backend uses: pending, confirmed, preparing, ready, assigned, out_for_delivery, delivered, cancelled.
  String _statusToBackend(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending:
        return 'pending';
      case OrderStatus.accepted:
        return 'confirmed';
      case OrderStatus.preparing:
        return 'preparing';
      case OrderStatus.ready:
        return 'ready'; // Posted for riders; riders see these in available-orders
      case OrderStatus.outForDelivery:
        return 'assigned';
      case OrderStatus.completed:
        return 'delivered';
      case OrderStatus.cancelled:
        return 'cancelled';
    }
  }

  List<Order> getByStatus(OrderStatus status) =>
      _orders.where((o) => o.status == status).toList();

  List<Order> get preparingOrders => _orders
      .where((o) =>
          o.status == OrderStatus.accepted || o.status == OrderStatus.preparing)
      .toList();
}
