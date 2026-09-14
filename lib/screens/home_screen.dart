import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/product_provider.dart';
import '../providers/cart_provider.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import 'product_details_screen.dart';
import 'cart_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color skyBlue = Color(0xFF29B6F6);
  static const Color darkBlue = Color.fromARGB(255, 167, 189, 201);

  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = const [
    'All',
    'Phones',
    'Computers',
    'Accessories',
    'Tablets',
    'Audio & Headphones',
    'Gaming',
    'Home Appliances',
    'Softwares',
    'Solar & Power',
    'Others',
  ];

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Phones':
        return Icons.smartphone;
      case 'Computers':
        return Icons.laptop;
      case 'Accessories':
        return Icons.devices_other;
      case 'Tablets':
        return Icons.tablet_android;
      case 'Audio & Headphones':
        return Icons.headphones;
      case 'Gaming':
        return Icons.sports_esports;
      case 'Home Appliances':
        return Icons.home;
      case 'Softwares':
        return Icons.apps;
      case 'Solar & Power':
        return Icons.solar_power;
      case 'Others':
        return Icons.category;
      default:
        return Icons.grid_view;
    }
  }

  List<Product> _filteredProducts(List<Product> products) {
    return products.where((product) {
      final query = _searchQuery.trim().toLowerCase();

      final matchesSearch =
          query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.category.toLowerCase().contains(query) ||
          product.brand.toLowerCase().contains(query) ||
          product.model.toLowerCase().contains(query);

      final matchesCategory =
          _selectedCategory == 'All' ||
          product.category.toLowerCase() ==
              _selectedCategory.toLowerCase();

      return matchesSearch && matchesCategory;
    }).toList();
  }

  Future<void> _refreshProducts() async {
  await context.read<ProductProvider>().loadProducts();
}

  void _openCart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CartScreen(),
      ),
    );
  }

  void _addToCart(Product product) {
    if (product.stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This product is currently out of stock.'),
        ),
      );
      return;
    }

    context.read<CartProvider>().addToCart(product);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} added to cart'),
        action: SnackBarAction(
          label: 'VIEW CART',
          textColor: Colors.white,
          onPressed: _openCart,
        ),
      ),
    );
  }

    Widget _buildBrandHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        16,
        10,
        16,
        18,
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: skyBlue.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/app_logo.jpg',
                width: 48,
                height: 48,
                fit: BoxFit.contain,
                errorBuilder: (
                  context,
                  error,
                  stackTrace,
                ) {
                  return Container(
                    width: 80,
                    height: 80,
                    color: Colors.white,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.storefront_outlined,
                      size: 42,
                      color: skyBlue,
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            '...',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: skyBlue,
              letterSpacing: 0.3,
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            'Every Gadget You Love, One Hub',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: skyBlue,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            'Quality Gadgets, Electronics & Technology Solutions',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search gadgets, brands or models...',
          prefixIcon: const Icon(
            Icons.search,
            color: skyBlue,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.clear,
                    color: skyBlue,
                  ),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.grey.shade200,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.grey.shade200,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: skyBlue,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 58,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        // ignore: unnecessary_underscores
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final selected = _selectedCategory == category;

          return ChoiceChip(
            selected: selected,
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _categoryIcon(category),
                  size: 17,
                  color: selected ? Colors.white : skyBlue,
                ),
                const SizedBox(width: 6),
                Text(category),
              ],
            ),
            selectedColor: skyBlue,
            backgroundColor: Colors.white,
            side: BorderSide(
              color: selected
                  ? skyBlue
                  : Colors.grey.shade300,
            ),
            labelStyle: TextStyle(
              color: selected
                  ? Colors.white
                  : Colors.black87,
              fontWeight: selected
                  ? FontWeight.w600
                  : FontWeight.normal,
            ),
            onSelected: (_) {
              setState(() {
                _selectedCategory = category;
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final bool outOfStock = product.stock <= 0;

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailsScreen(
                product: product,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1.15,
                  child: Container(
                    width: double.infinity,
                    color: Colors.grey.shade50,
                    padding: const EdgeInsets.all(10),
                    child: Image.network(
                      ApiService.getImageUrl(product.image),
                      fit: BoxFit.contain,
                      // ignore: unnecessary_underscores
                      errorBuilder: (_, __, ___) {
                        return const Icon(
                          Icons.image_not_supported_outlined,
                          size: 45,
                          color: Colors.grey,
                        );
                      },
                      loadingBuilder:
                          (context, child, loadingProgress) {
                        if (loadingProgress == null) {
                          return child;
                        }

                        return const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: skyBlue,
                          ),
                        );
                      },
                    ),
                  ),
                ),

                if (outOfStock)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'OUT OF STOCK',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(
                12,
                10,
                12,
                12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    product.category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    '${product.brand} ${product.model}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 11,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    '₦${product.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: darkBlue,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Row(
                    children: [
                      Icon(
                        outOfStock
                            ? Icons.remove_circle_outline
                            : Icons.inventory_2_outlined,
                        size: 15,
                        color: outOfStock
                            ? Colors.red
                            : skyBlue,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          outOfStock
                              ? 'Out of stock'
                              : '${product.stock} in stock',
                          style: TextStyle(
                            fontSize: 11,
                            color: outOfStock
                                ? Colors.red
                                : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 9),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: outOfStock
                          ? null
                          : () => _addToCart(product),
                      icon: const Icon(
                        Icons.add_shopping_cart,
                        size: 17,
                      ),
                      label: const Text(
                        'Add to Cart',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: skyBlue,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            Colors.grey.shade300,
                        disabledForegroundColor:
                            Colors.grey.shade600,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
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
  }

  Widget _buildProductsGrid(List<Product> products) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = 2;

        if (constraints.maxWidth >= 1100) {
          columns = 4;
        } else if (constraints.maxWidth >= 700) {
          columns = 3;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            16,
            0,
            16,
            100,
          ),
          itemCount: products.length,
          gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.46,
          ),
          itemBuilder: (context, index) {
            return _buildProductCard(products[index]);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 30,
        vertical: 60,
      ),
      child: Column(
        children: [
          Icon(
            Icons.search_off,
            size: 70,
            color: skyBlue.withValues(alpha: 0.65),
          ),
          const SizedBox(height: 15),
          const Text(
            'No products found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try another search or category.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _selectedCategory = 'All';
              });
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: skyBlue,
              side: const BorderSide(
                color: skyBlue,
              ),
            ),
            child: const Text('Clear Filters'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Levetor Hub',
          style: TextStyle(
            color: skyBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh products',
            onPressed: _refreshProducts,
            icon: const Icon(
              Icons.refresh,
              color: skyBlue,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),

      body: Consumer<ProductProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: skyBlue,
              ),
            );
          }

          if (provider.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.cloud_off,
                      size: 60,
                      color: skyBlue,
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Unable to load products',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      provider.error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      onPressed: _refreshProducts,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: skyBlue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final products =
              _filteredProducts(provider.products);

          return RefreshIndicator(
            color: skyBlue,
            onRefresh: _refreshProducts,
            child: ListView(
              physics:
                  const AlwaysScrollableScrollPhysics(),
              children: [
                _buildBrandHeader(),

                _buildSearchBar(),

                const SizedBox(height: 8),

                _buildCategories(),

                const SizedBox(height: 10),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.shopping_bag_outlined,
                        color: skyBlue,
                        size: 21,
                      ),
                      const SizedBox(width: 7),
                      const Text(
                        'Products',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${products.length} found',
                        style: const TextStyle(
                          color: skyBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                if (_selectedCategory != 'All')
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      5,
                      16,
                      8,
                    ),
                    child: Row(
                      children: [
                        Text(
                          _selectedCategory,
                          style: const TextStyle(
                            color: skyBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 5),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategory = 'All';
                            });
                          },
                          child: const Icon(
                            Icons.close,
                            size: 17,
                            color: skyBlue,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 5),

                products.isEmpty
                    ? _buildEmptyState()
                    : _buildProductsGrid(products),
              ],
            ),
          );
        },
      ),
    );
  }
}