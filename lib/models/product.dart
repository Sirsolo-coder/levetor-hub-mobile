class Product {
  final int id;
  final String name;
  final String category;
  final String brand;
  final String model;
  final String description;
  final double price;
  final int stock;
  final String? image;
  final String condition;
  final String warranty;
  final String? createdAt;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.brand,
    required this.model,
    required this.description,
    required this.price,
    required this.stock,
    this.image,
    required this.condition,
    required this.warranty,
    this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      brand: json['brand'] ?? '',
      model: json['model'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      stock: json['stock'] ?? 0,
      image: json['image'],
      condition: json['condition'] ?? '',
      warranty: json['warranty'] ?? '',
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'brand': brand,
      'model': model,
      'description': description,
      'price': price,
      'stock': stock,
      'image': image,
      'condition': condition,
      'warranty': warranty,
      'created_at': createdAt,
    };
  }
}