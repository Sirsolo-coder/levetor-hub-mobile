import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/cart_provider.dart';
import '../providers/customer_provider.dart';
import 'about_screen.dart';
import 'account_screen.dart';
import 'cart_screen.dart';
import 'contact_screen.dart';
import 'home_screen.dart';
import 'notification_screen.dart';
import 'orders_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState
    extends State<MainNavigationScreen> {
  static const Color skyBlue =
      Color(0xFF29B6F6);

  int _selectedIndex = 0;

  int _notificationRefreshKey = 0;

  static const String whatsappNumber =
      '2349058344205';

  final List<Widget> _screens = const [
    HomeScreen(),
    AccountScreen(),
    OrdersScreen(),
    NotificationScreen(),
    CartScreen(),
  ];

  Future<void> _openWhatsApp() async {
    final Uri url = Uri.parse(
      'https://wa.me/$whatsappNumber?text=${Uri.encodeComponent(
        'Hello Levetor Hub, I would like to make an enquiry.',
      )}',
    );

    try {
      await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to open WhatsApp.',
            ),
          ),
        );
      }
    }
  }

  void _openMoreMenu() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              5,
              16,
              20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'More',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 15),

                _buildMenuItem(
                  icon: Icons.info_outline,
                  title: 'About Us',
                  subtitle:
                      'Learn more about Levetor Hub',
                  onTap: () {
                    Navigator.pop(context);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const AboutScreen(),
                      ),
                    );
                  },
                ),

                _buildMenuItem(
                  icon:
                      Icons.contact_support_outlined,
                  title: 'Contact Us',
                  subtitle:
                      'Get in touch with our team',
                  onTap: () {
                    Navigator.pop(context);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const ContactScreen(),
                      ),
                    );
                  },
                ),

                _buildMenuItem(
                  icon: Icons.chat_outlined,
                  title: 'WhatsApp',
                  subtitle:
                      'Chat with Levetor Hub',
                  onTap: () {
                    Navigator.pop(context);
                    _openWhatsApp();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 3,
      ),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: skyBlue.withValues(
            alpha: 0.10,
          ),
          borderRadius:
              BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: skyBlue,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: skyBlue,
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final customerId =
        context.watch<CustomerProvider>().customerId;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),

      floatingActionButton:
          FloatingActionButton(
        onPressed: _openMoreMenu,
        backgroundColor: skyBlue,
        foregroundColor: Colors.white,
        tooltip: 'More',
        child: const Icon(
          Icons.more_horiz,
        ),
      ),

      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar:
          Consumer<CartProvider>(
        builder: (
          context,
          cartProvider,
          child,
        ) {
          final cartCount =
              cartProvider.items.length;

          return NavigationBarTheme(
            data: NavigationBarThemeData(
              labelTextStyle:
                  const WidgetStatePropertyAll(
                TextStyle(
                  fontSize: 11,
                  fontWeight:
                      FontWeight.w500,
                ),
              ),
            ),
            child: NavigationBar(
              selectedIndex:
                  _selectedIndex,

              onDestinationSelected:
                  (index) {
                setState(() {
                  _selectedIndex =
                      index;

                  if (index == 3) {
                    _notificationRefreshKey++;
                  }
                });
              },

              destinations: [
                const NavigationDestination(
                  icon: Icon(
                    Icons.home_outlined,
                  ),
                  selectedIcon: Icon(
                    Icons.home,
                  ),
                  label: 'Home',
                ),

                const NavigationDestination(
                  icon: Icon(
                    Icons.person_outline,
                  ),
                  selectedIcon: Icon(
                    Icons.person,
                  ),
                  label: 'Account',
                ),

                const NavigationDestination(
                  icon: Icon(
                    Icons.receipt_long_outlined,
                  ),
                  selectedIcon: Icon(
                    Icons.receipt_long,
                  ),
                  label: 'Orders',
                ),

                NavigationDestination(
                  icon: NotificationNavIcon(
                    customerId: customerId,
                    refreshKey:
                        _notificationRefreshKey,
                  ),
                  selectedIcon:
                      NotificationNavIcon(
                    customerId: customerId,
                    refreshKey:
                        _notificationRefreshKey,
                  ),
                  label: 'Notifications',
                ),

                NavigationDestination(
                  icon: Badge(
                    isLabelVisible:
                        cartCount > 0,
                    label: Text(
                      '$cartCount',
                    ),
                    child: const Icon(
                      Icons
                          .shopping_cart_outlined,
                    ),
                  ),
                  selectedIcon: Badge(
                    isLabelVisible:
                        cartCount > 0,
                    label: Text(
                      '$cartCount',
                    ),
                    child: const Icon(
                      Icons.shopping_cart,
                    ),
                  ),
                  label: 'Cart',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}