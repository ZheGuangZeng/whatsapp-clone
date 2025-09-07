import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_providers.dart';
import '../providers/auth_state.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_text_field.dart';

/// Forgot password page for requesting password reset
class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authNotifier = ref.read(authNotifierProvider.notifier);

    // Listen to auth state changes for error handling
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next is ErrorState) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                
                // Icon and title
                const Icon(
                  Icons.lock_reset,
                  size: 80,
                  color: Colors.green,
                ),
                const SizedBox(height: 24),
                
                Text(
                  _emailSent ? 'Check Your Email' : 'Forgot Your Password?',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                
                Text(
                  _emailSent 
                    ? 'We\'ve sent a password reset link to ${_emailController.text.trim()}'
                    : 'Enter your email address and we\'ll send you a link to reset your password.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                if (!_emailSent) ...[
                  // Email Input
                  AuthTextField(
                    controller: _emailController,
                    hintText: 'Email address',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 24),

                  // Send Reset Link Button
                  AuthButton(
                    text: 'Send Reset Link',
                    isLoading: _isLoading,
                    onPressed: () => _handleSendResetLink(authNotifier),
                  ),
                ] else ...[
                  // Success state buttons
                  AuthButton(
                    text: 'Resend Email',
                    onPressed: () => _handleSendResetLink(authNotifier),
                  ),
                  const SizedBox(height: 16),
                  
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Back to Sign In'),
                  ),
                ],
                
                const SizedBox(height: 24),

                // Back to Login Link (only show if email not sent)
                if (!_emailSent)
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Back to Sign In'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email address';
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  Future<void> _handleSendResetLink(dynamic authNotifier) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await authNotifier.sendPasswordReset(email: _emailController.text.trim());
      
      // If no error was thrown, consider it successful
      setState(() {
        _isLoading = false;
        _emailSent = true;
      });
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset email sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      setState(() => _isLoading = false);
      // Error will be handled by the auth state listener
    }
  }
}