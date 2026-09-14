import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/customer.dart';
import '../providers/customer_provider.dart';
import '../services/api_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState
    extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _fullnameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    final customer =
        context.read<CustomerProvider>().customer;

    _fullnameController =
        TextEditingController(
      text: customer?.fullname ?? '',
    );

    _emailController =
        TextEditingController(
      text: customer?.email ?? '',
    );

    _phoneController =
        TextEditingController(
      text: customer?.phone ?? '',
    );

    _addressController =
        TextEditingController(
      text: customer?.address ?? '',
    );
  }

  @override
  void dispose() {
    _fullnameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final provider =
        context.read<CustomerProvider>();

    final customer = provider.customer;

    if (customer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please login again before editing your profile.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final Customer updatedCustomer =
          await ApiService.updateCustomer(
        customerId: customer.id,
        fullname:
            _fullnameController.text.trim(),
        email:
            _emailController.text.trim(),
        phone:
            _phoneController.text.trim(),
        address:
            _addressController.text.trim(),
      );

      await provider.setCustomer(
        updatedCustomer,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Profile updated successfully.',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) {
        return;
      }

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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 10),

                const CircleAvatar(
                  radius: 42,
                  child: Icon(
                    Icons.person,
                    size: 45,
                  ),
                ),

                const SizedBox(height: 28),

                TextFormField(
                  controller:
                      _fullnameController,
                  textInputAction:
                      TextInputAction.next,
                  decoration:
                      const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon:
                        Icon(Icons.person_outline),
                    border:
                        OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Full name is required.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller:
                      _emailController,
                  keyboardType:
                      TextInputType.emailAddress,
                  textInputAction:
                      TextInputAction.next,
                  decoration:
                      const InputDecoration(
                    labelText: 'Email',
                    prefixIcon:
                        Icon(Icons.email_outlined),
                    border:
                        OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final email =
                        value?.trim() ?? '';

                    if (email.isEmpty) {
                      return 'Email is required.';
                    }

                    if (!email.contains('@') ||
                        !email.contains('.')) {
                      return 'Enter a valid email address.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller:
                      _phoneController,
                  keyboardType:
                      TextInputType.phone,
                  textInputAction:
                      TextInputAction.next,
                  decoration:
                      const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon:
                        Icon(Icons.phone_outlined),
                    border:
                        OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Phone number is required.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller:
                      _addressController,
                  keyboardType:
                      TextInputType.streetAddress,
                  textInputAction:
                      TextInputAction.done,
                  maxLines: 3,
                  decoration:
                      const InputDecoration(
                    labelText: 'Address',
                    prefixIcon:
                        Icon(Icons.location_on_outlined),
                    border:
                        OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton.icon(
                    onPressed:
                        _isLoading
                            ? null
                            : _saveProfile,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.save_outlined,
                          ),
                    label: Text(
                      _isLoading
                          ? 'Saving...'
                          : 'Save Changes',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          Navigator.pop(context);
                        },
                  child: const Text(
                    'Cancel',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
