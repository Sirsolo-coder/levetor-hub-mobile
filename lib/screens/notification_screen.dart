import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/customer_provider.dart';
import '../services/api_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({
    super.key,
  });

  @override
  State<NotificationScreen> createState() =>
      _NotificationScreenState();
}

class _NotificationScreenState
    extends State<NotificationScreen> {
  bool _isLoading = true;
  bool _isMarkingAllRead = false;

  List<Map<String, dynamic>> _notifications = [];

  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        _loadNotifications();
      },
    );
  }

  Future<void> _loadNotifications() async {
    final customerId =
        context.read<CustomerProvider>().customerId;

    if (customerId == null) {
      if (!mounted) {
        return;
      }

      setState(() {
        _notifications = [];
        _unreadCount = 0;
        _isLoading = false;
      });

      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final result =
          await ApiService.getNotifications(
        customerId,
      );

      final dynamic rawNotifications =
          result['notifications'];

      final notifications = <Map<String, dynamic>>[];

      if (rawNotifications is List) {
        for (final item in rawNotifications) {
          if (item is Map) {
            notifications.add(
              Map<String, dynamic>.from(item),
            );
          }
        }
      }

      int unread = 0;

      final dynamic rawUnread =
          result['unread_count'];

      if (rawUnread is int) {
        unread = rawUnread;
      } else if (rawUnread is num) {
        unread = rawUnread.toInt();
      } else {
        for (final notification
            in notifications) {
          if (notification['is_read'] != true) {
            unread++;
          }
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _notifications = notifications;
        _unreadCount = unread;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _markAsRead(
    Map<String, dynamic> notification,
  ) async {
    if (notification['is_read'] == true) {
      return;
    }

    final customerId =
        context.read<CustomerProvider>().customerId;

    final dynamic rawId =
        notification['id'];

    if (customerId == null || rawId == null) {
      return;
    }

    final int? notificationId =
        int.tryParse(rawId.toString());

    if (notificationId == null) {
      return;
    }

    final success =
        await ApiService.markNotificationAsRead(
      customerId: customerId,
      notificationId: notificationId,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      setState(() {
        notification['is_read'] = true;

        if (_unreadCount > 0) {
          _unreadCount--;
        }
      });
    }
  }

  Future<void> _markAllAsRead() async {
    final customerId =
        context.read<CustomerProvider>().customerId;

    if (customerId == null ||
        _unreadCount == 0 ||
        _isMarkingAllRead) {
      return;
    }

    setState(() {
      _isMarkingAllRead = true;
    });

    try {
      final success =
          await ApiService.markAllNotificationsAsRead(
        customerId,
      );

      if (!mounted) {
        return;
      }

      if (success) {
        setState(() {
          for (final notification
              in _notifications) {
            notification['is_read'] = true;
          }

          _unreadCount = 0;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isMarkingAllRead = false;
        });
      }
    }
  }

  Color _notificationIconColor(
    String type,
  ) {
    switch (type) {
      case 'order_created':
        return Colors.blue;

      case 'payment_success':
        return Colors.green;

      case 'order_status':
        return Colors.orange;

      default:
        return const Color(
          0xFF29B6F6,
        );
    }
  }

  IconData _notificationIcon(
    String type,
  ) {
    switch (type) {
      case 'order_created':
        return Icons.shopping_bag_outlined;

      case 'payment_success':
        return Icons.payment_outlined;

      case 'order_status':
        return Icons.local_shipping_outlined;

      default:
        return Icons.notifications_outlined;
    }
  }

  String _formatDate(
    dynamic value,
  ) {
    if (value == null) {
      return '';
    }

    final raw = value.toString().trim();

    if (raw.isEmpty) {
      return '';
    }

    DateTime? date =
        DateTime.tryParse(raw);

    if (date == null) {
      return raw;
    }

    final now = DateTime.now();

    final difference =
        now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours} hr ago';
    }

    if (difference.inDays == 1) {
      return 'Yesterday';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    }

    final day =
        date.day.toString().padLeft(2, '0');

    final month =
        date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final customerProvider =
        context.watch<CustomerProvider>();

    final customerId =
        customerProvider.customerId;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed:
                  _isMarkingAllRead
                      ? null
                      : _markAllAsRead,
              child: Text(
                _isMarkingAllRead
                    ? 'Marking...'
                    : 'Mark all read',
              ),
            ),
        ],
      ),
      body: customerId == null
          ? _buildLoginMessage()
          : _isLoading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : _notifications.isEmpty
                  ? RefreshIndicator(
                      onRefresh: _loadNotifications,
                      child: ListView(
                        physics:
                            const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height:
                                MediaQuery.of(context)
                                    .size
                                    .height *
                                0.22,
                          ),
                          const Icon(
                            Icons.notifications_none,
                            size: 65,
                          ),
                          const SizedBox(
                            height: 14,
                          ),
                          const Center(
                            child: Text(
                              'No notifications yet',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 8,
                          ),
                          Center(
                            child: Text(
                              'Your Levetor Hub updates will appear here.',
                              textAlign:
                                  TextAlign.center,
                              style: TextStyle(
                                color:
                                    Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh:
                          _loadNotifications,
                      child: ListView.separated(
                        padding:
                            const EdgeInsets.fromLTRB(
                          12,
                          12,
                          12,
                          24,
                        ),
                        itemCount:
                            _notifications.length,
                        separatorBuilder:
                            (_, __) =>
                                const SizedBox(
                          height: 8,
                        ),
                        itemBuilder:
                            (context, index) {
                          final notification =
                              _notifications[index];

                          final title =
                              notification['title']
                                      ?.toString() ??
                                  'Levetor Hub';

                          final body =
                              notification['body']
                                      ?.toString() ??
                                  '';

                          final type =
                              notification[
                                          'notification_type']
                                      ?.toString() ??
                                  'general';

                          final isRead =
                              notification['is_read'] ==
                                  true;

                          final iconColor =
                              _notificationIconColor(
                            type,
                          );

                          return Card(
                            elevation:
                                isRead ? 0.5 : 2,
                            color: isRead
                                ? Colors.white
                                : iconColor.withValues(
                                    alpha: 0.06,
                                  ),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                16,
                              ),
                            ),
                            child: InkWell(
                              borderRadius:
                                  BorderRadius.circular(
                                16,
                              ),
                              onTap: () =>
                                  _markAsRead(
                                notification,
                              ),
                              child: Padding(
                                padding:
                                    const EdgeInsets.all(
                                  14,
                                ),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration:
                                          BoxDecoration(
                                        color:
                                            iconColor.withValues(
                                          alpha: 0.12,
                                        ),
                                        shape:
                                            BoxShape.circle,
                                      ),
                                      child: Icon(
                                        _notificationIcon(
                                          type,
                                        ),
                                        color:
                                            iconColor,
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 12,
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment
                                                    .start,
                                            children: [
                                              Expanded(
                                                child:
                                                    Text(
                                                  title,
                                                  style:
                                                      TextStyle(
                                                    fontSize:
                                                        16,
                                                    fontWeight:
                                                        isRead
                                                            ? FontWeight.w600
                                                            : FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              if (!isRead)
                                                Container(
                                                  width:
                                                      9,
                                                  height:
                                                      9,
                                                  margin:
                                                      const EdgeInsets.only(
                                                    left:
                                                        8,
                                                    top:
                                                        6,
                                                  ),
                                                  decoration:
                                                      BoxDecoration(
                                                    color:
                                                        iconColor,
                                                    shape:
                                                        BoxShape.circle,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(
                                            height: 6,
                                          ),
                                          Text(
                                            body,
                                            style:
                                                TextStyle(
                                              fontSize: 14,
                                              color:
                                                  Colors.grey.shade700,
                                              height:
                                                  1.4,
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 8,
                                          ),
                                          Text(
                                            _formatDate(
                                              notification[
                                                  'created_at'],
                                            ),
                                            style:
                                                TextStyle(
                                              fontSize:
                                                  12,
                                              color:
                                                  Colors.grey.shade500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _buildLoginMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.notifications_none,
              size: 80,
            ),
            const SizedBox(
              height: 18,
            ),
            const Text(
              'Login to view notifications',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              'Your order, payment and delivery updates will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// =========================================================
// NOTIFICATION NAVIGATION BADGE
// =========================================================

class NotificationNavIcon extends StatefulWidget {
  final int? customerId;
  final int refreshKey;

  const NotificationNavIcon({
    super.key,
    required this.customerId,
    required this.refreshKey,
  });

  @override
  State<NotificationNavIcon> createState() =>
      _NotificationNavIconState();
}

class _NotificationNavIconState
    extends State<NotificationNavIcon> {
  Timer? _timer;

  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();

    _loadUnreadCount();

    _timer = Timer.periodic(
      const Duration(seconds: 15),
      (_) {
        _loadUnreadCount();
      },
    );
  }

  @override
  void didUpdateWidget(
    covariant NotificationNavIcon oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.customerId !=
            widget.customerId ||
        oldWidget.refreshKey !=
            widget.refreshKey) {
      _loadUnreadCount();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadUnreadCount() async {
    final customerId =
        widget.customerId;

    if (customerId == null) {
      if (mounted && _unreadCount != 0) {
        setState(() {
          _unreadCount = 0;
        });
      }

      return;
    }

    try {
      final result =
          await ApiService.getNotifications(
        customerId,
      );

      final dynamic raw =
          result['unread_count'];

      int count = 0;

      if (raw is int) {
        count = raw;
      } else if (raw is num) {
        count = raw.toInt();
      }

      if (mounted) {
        setState(() {
          _unreadCount = count;
        });
      }
    } catch (_) {
      // Keep the current badge count if the server
      // is temporarily unreachable.
    }
  }

  @override
  Widget build(BuildContext context) {
    final showBadge =
        _unreadCount > 0;

    return Badge(
      isLabelVisible: showBadge,
      label: Text(
        _unreadCount > 99
            ? '99+'
            : '$_unreadCount',
      ),
      child: const Icon(
        Icons.notifications_outlined,
      ),
    );
  }
}