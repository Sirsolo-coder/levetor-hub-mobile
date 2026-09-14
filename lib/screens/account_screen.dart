// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/customer.dart';
import '../providers/customer_provider.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'orders_screen.dart';
import 'edit_profile_screen.dart';
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CustomerProvider>(
      builder: (context, provider, child) {
        final customer = provider.customer;

        if (!provider.isLoggedIn || customer == null) {
          return _buildGuestAccount(context);
        }

        return _buildLoggedInAccount(
          context,
          provider,
          customer,
        );
      },
    );
  }

  // ============================================================
  // GUEST ACCOUNT
  // ============================================================

  Widget _buildGuestAccount(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Account'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(
                  Icons.account_circle_outlined,
                  size: 100,
                  color: Theme.of(context)
                      .colorScheme
                      .primary,
                ),

                const SizedBox(height: 20),

                Text(
                  'Welcome to Levetor Hub',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),

                const SizedBox(height: 10),

                Text(
                  'Login or create an account to manage '
                  'your orders and personal information.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium,
                ),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const LoginScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.login),
                    label: const Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const RegisterScreen(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.person_add_alt_1,
                    ),
                    label: const Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LOGGED-IN ACCOUNT
  // ============================================================

  Widget _buildLoggedInAccount(
    BuildContext context,
    CustomerProvider provider,
    Customer customer,
  ) {
    final initials = _getInitials(customer.fullname);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Account'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Edit Profile',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              _showEditProfile(context, provider, customer);
            },
          ),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 10),

              CircleAvatar(
                radius: 48,
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                customer.fullname.isEmpty
                    ? 'Customer'
                    : customer.fullname,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),

              const SizedBox(height: 6),

              Text(
                customer.email,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                'Welcome back to Levetor Hub!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 28),

              _accountInfoTile(
                context,
                icon: Icons.person_outline,
                title: 'Full Name',
                value: customer.fullname,
              ),

              _accountInfoTile(
                context,
                icon: Icons.email_outlined,
                title: 'Email',
                value: customer.email,
              ),

              _accountInfoTile(
                context,
                icon: Icons.phone_outlined,
                title: 'Phone',
                value: customer.phone,
              ),

              _accountInfoTile(
                context,
                icon: Icons.location_on_outlined,
                title: 'Address',
                value: customer.address.isEmpty
                    ? 'No address provided'
                    : customer.address,
              ),

              const SizedBox(height: 12),

              // =================================================
              // EDIT DETAILS
              // =================================================

              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.edit_outlined,
                  ),
                  title: const Text(
                    'Edit Details',
                  ),
                  subtitle: const Text(
                    'Update your personal information',
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                  ),
                  onTap: () {
                    _showEditProfile(
                      context,
                      provider,
                      customer,
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

Card(
  child: ListTile(
    leading: const Icon(
      Icons.edit_outlined,
    ),
    title: const Text('Edit Profile'),
    subtitle: const Text(
      'Update your personal information',
    ),
    trailing: const Icon(
      Icons.chevron_right,
    ),
    onTap: () async {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const EditProfileScreen(),
        ),
      );
    },
  ),
),

