class Customer {
  final int id;
  final String fullname;
  final String email;
  final String phone;
  final String address;

  const Customer({
    required this.id,
    required this.fullname,
    required this.email,
    required this.phone,
    required this.address,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: int.tryParse(json['id'].toString()) ?? 0,
      fullname: json['fullname']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullname': fullname,
      'email': email,
      'phone': phone,
      'address': address,
    };
  }
}