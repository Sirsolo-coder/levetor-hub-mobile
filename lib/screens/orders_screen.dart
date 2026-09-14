import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../providers/customer_provider.dart';
import '../services/api_service.dart';

class OrdersScreen extends StatefulWidget {
  final int? initialOrderId;

  const OrdersScreen({
    super.key,
    this.initialOrderId,
  });

  @override
  State<OrdersScreen> createState() =>
      _OrdersScreenState();
}

class _OrdersScreenState
    extends State<OrdersScreen> {
  Future<List<Order>>? _ordersFuture;

  int? _lastCustomerId;

  bool _didOpenInitialOrder = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        _loadOrders();
      },
    );
  }

  // =========================================================
  // LOAD ORDERS
  // =========================================================

  void _loadOrders() {
    final customerId =
        context.read<CustomerProvider>().customerId;

    if (customerId == null) {
      if (!mounted) {
        return;
      }

      setState(() {
        _ordersFuture = Future.value([]);
        _lastCustomerId = null;
      });

      return;
    }

    if (_lastCustomerId != customerId) {
      _didOpenInitialOrder = false;
    }

    _lastCustomerId = customerId;

    setState(() {
      _ordersFuture =
          ApiService.getOrders(customerId);
    });
  }

  Future<void> _refreshOrders() async {
    final customerId =
        context.read<CustomerProvider>().customerId;

    if (customerId == null) {
      return;
    }

    final future =
        ApiService.getOrders(customerId);

    setState(() {
      _ordersFuture = future;
      _lastCustomerId = customerId;
    });

    await future;
  }

  // =========================================================
  // WATCH CUSTOMER LOGIN STATE
  // =========================================================

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final customerId =
        context.watch<CustomerProvider>().customerId;

    if (customerId != _lastCustomerId) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) {
          if (!mounted) {
            return;
          }

          _loadOrders();
        },
      );
    }
  }

  // =========================================================
  // OPEN ORDER FROM NOTIFICATION
  // =========================================================

  void _openInitialOrderIfAvailable(
    List<Order> orders,
  ) {
    final targetOrderId =
        widget.initialOrderId;

    if (targetOrderId == null ||
        _didOpenInitialOrder) {
      return;
    }

    _didOpenInitialOrder = true;

    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        if (!mounted) {
          return;
        }

        Order? targetOrder;

        for (final order in orders) {
          if (order.id == targetOrderId) {
            targetOrder = order;
            break;
          }
        }

        if (targetOrder != null) {
          _showOrderDetails(targetOrder);
        } else {
          ScaffoldMessenger.of(context)
              .showSnackBar(
            SnackBar(
              content: Text(
                'Order #$targetOrderId could not be found.',
              ),
            ),
          );
        }
      },
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final customerId =
        context.watch<CustomerProvider>().customerId;

    if (customerId != _lastCustomerId) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) {
          if (mounted) {
            _loadOrders();
          }
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Orders',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh orders',
            onPressed: _refreshOrders,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _ordersFuture == null
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : FutureBuilder<List<Order>>(
              future: _ordersFuture,
              builder: (
                context,
                snapshot,
              ) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child:
                        CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return _buildError(
                    snapshot.error.toString(),
                  );
                }

                final orders =
                    snapshot.data ?? [];

                if (orders.isNotEmpty) {
                  _openInitialOrderIfAvailable(
                    orders,
                  );
                }

                if (orders.isEmpty) {
                  return RefreshIndicator(
                    onRefresh:
                        _refreshOrders,
                    child: ListView(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height:
                              MediaQuery.of(context)
                                      .size
                                      .height *
                                  0.25,
                        ),
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 90,
                          color:
                              Colors.grey.shade400,
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        const Center(
                          child: Text(
                            'No Orders Yet',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Center(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 30,
                            ),
                            child: Text(
                              'Your orders will appear here.',
                              textAlign:
                                  TextAlign.center,
                              style: TextStyle(
                                color:
                                    Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh:
                      _refreshOrders,
                  child: ListView.builder(
                    padding:
                        const EdgeInsets.all(16),
                    itemCount:
                        orders.length,
                    itemBuilder: (
                      context,
                      index,
                    ) {
                      final order =
                          orders[index];

                      return _buildOrderCard(
                        order,
                      );
                    },
                  ),
                );
              },
            ),
    );
  }

  // =========================================================
  // ORDER CARD
  // =========================================================

  Widget _buildOrderCard(
    Order order,
  ) {
    return Card(
      elevation: 2,
      margin:
          const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(12),
        onTap: () {
          _showOrderDetails(order);
        },
        child: Padding(
          padding:
              const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${order.id}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  _statusChip(
                    order.orderStatus,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              if (order.createdAt != null &&
                  order.createdAt!.isNotEmpty)
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 17,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(
                        order.createdAt!,
                      ),
                      style: TextStyle(
                        color:
                            Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 10),

              Row(
                children: [
                  const Icon(
                    Icons.shopping_bag_outlined,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${order.items.length} '
                    '${order.items.length == 1 ? 'item' : 'items'}',
                  ),
                ],
              ),

              const SizedBox(height: 12),

              const Divider(),

              const SizedBox(height: 8),

              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '₦${order.totalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Payment',
                        style: TextStyle(
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        order.paymentStatus,
                        style: const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 10),

              const Align(
                alignment:
                    Alignment.centerRight,
                child: Row(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    Text(
                      'View Details',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // STATUS CHIP
  // =========================================================

  Widget _statusChip(
    String status,
  ) {
    final normalized =
        status.trim().toLowerCase();

    Color color;

    if (normalized.contains('deliver')) {
      color = Colors.green;
    } else if (normalized.contains('cancel')) {
      color = Colors.red;
    } else if (normalized.contains('process') ||
        normalized.contains('ship')) {
      color = Colors.orange;
    } else {
      color = Colors.blue;
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.12,
        ),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight:
              FontWeight.bold,
        ),
      ),
    );
  }

  // =========================================================
  // ORDER DETAILS
  // =========================================================

  void _showOrderDetails(
    Order order,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(
              20,
              10,
              20,
              30,
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #${order.id}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                ...order.items.map(
                  (item) {
                    return Padding(
                      padding:
                          const EdgeInsets.only(
                        bottom: 12,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${item.name} × ${item.quantity}',
                            ),
                          ),
                          Text(
                            '₦${(item.price * item.quantity).toStringAsFixed(0)}',
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
                      MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    Text(
                      '₦${order.totalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Payment Status',
                    ),
                    Text(
                      order.paymentStatus,
                      style: const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Order Status',
                    ),
                    Text(
                      order.orderStatus,
                      style: const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =========================================================
  // ERROR
  // =========================================================

  Widget _buildError(
    String error,
  ) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 70,
              color: Colors.red,
            ),

            const SizedBox(height: 16),

            const Text(
              'Unable to load orders',
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              error,
              textAlign:
                  TextAlign.center,
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed:
                  _loadOrders,
              icon: const Icon(
                Icons.refresh,
              ),
              label:
                  const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // DATE
  // =========================================================

  String _formatDate(
    String value,
  ) {
    try {
      final date =
          DateTime.parse(value);

      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    } catch (_) {
      return value;
    }
  }
}