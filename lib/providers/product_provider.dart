import 'package:flutter/foundation.dart';

import '../models/product.dart';
import '../services/api_service.dart';

class ProductProvider extends ChangeNotifier {
  List<Product> _products = [];

  bool _isLoading = false;

  String? _error;

  List<Product> get products => _products;

  bool get isLoading => _isLoading;

  String? get error => _error;

  Future<void> loadProducts() async {
    _isLoading = true;
    _error = null;

    notifyListeners();

    try {
      _products = await ApiService.getProducts();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;

    notifyListeners();
  }
}
