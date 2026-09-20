import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/customer.dart';
import '../models/order.dart';
import '../models/product.dart';

class ApiService {
  // =========================================================
  // API CONFIGURATION
  // =========================================================

  static const String baseUrl = 'https://levetor-hub.onrender.com';
  // =========================================================
  // AUTHENTICATION TOKEN
  // =========================================================

  static const String _tokenKey = 'api_token';

  // =========================================================
  // SAVE AUTH TOKEN
  // =========================================================

  static Future<void> _saveAuthTokenFromResponse(
    dynamic data,
  ) async {
    if (data is! Map) {
      return;
    }

    String? token;

    final possibleTokenKeys = [
      'api_token',
      'token',
      'access_token',
    ];

    for (final key in possibleTokenKeys) {
      final value = data[key];

      if (value != null &&
          value.toString().trim().isNotEmpty) {
        token = value.toString().trim();
        break;
      }
    }

    if (token == null) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _tokenKey,
      token,
    );
  }

  // =========================================================
  // AUTHENTICATED API HEADERS
  // =========================================================

  static Future<Map<String, String>> _authenticatedHeaders({
    bool includeJson = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString(_tokenKey);

    final headers = <String, String>{};

    if (includeJson) {
      headers['Content-Type'] = 'application/json';
    }

    if (token != null &&
        token.trim().isNotEmpty) {
      headers['Authorization'] =
          'Bearer ${token.trim()}';
    }

    return headers;
  }

  // =========================================================
  // CHECK AUTH TOKEN
  // =========================================================

  static Future<bool> hasAuthToken() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString(_tokenKey);

    return token != null &&
        token.trim().isNotEmpty;
  }

  // =========================================================
  // CLEAR AUTH TOKEN
  // =========================================================

  static Future<void> clearAuthToken() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_tokenKey);
  }

  // =========================================================
  // HEALTH CHECK
  // =========================================================

  static Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/health'),
          )
          .timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode != 200) {
        return false;
      }

      final data = jsonDecode(response.body);

      return data is Map &&
          data['success'] == true;
    } catch (_) {
      return false;
    }
  }

  // =========================================================
  // GET PRODUCTS
  // =========================================================

  static Future<List<Product>> getProducts() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/products'),
          )
          .timeout(
            const Duration(seconds: 15),
          );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to load products. '
          'Server returned ${response.statusCode}.',
        );
      }

      final dynamic data =
          jsonDecode(response.body);

      List<dynamic> productsData;

      if (data is Map &&
          data['value'] is List) {
        productsData =
            data['value'] as List;
      } else if (data is List) {
        productsData = data;
      } else {
        throw Exception(
          'Invalid products response from server.',
        );
      }

      return productsData
          .whereType<Map>()
          .map(
            (json) => Product.fromJson(
              Map<String, dynamic>.from(json),
            ),
          )
          .toList();
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        'Unable to connect to Levetor Hub server.',
      );
    }
  }

  // =========================================================
  // GET SINGLE PRODUCT
  // =========================================================

  static Future<Product> getProduct(
    int productId,
  ) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '$baseUrl/api/products/$productId',
            ),
          )
          .timeout(
            const Duration(seconds: 15),
          );

      if (response.statusCode != 200) {
        String message =
            'Failed to load product.';

        try {
          final data =
              jsonDecode(response.body);

          if (data is Map &&
              data['error'] != null) {
            message =
                data['error'].toString();
          } else if (data is Map &&
              data['message'] != null) {
            message =
                data['message'].toString();
          }
        } catch (_) {}

        throw Exception(message);
      }

      final dynamic data =
          jsonDecode(response.body);

      if (data is! Map) {
        throw Exception(
          'Invalid product response from server.',
        );
      }

      dynamic productData;

      if (data['product'] is Map) {
        productData = data['product'];
      } else if (data['id'] != null) {
        productData = data;
      } else {
        throw Exception(
          'Product data was not found in server response.',
        );
      }

      return Product.fromJson(
        Map<String, dynamic>.from(
          productData,
        ),
      );
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        'Unable to connect to Levetor Hub server.',
      );
    }
  }

    // =========================================================
  // CREATE ORDER
  // =========================================================

  static Future<Map<String, dynamic>> createOrder({
    int? customerId,
    required String fullname,
    required String email,
    required String phone,
    required String address,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final requestBody = <String, dynamic>{
        'fullname': fullname,
        'email': email,
        'phone': phone,
        'address': address,
        'items': items,
      };

      if (customerId != null) {
        requestBody['customer_id'] = customerId;
      }

      // Authenticated customer orders must include the API token.
      final headers = customerId != null
          ? await _authenticatedHeaders(
              includeJson: true,
            )
          : <String, String>{
              'Content-Type': 'application/json',
            };

      if (customerId != null &&
          !headers.containsKey('Authorization')) {
        throw Exception(
          'Authentication required. Please login again.',
        );
      }

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/orders'),
            headers: headers,
            body: jsonEncode(requestBody),
          )
          .timeout(
            const Duration(seconds: 20),
          );

      dynamic data;

      try {
        data = jsonDecode(response.body);
      } catch (_) {
        throw Exception(
          'Invalid response received from server.',
        );
      }

      if (response.statusCode != 201) {
        String message = 'Failed to create order.';

        if (data is Map) {
          if (data['message'] != null) {
            message = data['message'].toString();
          } else if (data['error'] != null) {
            message = data['error'].toString();
          }
        }

        throw Exception(message);
      }

      if (data is! Map) {
        throw Exception(
          'Invalid order response received from server.',
        );
      }

      return Map<String, dynamic>.from(data);
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        'Unable to connect to Levetor Hub server.',
      );
    }
  }

  // =========================================================
  // INITIALIZE PAYSTACK PAYMENT
  // =========================================================

  static Future<Map<String, dynamic>>
      initializePayment({
    required int orderId,
  }) async {
    try {
      final headers =
          await _authenticatedHeaders(
        includeJson: true,
      );

      if (!headers.containsKey(
        'Authorization',
      )) {
        throw Exception(
          'Authentication required. Please login again.',
        );
      }

      final response = await http
          .post(
            Uri.parse(
              '$baseUrl/api/payments/initialize',
            ),
            headers: headers,
            body: jsonEncode({
              'order_id': orderId,
            }),
          )
          .timeout(
            const Duration(seconds: 30),
          );

      dynamic data;

      try {
        data = jsonDecode(
          response.body,
        );
      } catch (_) {
        throw Exception(
          'Invalid payment initialization response.',
        );
      }

      if (response.statusCode != 200) {
        String message =
            'Failed to initialize payment.';

        if (data is Map) {
          if (data['message'] != null) {
            message =
                data['message'].toString();
          } else if (data['error'] != null) {
            message =
                data['error'].toString();
          }
        }

        throw Exception(message);
      }

      if (data is! Map) {
        throw Exception(
          'Invalid payment initialization response.',
        );
      }

      final result =
          Map<String, dynamic>.from(
        data,
      );

      if (result['success'] != true) {
        throw Exception(
          result['message']?.toString() ??
              'Payment initialization failed.',
        );
      }

      return result;
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        'Unable to connect to payment server.',
      );
    }
  }

  // =========================================================
  // VERIFY PAYSTACK PAYMENT
  // =========================================================

  static Future<Map<String, dynamic>>
      verifyPayment({
    required String reference,
  }) async {
    try {
      final cleanReference =
          reference.trim();

      if (cleanReference.isEmpty) {
        throw Exception(
          'Payment reference is required.',
        );
      }

      final headers =
          await _authenticatedHeaders();

      final response = await http
          .get(
            Uri.parse(
              '$baseUrl/api/payments/verify/'
              '${Uri.encodeComponent(cleanReference)}',
            ),
            headers: headers,
          )
          .timeout(
            const Duration(seconds: 30),
          );

      dynamic data;

      try {
        data = jsonDecode(
          response.body,
        );
      } catch (_) {
        throw Exception(
          'Invalid payment verification response.',
        );
      }

      if (response.statusCode != 200) {
        String message =
            'Payment verification failed.';

        if (data is Map) {
          if (data['message'] != null) {
            message =
                data['message'].toString();
          } else if (data['error'] != null) {
            message =
                data['error'].toString();
          }
        }

        throw Exception(message);
      }

      if (data is! Map) {
        throw Exception(
          'Invalid payment verification response.',
        );
      }

      final result =
          Map<String, dynamic>.from(
        data,
      );

      if (result['success'] != true) {
        throw Exception(
          result['message']?.toString() ??
              'Payment verification failed.',
        );
      }

      return result;
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        'Unable to connect to payment server.',
      );
    }
  }

  // =========================================================
  // GET CUSTOMER ORDERS
  // =========================================================

  static Future<List<Order>> getOrders(
    int customerId,
  ) async {
    try {
      final headers =
          await _authenticatedHeaders();

      final response = await http
          .get(
            Uri.parse(
              '$baseUrl/api/orders/$customerId',
            ),
            headers: headers,
          )
          .timeout(
            const Duration(seconds: 15),
          );

      if (response.statusCode != 200) {
        dynamic data;

        try {
          data = jsonDecode(
            response.body,
          );
        } catch (_) {
          data = null;
        }

        String message =
            'Failed to load orders. '
            'Server returned ${response.statusCode}.';

        if (data is Map &&
            data['message'] != null) {
          message =
              data['message'].toString();
        }

        throw Exception(message);
      }

      final dynamic data =
          jsonDecode(response.body);

      List<dynamic>? ordersData;

      if (data is List) {
        ordersData = data;
      } else if (data is Map &&
          data['orders'] is List) {
        ordersData =
            data['orders'] as List;
      } else if (data is Map &&
          data['value'] is List) {
        ordersData =
            data['value'] as List;
      }

      if (ordersData == null) {
        throw Exception(
          'Invalid orders response from server.',
        );
      }

      return ordersData
          .whereType<Map>()
          .map(
            (json) => Order.fromJson(
              Map<String, dynamic>.from(
                json,
              ),
            ),
          )
          .toList();
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        'Unable to connect to Levetor Hub server.',
      );
    }
  }

  // =========================================================
  // IMAGE URL
  // =========================================================

  static String getImageUrl(
    String? imageName,
  ) {
    if (imageName == null ||
        imageName.trim().isEmpty) {
      return '';
    }

    final cleanName =
        imageName.trim();

    if (cleanName.startsWith(
          'http://',
        ) ||
        cleanName.startsWith(
          'https://',
        )) {
      return cleanName;
    }

    return '$baseUrl/static/uploads/$cleanName';
  }

  // =========================================================
  // REGISTER CUSTOMER
  // =========================================================

  static Future<Map<String, dynamic>>
      registerCustomer({
    required String fullname,
    required String email,
    required String phone,
    required String address,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(
              '$baseUrl/api/register',
            ),
            headers: {
              'Content-Type':
                  'application/json',
            },
            body: jsonEncode({
              'fullname': fullname,
              'email': email,
              'phone': phone,
              'address': address,
              'password': password,
              'confirm_password':
                  confirmPassword,
            }),
          )
          .timeout(
            const Duration(seconds: 20),
          );

      dynamic data;

      try {
        data = jsonDecode(
          response.body,
        );
      } catch (_) {
        throw Exception(
          'Invalid response received from server.',
        );
      }

      if (response.statusCode != 201) {
        String message =
            'Registration failed.';

        if (data is Map) {
          if (data['message'] != null) {
            message =
                data['message'].toString();
          } else if (data['error'] != null) {
            message =
                data['error'].toString();
          }
        }

        throw Exception(message);
      }

      if (data is! Map) {
        throw Exception(
          'Invalid registration response from server.',
        );
      }

      return Map<String, dynamic>.from(
        data,
      );
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        'Unable to connect to Levetor Hub server.',
      );
    }
  }

  // =========================================================
  // LOGIN CUSTOMER
  // =========================================================

  static Future<Map<String, dynamic>>
      loginCustomer({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(
              '$baseUrl/api/login',
            ),
            headers: {
              'Content-Type':
                  'application/json',
            },
            body: jsonEncode({
              'email': email,
              'password': password,
            }),
          )
          .timeout(
            const Duration(seconds: 20),
          );

      dynamic data;

      try {
        data = jsonDecode(
          response.body,
        );
      } catch (_) {
        throw Exception(
          'Invalid response received from server.',
        );
      }

      if (response.statusCode != 200) {
        String message =
            'Login failed.';

        if (data is Map) {
          if (data['message'] != null) {
            message =
                data['message'].toString();
          } else if (data['error'] != null) {
            message =
                data['error'].toString();
          }
        }

        throw Exception(message);
      }

      if (data is! Map) {
        throw Exception(
          'Invalid login response from server.',
        );
      }

      final result =
          Map<String, dynamic>.from(
        data,
      );

      if (result['success'] == false) {
        throw Exception(
          result['message']?.toString() ??
              'Login failed.',
        );
      }

      await _saveAuthTokenFromResponse(
        result,
      );

      return result;
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        'Unable to connect to Levetor Hub server.',
      );
    }
  }

  // =========================================================
  // GET CUSTOMER
  // =========================================================

  static Future<Customer> getCustomer(
    int customerId,
  ) async {
    try {
      final headers =
          await _authenticatedHeaders();

      final response = await http
          .get(
            Uri.parse(
              '$baseUrl/api/customers/$customerId',
            ),
            headers: headers,
          )
          .timeout(
            const Duration(seconds: 20),
          );

      dynamic data;

      try {
        data = jsonDecode(
          response.body,
        );
      } catch (_) {
        throw Exception(
          'Invalid response received from server.',
        );
      }

      if (response.statusCode != 200) {
        throw Exception(
          data is Map &&
                  data['message'] != null
              ? data['message'].toString()
              : 'Failed to load customer profile.',
        );
      }

      if (data is! Map ||
          data['customer'] is! Map) {
        throw Exception(
          'Invalid customer profile received from server.',
        );
      }

      return Customer.fromJson(
        Map<String, dynamic>.from(
          data['customer'],
        ),
      );
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        'Unable to connect to Levetor Hub server.',
      );
    }
  }

  // =========================================================
  // UPDATE CUSTOMER
  // =========================================================

  static Future<Customer> updateCustomer({
    required int customerId,
    required String fullname,
    required String email,
    required String phone,
    required String address,
  }) async {
    try {
      final headers =
          await _authenticatedHeaders(
        includeJson: true,
      );

      final response = await http
          .put(
            Uri.parse(
              '$baseUrl/api/customers/$customerId',
            ),
            headers: headers,
            body: jsonEncode({
              'fullname': fullname,
              'email': email,
              'phone': phone,
              'address': address,
            }),
          )
          .timeout(
            const Duration(seconds: 20),
          );

      dynamic data;

      try {
        data = jsonDecode(
          response.body,
        );
      } catch (_) {
        throw Exception(
          'Invalid response received from server.',
        );
      }

      if (response.statusCode != 200) {
        throw Exception(
          data is Map &&
                  data['message'] != null
              ? data['message'].toString()
              : 'Failed to update customer profile.',
        );
      }

      if (data is! Map ||
          data['customer'] is! Map) {
        throw Exception(
          'Invalid customer profile received from server.',
        );
      }

      return Customer.fromJson(
        Map<String, dynamic>.from(
          data['customer'],
        ),
      );
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        'Unable to connect to Levetor Hub server.',
      );
    }
  }

  // =========================================================
  // GOOGLE LOGIN
  // =========================================================

  static Future<Map<String, dynamic>>
      googleLogin({
    required String idToken,
  }) async {
    try {
      final cleanToken =
          idToken.trim();

      if (cleanToken.isEmpty) {
        throw Exception(
          'Google authentication token is missing.',
        );
      }

      final response = await http
          .post(
            Uri.parse(
              '$baseUrl/api/auth/google',
            ),
            headers: {
              'Content-Type':
                  'application/json',
            },
            body: jsonEncode({
              'id_token': cleanToken,
            }),
          )
          .timeout(
            const Duration(seconds: 20),
          );

      dynamic data;

      try {
        data = jsonDecode(
          response.body,
        );
      } catch (_) {
        throw Exception(
          'Invalid Google authentication response.',
        );
      }

      if (response.statusCode != 200) {
        String message =
            'Google login failed.';

        if (data is Map) {
          if (data['message'] != null) {
            message =
                data['message'].toString();
          } else if (data['error'] != null) {
            message =
                data['error'].toString();
          }
        }

        throw Exception(message);
      }

      if (data is! Map) {
        throw Exception(
          'Invalid Google authentication response.',
        );
      }

      final result =
          Map<String, dynamic>.from(
        data,
      );

      if (result['success'] != true) {
        throw Exception(
          result['message']?.toString() ??
              'Google login failed.',
        );
      }

      await _saveAuthTokenFromResponse(
        result,
      );

      return result;
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        'Unable to connect to Google authentication server.',
      );
    }
  }

  // =========================================================
  // FORGOT PASSWORD
  // =========================================================

  static Future<Map<String, dynamic>>
      forgotPassword({
    required String email,
  }) async {
    try {
      final cleanEmail =
          email.trim();

      if (cleanEmail.isEmpty) {
        throw Exception(
          'Email address is required.',
        );
      }

      final response = await http
          .post(
            Uri.parse(
              '$baseUrl/api/forgot-password',
            ),
            headers: {
              'Content-Type':
                  'application/json',
            },
            body: jsonEncode({
              'email': cleanEmail,
            }),
          )
          .timeout(
            const Duration(seconds: 20),
          );

      dynamic data;

      try {
        data = jsonDecode(
          response.body,
        );
      } catch (_) {
        throw Exception(
          'Invalid password reset response.',
        );
      }

      if (response.statusCode != 200) {
        String message =
            'Password reset request failed.';

        if (data is Map) {
          if (data['message'] != null) {
            message =
                data['message'].toString();
          } else if (data['error'] != null) {
            message =
                data['error'].toString();
          }
        }

        throw Exception(message);
      }

      if (data is! Map) {
        throw Exception(
          'Invalid password reset response.',
        );
      }

      final result =
          Map<String, dynamic>.from(
        data,
      );

      if (result['success'] != true) {
        throw Exception(
          result['message']?.toString() ??
              'Password reset request failed.',
        );
      }

      return result;
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        'Unable to connect to password reset server.',
      );
    }
  }

  // =========================================================
  // REGISTER FCM DEVICE TOKEN
  // =========================================================

  static Future<bool> registerFcmToken({
    required int customerId,
    required String fcmToken,
  }) async {
    try {
      final cleanToken =
          fcmToken.trim();

      if (cleanToken.isEmpty) {
        return false;
      }

      final headers =
          await _authenticatedHeaders(
        includeJson: true,
      );

      final response = await http
          .post(
            Uri.parse(
              '$baseUrl/api/customers/'
              '$customerId/fcm-token',
            ),
            headers: headers,
            body: jsonEncode({
              'fcm_token': cleanToken,
            }),
          )
          .timeout(
            const Duration(seconds: 20),
          );

      dynamic data;

      try {
        data = jsonDecode(
          response.body,
        );
      } catch (_) {
        return false;
      }

      if (response.statusCode != 200) {
        debugPrint(
          'FCM token registration failed: '
          '${response.statusCode}',
        );

        if (data is Map &&
            data['message'] != null) {
          debugPrint(
            'FCM server message: '
            '${data['message']}',
          );
        }

        return false;
      }

      if (data is! Map) {
        return false;
      }

      final result =
          Map<String, dynamic>.from(
        data,
      );

      if (result['success'] != true) {
        debugPrint(
          'FCM token registration failed: '
          '${result['message'] ?? 'Unknown error'}',
        );

        return false;
      }

      debugPrint(
        'FCM token registered for customer '
        '$customerId.',
      );

      return true;
    } catch (e) {
      debugPrint(
        'Unable to register FCM token: $e',
      );

      return false;
    }
  }

  // =========================================================
  // GET CUSTOMER NOTIFICATIONS
  // =========================================================

  static Future<Map<String, dynamic>>
      getNotifications(
    int customerId,
  ) async {
    try {
      final headers =
          await _authenticatedHeaders();

      final response = await http
          .get(
            Uri.parse(
              '$baseUrl/api/customers/'
              '$customerId/notifications',
            ),
            headers: headers,
          )
          .timeout(
            const Duration(seconds: 20),
          );

      dynamic data;

      try {
        data = jsonDecode(
          response.body,
        );
      } catch (_) {
        throw Exception(
          'Invalid notification response from server.',
        );
      }

      if (response.statusCode != 200) {
        throw Exception(
          data is Map &&
                  data['message'] != null
              ? data['message'].toString()
              : 'Failed to load notifications.',
        );
      }

      if (data is! Map) {
        throw Exception(
          'Invalid notification data received from server.',
        );
      }

      final result =
          Map<String, dynamic>.from(
        data,
      );

      if (result['success'] != true) {
        throw Exception(
          result['message']?.toString() ??
              'Failed to load notifications.',
        );
      }

      return result;
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        'Unable to connect to notification server.',
      );
    }
  }

  // =========================================================
  // MARK ONE NOTIFICATION AS READ
  // =========================================================

  static Future<bool> markNotificationAsRead({
    required int customerId,
    required int notificationId,
  }) async {
    try {
      final headers =
          await _authenticatedHeaders(
        includeJson: true,
      );

      final response = await http
          .put(
            Uri.parse(
              '$baseUrl/api/customers/'
              '$customerId/notifications/'
              '$notificationId/read',
            ),
            headers: headers,
          )
          .timeout(
            const Duration(seconds: 20),
          );

      dynamic data;

      try {
        data = jsonDecode(
          response.body,
        );
      } catch (_) {
        return false;
      }

      if (response.statusCode != 200) {
        return false;
      }

      if (data is! Map) {
        return false;
      }

      final result =
          Map<String, dynamic>.from(
        data,
      );

      return result['success'] == true;
    } catch (_) {
      return false;
    }
  }

  // =========================================================
  // MARK ALL NOTIFICATIONS AS READ
  // =========================================================

  static Future<bool>
      markAllNotificationsAsRead(
    int customerId,
  ) async {
    try {
      final headers =
          await _authenticatedHeaders(
        includeJson: true,
      );

      final response = await http
          .put(
            Uri.parse(
              '$baseUrl/api/customers/'
              '$customerId/notifications/read-all',
            ),
            headers: headers,
          )
          .timeout(
            const Duration(seconds: 20),
          );

      dynamic data;

      try {
        data = jsonDecode(
          response.body,
        );
      } catch (_) {
        return false;
      }

      if (response.statusCode != 200) {
        return false;
      }

      if (data is! Map) {
        return false;
      }

      final result =
          Map<String, dynamic>.from(
        data,
      );

      return result['success'] == true;
    } catch (_) {
      return false;
    }
  }
}