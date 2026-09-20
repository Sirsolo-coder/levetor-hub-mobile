import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/customer.dart';
import '../services/api_service.dart';

class CustomerProvider extends ChangeNotifier {
  Customer? _customer;
  bool _isLoading = false;

  Customer? get customer => _customer;

  int? get customerId => _customer?.id;

  bool get isLoggedIn => _customer != null;

  bool get isLoading => _isLoading;

  String get fullname => _customer?.fullname ?? '';

  String get email => _customer?.email ?? '';

  String get phone => _customer?.phone ?? '';

  String get address => _customer?.address ?? '';

  // ============================================================
  // SET CUSTOMER AFTER LOGIN / REGISTRATION
  // ============================================================

  Future<void> setCustomer(
    Customer customer, {
    String? apiToken,
  }) async {
    _customer = customer;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(
      'customer_id',
      customer.id,
    );

    await prefs.setString(
      'customer_fullname',
      customer.fullname,
    );

    await prefs.setString(
      'customer_email',
      customer.email,
    );

    await prefs.setString(
      'customer_phone',
      customer.phone,
    );

    await prefs.setString(
      'customer_address',
      customer.address,
    );

    if (apiToken != null && apiToken.trim().isNotEmpty) {
      await prefs.setString(
        'api_token',
        apiToken.trim(),
      );

      debugPrint(
        'API authentication token saved successfully.',
      );
    }

    notifyListeners();

    // Register this phone for notifications.
    await registerNotificationToken();
  }

  // ============================================================
  // BACKWARD COMPATIBILITY
  // ============================================================

  Future<void> setCustomerId(
    int customerId,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(
      'customer_id',
      customerId,
    );

    if (_customer == null ||
        _customer!.id != customerId) {
      _customer = Customer(
        id: customerId,
        fullname: '',
        email: '',
        phone: '',
        address: '',
      );
    }

    notifyListeners();

    await registerNotificationToken();
  }

  // ============================================================
  // LOAD SAVED CUSTOMER
  // ============================================================

  Future<void> loadCustomer() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();

    final id = prefs.getInt(
      'customer_id',
    );

    if (id != null) {
      _customer = Customer(
        id: id,
        fullname:
            prefs.getString(
              'customer_fullname',
            ) ??
            '',
        email:
            prefs.getString(
              'customer_email',
            ) ??
            '',
        phone:
            prefs.getString(
              'customer_phone',
            ) ??
            '',
        address:
            prefs.getString(
              'customer_address',
            ) ??
            '',
      );
    }

    _isLoading = false;
    notifyListeners();

    if (_customer != null) {
      await registerNotificationToken();
    }
  }

  // ============================================================
  // REGISTER FCM DEVICE TOKEN
  // ============================================================

  Future<void> registerNotificationToken() async {
    final customer = _customer;

    if (customer == null) {
      return;
    }

    try {
      final messaging =
          FirebaseMessaging.instance;

      final token = await messaging.getToken();

      if (token == null ||
          token.trim().isEmpty) {
        debugPrint(
          'FCM token unavailable.',
        );
        return;
      }

      final registered =
          await ApiService.registerFcmToken(
        customerId: customer.id,
        fcmToken: token,
      );

      debugPrint(
        registered
            ? 'FCM token linked to customer ${customer.id}.'
            : 'FCM token could not be linked.',
      );
    } catch (e) {
      debugPrint(
        'FCM customer registration error: $e',
      );
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> clearCustomer() async {
    _customer = null;

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(
      'customer_id',
    );

    await prefs.remove(
      'customer_fullname',
    );

    await prefs.remove(
      'customer_email',
    );

    await prefs.remove(
      'customer_phone',
    );

    await prefs.remove(
      'customer_address',
    );

    await prefs.remove(
      'api_token',
    );

    notifyListeners();
  }
}