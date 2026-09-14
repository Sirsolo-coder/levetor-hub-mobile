import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../services/api_service.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Shopping Cart',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (cart.items.isNotEmpty)
            IconButton(
              tooltip: 'Clear cart',
              onPressed: () {
                _showClearCartDialog(context, cart);
              },
              icon: const Icon(
                Icons.delete_sweep_outlined,
              ),
            ),
        ],
      ),
      body: cart.items.isEmpty
          ? _buildEmptyCart(context)
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    14,
                    16,
                    4,
                  ),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${cart.itemCount} item${cart.itemCount == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Cart',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      12,
                      8,
                      12,
                      12,
                    ),
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      final product = item.product;

                      final double subtotal =
                          product.price * item.quantity;

                      final bool canIncrease =
                          item.quantity < product.stock;

                      return Card(
                        margin: const EdgeInsets.only(
                          bottom: 12,
                        ),
                        elevation: 1.5,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(16),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 95,
                                height: 105,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                                child: product.image != null &&
                                        product.image!
                                            .trim()
                                            .isNotEmpty
                                    ? ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(
                                          12,
                                        ),
                                        child: Image.network(
                                          ApiService.getImageUrl(
                                            product.image,
                                          ),
                                          fit: BoxFit.contain,
                                          loadingBuilder: (
                                            context,
                                            child,
                                            loadingProgress,
                                          ) {
                                            if (loadingProgress ==
                                                null) {
                                              return child;
                                            }

                                            return const Center(
                                              child: SizedBox(
                                                width: 24,
                                                height: 24,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              ),
                                            );
                                          },
                                          errorBuilder: (
                                            context,
                                            error,
                                            stackTrace,
                                          ) {
                                            return Icon(
                                              Icons
                                                  .image_not_supported_outlined,
                                              size: 42,
                                              color: Colors
                                                  .grey
                                                  .shade500,
                                            );
                                          },
                                        ),
                                      )
                                    : Icon(
                                        Icons.image_outlined,
                                        size: 42,
                                        color:
                                            Colors.grey.shade500,
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      maxLines: 2,
                                      overflow:
                                          TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${product.brand} ${product.model}',
                                      maxLines: 1,
                                      overflow:
                                          TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color:
                                            Colors.grey.shade700,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 7),
                                    Text(
                                      '₦${product.price.toStringAsFixed(0)} each',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color:
                                            Colors.grey.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '₦${subtotal.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 9),
                                    Row(
                                      children: [
                                        Container(
                                          height: 38,
                                          decoration:
                                              BoxDecoration(
                                            border: Border.all(
                                              color: Colors
                                                  .grey
                                                  .shade300,
                                            ),
                                            borderRadius:
                                                BorderRadius
                                                    .circular(
                                              10,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              IconButton(
                                                tooltip:
                                                    'Decrease quantity',
                                                visualDensity:
                                                    VisualDensity
                                                        .compact,
                                                onPressed: () {
                                                  cart
                                                      .decreaseQuantity(
                                                    product.id,
                                                  );
                                                },
                                                icon: const Icon(
                                                  Icons.remove,
                                                  size: 18,
                                                ),
                                              ),
                                              SizedBox(
                                                width: 28,
                                                child: Text(
                                                  '${item.quantity}',
                                                  textAlign:
                                                      TextAlign
                                                          .center,
                                                  style:
                                                      const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight:
                                                        FontWeight
                                                            .bold,
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                tooltip:
                                                    'Increase quantity',
                                                visualDensity:
                                                    VisualDensity
                                                        .compact,
                                                onPressed:
                                                    canIncrease
                                                        ? () {
                                                            cart
                                                                .increaseQuantity(
                                                              product
                                                                  .id,
                                                            );
                                                          }
                                                        : null,
                                                icon: const Icon(
                                                  Icons.add,
                                                  size: 18,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Spacer(),
                                        IconButton(
                                          tooltip:
                                              'Remove from cart',
                                          onPressed: () {
                                            cart.removeFromCart(
                                              product.id,
                                            );
                                          },
                                          icon: Icon(
                                            Icons
                                                .delete_outline,
                                            color: Colors
                                                .grey
                                                .shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (!canIncrease)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(
                                          top: 4,
                                        ),
                                        child: Text(
                                          'Maximum available stock reached',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors
                                                .grey
                                                .shade600,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      16,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .scaffoldBackgroundColor,
                      border: Border(
                        top: BorderSide(
                          color: Colors.grey.shade300,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Items',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            Text(
                              '${cart.itemCount}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Subtotal',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            Text(
                              '₦${cart.total.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Divider(
                          color: Colors.grey.shade300,
                          height: 1,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '₦${cart.total.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const CheckoutScreen(),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.shopping_bag_outlined,
                            ),
                            label: const Text(
                              'Proceed to Checkout',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 64,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Your cart is empty',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add products to your cart to see them here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(
                Icons.shopping_bag_outlined,
              ),
              label: const Text(
                'Continue Shopping',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearCartDialog(
    BuildContext context,
    CartProvider cart,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Clear Cart?',
          ),
          content: const Text(
            'Are you sure you want to remove all products from your cart?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Cancel',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                cart.clearCart();
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Clear',
              ),
            ),
          ],
        );
      },
    );
  }
}