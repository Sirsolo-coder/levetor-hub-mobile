import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../services/api_service.dart';
import 'cart_screen.dart';

class ProductDetailsScreen extends StatelessWidget {
  final Product product;

  const ProductDetailsScreen({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final bool inStock = product.stock > 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          product.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          Consumer<CartProvider>(
            builder: (context, cart, child) {
              return Stack(
                children: [
                  IconButton(
                    tooltip: 'Cart',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CartScreen(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.shopping_cart_outlined,
                    ),
                  ),
                  if (cart.itemCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${cart.itemCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          30,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==========================================
            // PRODUCT IMAGE
            // ==========================================
            Container(
              width: double.infinity,
              height: 330,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  Center(
                    child: product.image != null &&
                            product.image!.trim().isNotEmpty
                        ? ClipRRect(
                            borderRadius:
                                BorderRadius.circular(20),
                            child: Image.network(
                              ApiService.getImageUrl(
                                product.image,
                              ),
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.contain,
                              loadingBuilder:
                                  (context,
                                      child,
                                      loadingProgress) {
                                if (loadingProgress ==
                                    null) {
                                  return child;
                                }

                                return const Center(
                                  child:
                                      CircularProgressIndicator(),
                                );
                              },
                              errorBuilder:
                                  (context,
                                      error,
                                      stackTrace) {
                                return const Center(
                                  child: Icon(
                                    Icons
                                        .image_not_supported,
                                    size: 70,
                                  ),
                                );
                              },
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.image,
                              size: 70,
                            ),
                          ),
                  ),

                  // CONDITION BADGE
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color:
                                Colors.black.withValues(
                              alpha: 0.08,
                            ),
                            blurRadius: 6,
                            offset:
                                const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        product.condition,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // ==========================================
            // CATEGORY
            // ==========================================
            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius:
                    BorderRadius.circular(8),
              ),
              child: Text(
                product.category,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ==========================================
            // PRODUCT NAME
            // ==========================================
            Text(
              product.name,
              style: const TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),

            const SizedBox(height: 7),

            // ==========================================
            // BRAND + MODEL
            // ==========================================
            Text(
              '${product.brand} ${product.model}',
              style: TextStyle(
                fontSize: 17,
                color: Colors.grey.shade700,
              ),
            ),

            const SizedBox(height: 16),

            // ==========================================
            // PRICE
            // ==========================================
            Text(
              '₦${product.price.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            // ==========================================
            // STOCK STATUS
            // ==========================================
            Row(
              children: [
                Icon(
                  inStock
                      ? Icons.check_circle
                      : Icons.cancel,
                  size: 19,
                ),
                const SizedBox(width: 7),
                Text(
                  inStock
                      ? 'In stock • ${product.stock} available'
                      : 'Out of stock',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            // ==========================================
            // PRODUCT INFORMATION
            // ==========================================
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(16),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Product Information',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 16),

                    _infoRow(
                      'Category',
                      product.category,
                    ),

                    _infoRow(
                      'Brand',
                      product.brand,
                    ),

                    _infoRow(
                      'Model',
                      product.model,
                    ),

                    _infoRow(
                      'Condition',
                      product.condition,
                    ),

                    _infoRow(
                      'Warranty',
                      product.warranty,
                    ),

                    _infoRow(
                      'Stock',
                      product.stock.toString(),
                      isLast: true,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ==========================================
            // DESCRIPTION
            // ==========================================
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius:
                    BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.grey.shade200,
                ),
              ),
              child: Text(
                product.description,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.55,
                ),
              ),
            ),

            const SizedBox(height: 30),

            // ==========================================
            // ADD TO CART
            // ==========================================
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: inStock
                    ? () {
                        context
                            .read<CartProvider>()
                            .addToCart(product);

                        ScaffoldMessenger.of(
                          context,
                        ).hideCurrentSnackBar();

                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${product.name} added to cart',
                            ),
                            duration:
                                const Duration(
                              seconds: 2,
                            ),
                            action: SnackBarAction(
                              label: 'VIEW CART',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const CartScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      }
                    : null,
                icon: const Icon(
                  Icons.shopping_cart,
                  size: 21,
                ),
                label: Text(
                  inStock
                      ? 'Add to Cart'
                      : 'Out of Stock',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ==========================================
            // VIEW CART
            // ==========================================
            Consumer<CartProvider>(
              builder: (context, cart, child) {
                if (cart.itemCount == 0) {
                  return const SizedBox.shrink();
                }

                return SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const CartScreen(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.shopping_bag_outlined,
                    ),
                    label: Text(
                      'View Cart (${cart.itemCount})',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(
    String label,
    String value, {
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: isLast ? 0 : 14,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}