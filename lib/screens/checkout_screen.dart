import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/cart_provider.dart';
import '../providers/customer_provider.dart';
import '../services/api_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isPlacingOrder = false;
  bool _isCheckingPayment = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();

    super.dispose();
  }

    // =========================================================
  // PLACE ORDER + START PAYMENT
  // =========================================================

  Future<void> _placeOrder() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final cart = context.read<CartProvider>();

    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your cart is empty.'),
        ),
      );
      return;
    }

    if (_isPlacingOrder || _isCheckingPayment) {
      return;
    }

    final customerProvider =
        context.read<CustomerProvider>();

    final customerId =
        customerProvider.customerId;

    // =======================================================
    // PAYMENT REQUIRES A LOGGED-IN CUSTOMER
    // =======================================================

    if (customerId == null || customerId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please login again before making a payment.',
          ),
        ),
      );
      return;
    }

    final hasToken =
        await ApiService.hasAuthToken();

    if (!hasToken) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your login session is missing. Please login again.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isPlacingOrder = true;
    });

    try {
      final items = cart.items.map((item) {
        return {
          'product_id': item.product.id,
          'quantity': item.quantity,
        };
      }).toList();

      // =======================================================
      // CREATE AUTHENTICATED ORDER
      // =======================================================

      final result = await ApiService.createOrder(
        customerId: customerId,
        fullname: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        items: items,
      );

      final orderId = result['order_id'];

      if (orderId == null) {
        throw Exception(
          'Server did not return an order ID.',
        );
      }

      final int parsedOrderId =
          int.parse(orderId.toString());

      debugPrint(
        'Authenticated customer: $customerId',
      );

      debugPrint(
        'Order created: $parsedOrderId',
      );

      // =======================================================
      // INITIALIZE PAYSTACK
      // =======================================================

      final payment =
          await ApiService.initializePayment(
        orderId: parsedOrderId,
      );

      final authorizationUrl =
          payment['authorization_url']?.toString();

      final reference =
          payment['reference']?.toString();

      if (authorizationUrl == null ||
          authorizationUrl.isEmpty) {
        throw Exception(
          'Paystack checkout URL was not returned.',
        );
      }

      if (reference == null ||
          reference.isEmpty) {
        throw Exception(
          'Paystack payment reference was not returned.',
        );
      }

      debugPrint(
        'Paystack reference: $reference',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isPlacingOrder = false;
      });

      // =======================================================
      // OPEN PAYSTACK
      // =======================================================

      final paymentUrl =
          Uri.parse(authorizationUrl);

      final launched =
          await launchUrl(
        paymentUrl,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        throw Exception(
          'Unable to open Paystack checkout.',
        );
      }

      if (!mounted) {
        return;
      }

      // =======================================================
      // WAIT FOR USER TO RETURN
      // =======================================================

      await _showPaymentVerificationDialog(
        orderId: parsedOrderId,
        reference: reference,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isPlacingOrder = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Payment setup failed:\n'
            '${e.toString().replaceFirst(
              'Exception: ',
              '',
            )}',
          ),
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }
  // =========================================================
  // PAYMENT VERIFICATION DIALOG
  // =========================================================

  Future<void> _showPaymentVerificationDialog({
    required int orderId,
    required String reference,
  }) async {
    if (!mounted) {
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.payment,
            size: 60,
          ),
          title: const Text(
            'Complete Your Payment',
            textAlign: TextAlign.center,
          ),
          content: const Text(
            'Paystack checkout has been opened.\n\n'
            'Complete the payment, then tap '
            '"I Have Paid" to verify your payment.',
            textAlign: TextAlign.center,
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(true);
                },
                child: const Text(
                  'I Have Paid',
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text(
                'Check Again Later',
              ),
            ),
          ],
        );
      },
    );

    if (!mounted) {
      return;
    }

    if (result == true) {
      await _verifyPayment(
        orderId: orderId,
        reference: reference,
      );
    }
  }

  // =========================================================
  // VERIFY PAYMENT
  // =========================================================

  Future<void> _verifyPayment({
    required int orderId,
    required String reference,
  }) async {
    if (_isCheckingPayment) {
      return;
    }

    setState(() {
      _isCheckingPayment = true;
    });

    try {
      final result = await ApiService.verifyPayment(
        reference: reference,
      );

      final success = result['success'] == true;

      if (!success) {
        throw Exception(
          result['message']?.toString() ??
              'Payment could not be verified.',
        );
      }

      final paymentStatus =
          result['payment_status']?.toString();

      if (paymentStatus?.toLowerCase() != 'paid') {
        throw Exception(
          result['message']?.toString() ??
              'Payment has not been completed.',
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _isCheckingPayment = false;
      });

      // Payment is confirmed.
      final cart = context.read<CartProvider>();
      cart.clearCart();

      await _showPaymentSuccessDialog(
        orderId: orderId,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isCheckingPayment = false;
      });

      await showDialog(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            icon: const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 60,
            ),
            title: const Text(
              'Payment Not Confirmed',
              textAlign: TextAlign.center,
            ),
            content: Text(
              e.toString().replaceFirst(
                    'Exception: ',
                    '',
                  ),
              textAlign: TextAlign.center,
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text(
                    'OK',
                  ),
                ),
              ),
            ],
          );
        },
      );
    }
  }

  // =========================================================
  // PAYMENT SUCCESS
  // =========================================================

  Future<void> _showPaymentSuccessDialog({
    required int orderId,
  }) async {
    if (!mounted) {
      return;
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 70,
          ),
          title: const Text(
            'Payment Successful',
            textAlign: TextAlign.center,
          ),
          content: Text(
            'Your payment has been verified successfully.\n\n'
            'Order ID: #$orderId\n\n'
            'Thank you for shopping with Levetor Hub.',
            textAlign: TextAlign.center,
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text(
                  'Continue Shopping',
                ),
              ),
            ),
          ],
        );
      },
    );

    if (!mounted) {
      return;
    }

    Navigator.of(context).popUntil(
      (route) => route.isFirst,
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    final busy =
        _isPlacingOrder || _isCheckingPayment;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Checkout',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: cart.items.isEmpty
          ? _buildEmptyCart()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    // =================================================
                    // CUSTOMER INFORMATION
                    // =================================================

                    const Text(
                      'Customer Information',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _nameController,
                      textCapitalization:
                          TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        hintText:
                            'Enter your full name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(
                          Icons.person_outline,
                        ),
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'Please enter your full name';
                        }

                        if (value.trim().length < 3) {
                          return 'Please enter a valid name';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _emailController,
                      keyboardType:
                          TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        hintText:
                            'example@email.com',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(
                          Icons.email_outlined,
                        ),
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'Please enter your email';
                        }

                        final email =
                            value.trim();

                        if (!email.contains('@') ||
                            !email.contains('.')) {
                          return 'Enter a valid email address';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _phoneController,
                      keyboardType:
                          TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        hintText: '08012345678',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(
                          Icons.phone_outlined,
                        ),
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'Please enter your phone number';
                        }

                        if (value.trim().length < 10) {
                          return 'Enter a valid phone number';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _addressController,
                      textCapitalization:
                          TextCapitalization.sentences,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText:
                            'Delivery Address',
                        hintText:
                            'Enter your complete delivery address',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(
                          Icons.location_on_outlined,
                        ),
                        alignLabelWithHint: true,
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'Please enter your delivery address';
                        }

                        if (value.trim().length < 10) {
                          return 'Please enter a complete address';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 30),

                    // =================================================
                    // ORDER SUMMARY
                    // =================================================

                    const Text(
                      'Order Summary',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 14),

                    Card(
                      elevation: 2,
                      child: Padding(
                        padding:
                            const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            ...cart.items.map(
                              (item) {
                                return Padding(
                                  padding:
                                      const EdgeInsets.only(
                                    bottom: 14,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${item.product.name} × ${item.quantity}',
                                          style:
                                              const TextStyle(
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 12,
                                      ),
                                      Text(
                                        '₦${item.subtotal.toStringAsFixed(0)}',
                                        style:
                                            const TextStyle(
                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),

                            const Divider(),

                            const SizedBox(height: 8),

                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .spaceBetween,
                              children: [
                                const Text(
                                  'Total Items',
                                ),
                                Text(
                                  '${cart.itemCount}',
                                  style:
                                      const TextStyle(
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .spaceBetween,
                              children: [
                                const Text(
                                  'Total',
                                  style:
                                      TextStyle(
                                    fontSize: 20,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '₦${cart.total.toStringAsFixed(0)}',
                                  style:
                                      const TextStyle(
                                    fontSize: 22,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // =================================================
                    // PAYMENT BUTTON
                    // =================================================

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed:
                            busy ? null : _placeOrder,
                        icon: busy
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.payment,
                              ),
                        label: Text(
                          _isPlacingOrder
                              ? 'Preparing Payment...'
                              : _isCheckingPayment
                                  ? 'Verifying Payment...'
                                  : 'Pay with Paystack',
                          style:
                              const TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Center(
                      child: Text(
                        'You will be securely redirected to Paystack '
                        'to complete your payment.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              Colors.grey.shade600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  // =========================================================
  // EMPTY CART
  // =========================================================

  Widget _buildEmptyCart() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 80,
            ),
            SizedBox(height: 18),
            Text(
              'Your cart is empty',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Add products to your cart before checking out.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}