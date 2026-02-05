class Order {
  final String id;
  final String customerName;
  final String timeAgo;
  final List<String> items;
  final double total;

  Order({
    required this.id,
    required this.customerName,
    required this.timeAgo,
    required this.items,
    required this.total,
  });
}