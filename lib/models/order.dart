class OrderItem {
  final int productId;
  final String name;
  final String brand;
  final String model;
  final String? image;
  final int quantity;
  final double price;

  OrderItem({
    required this.productId,
    required this.name,
    required this.brand,
    required this.model,
    this.image,
    required this.quantity,
    required this.price,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: int.tryParse(json['product_id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      brand: json['brand']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      image: json['image']?.toString(),
      quantity: int.tryParse(json['quantity']?.toString() ?? '0') ?? 0,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class Order {
  final int id;
  final int customerId;
  final double totalAmount;
  final String paymentStatus;
  final String orderStatus;
  final String? createdAt;
  final List<OrderItem> items;

  Order({
    required this.id,
    required this.customerId,
    required this.totalAmount,
    required this.paymentStatus,
    required this.orderStatus,
    this.createdAt,
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      customerId:
          int.tryParse(json['customer_id']?.toString() ?? '0') ?? 0,
      totalAmount:
          double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0.0,
      paymentStatus: json['payment_status']?.toString() ?? 'Pending',
      orderStatus: json['order_status']?.toString() ?? 'Pending',
      createdAt: json['created_at']?.toString(),
      items: (json['items'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((item) => OrderItem.fromJson(item))
          .toList(),
    );
  }
}