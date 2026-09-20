import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import '../models/customer.dart';
import '../providers/customer_provider.dart';
import '../services/api_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;

  GoogleSignIn? _googleSignIn;

  static const String _googleWebClientId =
      '20892518320-nk2mrd1dh3n0l4uckhuh47pjpjp60hsb.apps.googleusercontent.com';

  @override
  void initState() {
    super.initState();

    _initializeGoogleSignIn();
  }

  Future<void> _initializeGoogleSignIn() async {
    try {
      final googleSignIn = GoogleSignIn.instance;

      await googleSignIn.initialize(
        serverClientId: _googleWebClientId,
      );

      _googleSignIn = googleSignIn;

      debugPrint('Google Sign-In initialized successfully.');
    } catch (e) {
      debugPrint('Google Sign-In initialization error: $e');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  // =========================================================
  // NORMAL LOGIN
  // =========================================================

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ApiService.loginCustomer(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      if (result['success'] != true) {
        throw Exception(
          result['message']?.toString() ?? 'Login failed.',
        );
      }

      final customerData = result['customer'];

      if (customerData is! Map) {
        throw Exception(
          'Invalid customer information received.',
        );
      }

      final customer = Customer.fromJson(
        Map<String, dynamic>.from(customerData),
      );

      // =====================================================
      // SAVE CUSTOMER + API TOKEN
      // =====================================================

      final apiToken = result['token']?.toString();

      if (apiToken == null || apiToken.trim().isEmpty) {
        throw Exception(
          'Login succeeded, but the authentication token was not received.',
        );
      }

      await context.read<CustomerProvider>().setCustomer(
        customer,
        apiToken: apiToken,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Welcome back, ${customer.fullname}!',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showError(
        e.toString().replaceFirst(
          'Exception: ',
          '',
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

  // =========================================================
  // GOOGLE LOGIN
  // =========================================================

  Future<void> _googleLogin() async {
    if (_isLoading || _isGoogleLoading) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isGoogleLoading = true;
    });

    try {
      final googleSignIn = _googleSignIn;

      if (googleSignIn == null) {
        throw Exception(
          'Google Sign-In is still initializing. Please try again.',
        );
      }

      // Google Sign-In was already initialized in initState().
      final account = await googleSignIn.authenticate();

      final authentication = account.authentication;

      final idToken = authentication.idToken;

      if (idToken == null || idToken.trim().isEmpty) {
        throw Exception(
          'Google did not return an authentication token.',
        );
      }

      final result = await ApiService.googleLogin(
        idToken: idToken,
      );

      if (!mounted) {
        return;
      }

      if (result['success'] != true) {
        throw Exception(
          result['message']?.toString() ??
              'Google login failed.',
        );
      }

      final customerData = result['customer'];

      if (customerData is! Map) {
        throw Exception(
          'Invalid customer information received from Google.',
        );
      }

      final customer = Customer.fromJson(
        Map<String, dynamic>.from(customerData),
      );

      // =====================================================
      // SAVE CUSTOMER + GOOGLE API TOKEN
      // =====================================================

      final apiToken = result['token']?.toString();

      if (apiToken == null || apiToken.trim().isEmpty) {
        throw Exception(
          'Google login succeeded, but the authentication token was not received.',
        );
      }

      await context.read<CustomerProvider>().setCustomer(
        customer,
        apiToken: apiToken,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Welcome, ${customer.fullname}!',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
    } on GoogleSignInException catch (e) {
      if (!mounted) {
        return;
      }

      if (e.code == GoogleSignInExceptionCode.canceled) {
        return;
      }

      _showError(
        e.description ??
            'Google Sign-In failed.',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showError(
        e.toString().replaceFirst(
          'Exception: ',
          '',
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    }
  }

// =========================================================
// FORGOT PASSWORD
// =========================================================

Future<void> _forgotPassword() async {
  final emailController = TextEditingController(
    text: _emailController.text.trim(),
  );

  bool loading = false;

  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: const Text('Forgot Password?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Enter your email address and we will send you a password reset link.',
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: emailController,
                  enabled: !loading,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(
                      Icons.email_outlined,
                    ),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: loading
                    ? null
                    : () {
                        Navigator.of(dialogContext).pop(
                          <String, dynamic>{
                            'cancelled': true,
                          },
                        );
                      },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: loading
                    ? null
                    : () async {
                        final email =
                            emailController.text.trim();

                        if (email.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please enter your email address.',
                              ),
                              behavior:
                                  SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }

                        if (_validateEmail(email) != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please enter a valid email address.',
                              ),
                              behavior:
                                  SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }

                        setDialogState(() {
                          loading = true;
                        });

                        try {
                          final response =
                              await ApiService.forgotPassword(
                            email: email,
                          );

                          if (!mounted) {
                            return;
                          }

                          final message =
                              response['message']?.toString();

                          Navigator.of(dialogContext).pop(
                            <String, dynamic>{
                              'success': true,
                              'message': message,
                            },
                          );
                        } catch (e) {
                          if (!mounted) {
                            return;
                          }

                          setDialogState(() {
                            loading = false;
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                e.toString().replaceFirst(
                                      'Exception: ',
                                      '',
                                    ),
                              ),
                              behavior:
                                  SnackBarBehavior.floating,
                              duration:
                                  const Duration(seconds: 5),
                            ),
                          );
                        }
                      },
                child: loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Send Reset Email',
                      ),
              ),
            ],
          );
        },
      );
    },
  );

  // Dispose ONLY after the dialog has completely closed.
  emailController.dispose();

  if (!mounted) {
    return;
  }

  if (result != null &&
      result['success'] == true) {
    final message =
        result['message']?.toString();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message?.isNotEmpty == true
              ? message!
              : 'Password reset instructions have been sent to your email address. Please check your inbox.',
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
  }
}

  // =========================================================
  // VALIDATION
  // =========================================================

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email.';
    }

    final emailRegex =
        RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address.';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password.';
    }

    return null;
  }

  // =========================================================
  // UI HELPERS
  // =========================================================

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final isBusy =
        _isLoading || _isGoogleLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 25),

                Icon(
                  Icons.lock_person_outlined,
                  size: 75,
                  color:
                      Theme.of(context)
                          .colorScheme
                          .primary,
                ),

                const SizedBox(height: 18),

                Text(
                  'Welcome Back',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
                        fontWeight:
                            FontWeight.bold,
                      ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Login to your Levetor Hub account.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium,
                ),

                const SizedBox(height: 35),

                TextFormField(
                  controller: _emailController,
                  keyboardType:
                      TextInputType.emailAddress,
                  decoration: _inputDecoration(
                    label: 'Email Address',
                    icon:
                        Icons.email_outlined,
                  ),
                  validator: _validateEmail,
                ),

                const SizedBox(height: 18),

                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: _inputDecoration(
                    label: 'Password',
                    icon:
                        Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword =
                              !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: _validatePassword,
                ),

                Align(
                  alignment:
                      Alignment.centerRight,
                  child: TextButton(
                    onPressed:
                        isBusy
                            ? null
                            : _forgotPassword,
                    child: const Text(
                      'Forgot Password?',
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed:
                        isBusy ? null : _login,
                    style:
                        ElevatedButton.styleFrom(
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 22),

                Row(
                  children: [
                    const Expanded(
                      child: Divider(),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 14,
                      ),
                      child: Text(
                        'OR',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                      ),
                    ),
                    const Expanded(
                      child: Divider(),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                SizedBox(
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed:
                        isBusy
                            ? null
                            : _googleLogin,

                    // =================================================
                    // GOOGLE ICON
                    // =================================================
                    icon: _isGoogleLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'G',
                            style: TextStyle(
                              fontSize: 23,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),

                    label: Text(
                      _isGoogleLoading
                          ? 'Signing in with Google...'
                          : 'Continue with Google',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),

                    style:
                        OutlinedButton.styleFrom(
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account? ",
                    ),
                    TextButton(
                      onPressed:
                          isBusy
                              ? null
                              : () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const RegisterScreen(),
                                    ),
                                  );
                                },
                      child: const Text(
                        'Create Account',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}