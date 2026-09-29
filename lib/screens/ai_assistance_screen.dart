import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../services/api_service.dart';
import 'product_details_screen.dart';

class AIAssistanceScreen extends StatefulWidget {
  const AIAssistanceScreen({super.key});

  @override
  State<AIAssistanceScreen> createState() => _AIAssistanceScreenState();
}

class _AIAssistanceScreenState extends State<AIAssistanceScreen> {
  static const Color skyBlue = Color(0xFF29B6F6);

  final TextEditingController _messageController = TextEditingController();

  final ScrollController _scrollController = ScrollController();

  final List<_ChatMessage> _messages = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _messages.add(
      const _ChatMessage(
        text:
            'Hello! 👋 I’m Levetor Hub AI Assistant. '
            'I can help you find products, compare gadgets, '
            'check availability and choose products based '
            'on your needs and budget.',
        isUser: false,
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // =========================================================
  // SEND MESSAGE
  // =========================================================

  Future<void> _sendMessage() async {
    if (_isLoading) {
      return;
    }

    final message = _messageController.text.trim();

    if (message.isEmpty) {
      return;
    }

    _messageController.clear();

    setState(() {
      _messages.add(_ChatMessage(text: message, isUser: true));

      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final result = await ApiService.askAIAssistant(message: message);

      if (!mounted) {
        return;
      }

      final response = result['message']?.toString().trim() ?? '';

      final rawProductIds = result['product_ids'];

      final List<int> productIds = [];

      if (rawProductIds is List) {
        for (final value in rawProductIds) {
          final productId = int.tryParse(value.toString());

          if (productId != null &&
              productId > 0 &&
              !productIds.contains(productId)) {
            productIds.add(productId);
          }
        }
      }

      final products = await _loadRecommendedProducts(productIds);

      if (!mounted) {
        return;
      }

      setState(() {
        _messages.add(
          _ChatMessage(
            text: response.isEmpty
                ? 'I found some information for you.'
                : response,
            isUser: false,
            products: products,
          ),
        );

        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;

        _messages.add(
          _ChatMessage(
            text:
                'Sorry, I could not process that request.\n\n'
                '${e.toString().replaceFirst('Exception: ', '')}',
            isUser: false,
            isError: true,
          ),
        );
      });

      _scrollToBottom();
    }
  }

  // =========================================================
  // LOAD AI RECOMMENDED PRODUCTS
  // =========================================================

  Future<List<Product>> _loadRecommendedProducts(List<int> productIds) async {
    if (productIds.isEmpty) {
      return [];
    }

    final List<Product> products = [];

    for (final productId in productIds) {
      try {
        final product = await ApiService.getProduct(productId);

        if (!products.any((item) => item.id == product.id)) {
          products.add(product);
        }
      } catch (_) {
        // Ignore an individual unavailable product.
        // Other AI recommendations can still be displayed.
      }
    }

    return products;
  }

  // =========================================================
  // SCROLL
  // =========================================================

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  // =========================================================
  // SUGGESTION
  // =========================================================

  void _useSuggestion(String suggestion) {
    _messageController.text = suggestion;

    setState(() {});

    _sendMessage();
  }

  // =========================================================
  // HEADER ICON
  // =========================================================

  Widget _buildHeaderIcon() {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: skyBlue,
        borderRadius: BorderRadius.circular(13),
      ),
      child: const Icon(Icons.auto_awesome, color: Colors.white, size: 23),
    );
  }

  // =========================================================
  // SUGGESTION CHIP
  // =========================================================

  Widget _buildSuggestion(String text) {
    return ActionChip(
      avatar: const Icon(Icons.auto_awesome, size: 16, color: skyBlue),
      label: Text(text),
      labelStyle: const TextStyle(color: Colors.black87, fontSize: 12),
      backgroundColor: Colors.white,
      side: BorderSide(color: skyBlue.withValues(alpha: 0.2)),
      onPressed: _isLoading ? null : () => _useSuggestion(text),
    );
  }

  // =========================================================
  // MESSAGE
  // =========================================================

  Widget _buildMessage(_ChatMessage message) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: skyBlue,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 9),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: isUser
                        ? skyBlue
                        : message.isError
                        ? Colors.red.shade50
                        : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    border: !isUser
                        ? Border.all(
                            color: message.isError
                                ? Colors.red.shade200
                                : Colors.grey.shade200,
                          )
                        : null,
                    boxShadow: !isUser
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: isUser
                          ? Colors.white
                          : message.isError
                          ? Colors.red.shade800
                          : Colors.black87,
                    ),
                  ),
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: 9),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: skyBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: skyBlue,
                    size: 20,
                  ),
                ),
              ],
            ],
          ),

          // AI PRODUCT RECOMMENDATIONS
          if (!isUser && message.products.isNotEmpty)
            _buildProductRecommendations(message.products),
        ],
      ),
    );
  }

  // =========================================================
  // PRODUCT RECOMMENDATIONS
  // =========================================================

  Widget _buildProductRecommendations(List<Product> products) {
    return Padding(
      padding: const EdgeInsets.only(left: 43, top: 10),
      child: SizedBox(
        height: 245,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: products.length,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            return _buildProductCard(products[index]);
          },
        ),
      ),
    );
  }

  // =========================================================
  // PRODUCT CARD
  // =========================================================

  Widget _buildProductCard(Product product) {
    return Container(
      width: 210,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PRODUCT IMAGE
          Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: product.image != null && product.image!.trim().isNotEmpty
                  ? Image.network(
                      ApiService.getImageUrl(product.image),
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) {
                        return const Icon(
                          Icons.devices_other,
                          color: skyBlue,
                          size: 40,
                        );
                      },
                    )
                  : const Icon(Icons.devices_other, color: skyBlue, size: 40),
            ),
          ),

          const SizedBox(height: 8),

          // PRODUCT NAME
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 4),

          // PRICE
          Text(
            '₦${_formatPrice(product.price)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: skyBlue,
            ),
          ),

          const Spacer(),

          // ACTIONS
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductDetailsScreen(product: product),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: skyBlue,
                    side: const BorderSide(color: skyBlue),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minimumSize: const Size(0, 36),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'View',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ElevatedButton(
                  onPressed: product.stock <= 0
                      ? null
                      : () {
                          context.read<CartProvider>().addToCart(product);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${product.name} added to cart.'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: skyBlue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade600,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minimumSize: const Size(0, 36),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    product.stock <= 0 ? 'Out' : 'Add',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================
  // PRICE FORMAT
  // =========================================================

  String _formatPrice(double price) {
    final formatted = price.toStringAsFixed(2);

    final parts = formatted.split('.');

    final wholePart = parts[0];

    final buffer = StringBuffer();

    for (int i = 0; i < wholePart.length; i++) {
      if (i > 0 && (wholePart.length - i) % 3 == 0) {
        buffer.write(',');
      }

      buffer.write(wholePart[i]);
    }

    return '${buffer.toString()}.${parts[1]}';
  }

  // =========================================================
  // LOADING MESSAGE
  // =========================================================

  Widget _buildLoadingMessage() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: skyBlue,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 9),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const SizedBox(
              width: 45,
              height: 18,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [_LoadingDot(), _LoadingDot(), _LoadingDot()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // INPUT AREA
  // =========================================================

  Widget _buildInputArea() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                enabled: !_isLoading,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'Ask about phones, computers, gadgets...',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(18)),
                    borderSide: BorderSide(color: skyBlue, width: 1.5),
                  ),
                ),
                onSubmitted: (_) {
                  _sendMessage();
                },
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _isLoading ? Colors.grey.shade300 : skyBlue,
                borderRadius: BorderRadius.circular(16),
              ),
              child: IconButton(
                tooltip: 'Send',
                onPressed: _isLoading ? null : _sendMessage,
                icon: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 21,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        titleSpacing: 8,
        title: Row(
          children: [
            _buildHeaderIcon(),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Assistant',
                  style: TextStyle(
                    color: skyBlue,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Levetor Hub',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.only(top: 10, bottom: 10),
              children: [
                if (_messages.length == 1)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildSuggestion('Phones under ₦300,000'),
                        _buildSuggestion('Recommend a computer'),
                        _buildSuggestion('What is in stock?'),
                        _buildSuggestion('Compare two gadgets'),
                        _buildSuggestion('Find a tablet'),
                        _buildSuggestion('What are the latest smartphones?'),
                        _buildSuggestion(
                          'What is the best laptop for programming?',
                        ),
                        _buildSuggestion(
                          'What is the best computer for gaming?',
                        ),
                        _buildSuggestion(
                          'What is the best computer for graphics design?',
                        ),
                        _buildSuggestion(
                          'What is the best computer for students?',
                        ),
                      ],
                    ),
                  ),
                ..._messages.map(_buildMessage),
                if (_isLoading) _buildLoadingMessage(),
              ],
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }
}

// =========================================================
// CHAT MESSAGE MODEL
// =========================================================

class _ChatMessage {
  final String text;
  final bool isUser;
  final bool isError;
  final List<Product> products;

  const _ChatMessage({
    required this.text,
    required this.isUser,
    this.isError = false,
    this.products = const [],
  });
}

// =========================================================
// LOADING DOT
// =========================================================

class _LoadingDot extends StatelessWidget {
  const _LoadingDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: const BoxDecoration(
        color: Color(0xFF29B6F6),
        shape: BoxShape.circle,
      ),
    );
  }
}
