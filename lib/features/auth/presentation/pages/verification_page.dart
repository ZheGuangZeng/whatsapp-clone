import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_providers.dart';
import '../providers/auth_state.dart';
import '../widgets/auth_button.dart';
import '../widgets/otp_input_field.dart';

/// Verification page for OTP verification
class VerificationPage extends ConsumerStatefulWidget {
  const VerificationPage({
    super.key,
    this.email,
    this.phone,
  });

  final String? email;
  final String? phone;

  @override
  ConsumerState<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends ConsumerState<VerificationPage> {
  final _otpController = TextEditingController();
  Timer? _timer;
  int _remainingSeconds = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _canResend = false;
    _remainingSeconds = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        setState(() => _canResend = true);
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final authNotifier = ref.read(authNotifierProvider.notifier);

    // Listen to auth state changes
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      switch (next) {
        case AuthenticatedState():
          context.go('/home');
          break;
        case ErrorState(:final message):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.red,
            ),
          );
          break;
        default:
          break;
      }
    });

    final isEmail = widget.email != null;
    final contact = widget.email ?? widget.phone ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Verification Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_outlined,
                  size: 50,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                'Verify Your ${isEmail ? 'Email' : 'Phone'}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Description
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                  children: [
                    const TextSpan(
                      text: 'We sent a verification code to\n',
                    ),
                    TextSpan(
                      text: contact,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // OTP Input
              OtpInputField(
                controller: _otpController,
                onChanged: (value) {
                  if (value.length == 6) {
                    _handleVerification(authNotifier);
                  }
                },
              ),
              const SizedBox(height: 24),

              // Verify Button
              AuthButton(
                text: 'Verify Code',
                isLoading: authState.isLoading,
                onPressed: () => _handleVerification(authNotifier),
              ),
              const SizedBox(height: 24),

              // Resend Code
              if (!_canResend)
                Text(
                  'Resend code in $_remainingSeconds seconds',
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                )
              else
                TextButton(
                  onPressed: () => _handleResend(),
                  child: const Text(
                    'Resend verification code',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              const SizedBox(height: 16),

              // Change email/phone option
              TextButton(
                onPressed: () => context.pop(),
                child: Text(
                  'Change ${isEmail ? 'email address' : 'phone number'}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleVerification(authNotifier) {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 6-digit code'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (widget.email != null) {
      authNotifier.verifyEmail(
        email: widget.email!,
        otp: otp,
      );
    } else if (widget.phone != null) {
      // For phone verification, we would call verifyPhone method
      // authNotifier.verifyPhone(phone: widget.phone!, otp: otp);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone verification not yet implemented'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _handleResend() {
    if (widget.email != null) {
      // Resend email verification
      ref.read(authRepositoryProvider).sendEmailVerification(
        email: widget.email!,
      );
    } else if (widget.phone != null) {
      // Resend phone verification
      ref.read(authRepositoryProvider).sendPhoneVerification(
        phone: widget.phone!,
      );
    }

    _startTimer();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Verification code sent!'),
        backgroundColor: Colors.green,
      ),
    );
  }
}