const SizedBox(height: 12),
              // =================================================
              // MY ORDERS
              // =================================================

              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.receipt_long_outlined,
                  ),
                  title: const Text(
                    'My Orders',
                  ),
                  subtitle: const Text(
                    'View your previous orders',
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const OrdersScreen(),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // =================================================
              // LOGOUT
              // =================================================

              Card(
                child: ListTile(
                  leading: Icon(
                    Icons.logout,
                    color: Theme.of(context)
                        .colorScheme
                        .error,
                  ),
                  title: const Text(
                    'Logout',
                  ),
                  subtitle: const Text(
                    'Sign out of your account',
                  ),
                  onTap: () async {
                    final shouldLogout =
                        await _showLogoutDialog(context);

                    if (shouldLogout != true) {
                      return;
                    }

                    if (!context.mounted) {
                      return;
                    }

                    await provider.clearCustomer();

                    if (!context.mounted) {
                      return;
                    }

                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      const SnackBar(
                        content: Text(
                          'You have been logged out.',
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ACCOUNT INFORMATION TILE
  // ============================================================

  Widget _accountInfoTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          value.isEmpty
              ? 'Not provided'
              : value,
        ),
      ),
    );
  }

  // ============================================================
  // EDIT PROFILE
  // ============================================================

  void _showEditProfile(
    BuildContext context,
    CustomerProvider provider,
    Customer customer,
  ) {
    final fullnameController =
        TextEditingController(
      text: customer.fullname,
    );

    final emailController =
        TextEditingController(
      text: customer.email,
    );

    final phoneController =
        TextEditingController(
      text: customer.phone,
    );

    final addressController =
        TextEditingController(
      text: customer.address,
    );

    bool saving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            dialogContext,
            setDialogState,
          ) {
            return AlertDialog(
              title: const Text(
                'Edit Details',
              ),

              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: fullnameController,
                      enabled: !saving,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(
                          Icons.person_outline,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    TextField(
                      controller: emailController,
                      enabled: !saving,
                      keyboardType:
                          TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(
                          Icons.email_outlined,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    TextField(
                      controller: phoneController,
                      enabled: !saving,
                      keyboardType:
                          TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        prefixIcon: Icon(
                          Icons.phone_outlined,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    TextField(
                      controller: addressController,
                      enabled: !saving,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        prefixIcon: Icon(
                          Icons.location_on_outlined,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () {
                          Navigator.pop(
                            dialogContext,
                          );
                        },
                  child: const Text(
                    'Cancel',
                  ),
                ),

                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final fullname =
                              fullnameController
                                  .text
                                  .trim();

                          final email =
                              emailController
                                  .text
                                  .trim();

                          final phone =
                              phoneController
                                  .text
                                  .trim();

                          final address =
                              addressController
                                  .text
                                  .trim();

                          if (fullname.isEmpty ||
                              email.isEmpty ||
                              phone.isEmpty) {
                            ScaffoldMessenger.of(
                              dialogContext,
                            ).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Full name, email and phone are required.',
                                ),
                              ),
                            );
                            return;
                          }

                          setDialogState(() {
                            saving = true;
                          });

                          try {
                            final updatedCustomer =
                                await ApiService
                                    .updateCustomer(
                              customerId:
                                  customer.id,
                              fullname: fullname,
                              email: email,
                              phone: phone,
                              address: address,
                            );

                            await provider
                                .setCustomer(
                              updatedCustomer,
                            );

                            if (!dialogContext
                                .mounted) {
                              return;
                            }

                            Navigator.pop(
                              dialogContext,
                            );

                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Your profile has been updated successfully.',
                                ),
                              ),
                            );
                          } catch (e) {
                            if (!dialogContext
                                .mounted) {
                              return;
                            }

                            setDialogState(() {
                              saving = false;
                            });

                            ScaffoldMessenger.of(
                              dialogContext,
                            ).showSnackBar(
                              SnackBar(
                                content: Text(
                                  e.toString()
                                      .replaceFirst(
                                    'Exception: ',
                                    '',
                                  ),
                                ),
                              ),
                            );
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Save',
                        ),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      fullnameController.dispose();
      emailController.dispose();
      phoneController.dispose();
      addressController.dispose();
    });
  }

  // ============================================================
  // INITIALS
  // ============================================================

  String _getInitials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where(
          (part) => part.isNotEmpty,
        )
        .toList();

    if (parts.isEmpty) {
      return 'LH';
    }

    if (parts.length == 1) {
      final word = parts.first;

      return word
          .substring(
            0,
            word.length >= 2 ? 2 : 1,
          )
          .toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'
        .toUpperCase();
  }

  // ============================================================
  // LOGOUT CONFIRMATION
  // ============================================================

  Future<bool?> _showLogoutDialog(
    BuildContext context,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Logout',
          ),
          content: const Text(
            'Are you sure you want to logout?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text(
                'Logout',
              ),
            ),
          ],
        );
      },
    );
  }
}
