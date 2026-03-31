// otp_screen.dart
// Second step of OTP auth: user enters the 6-digit code sent to their email.
// On success, checks if they have a profile; new users are sent to setup_name_screen.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../theme/crayon_theme.dart';

class OtpScreen extends StatefulWidget {
  final String email;
  const OtpScreen({super.key, required this.email});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();
  final _authService = AuthService();
  bool _loading = false;
  bool _resending = false;
  String? _error;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final token = _otpController.text.trim();
    if (token.length != 6) {
      setState(() => _error = 'Enter the 6-digit code.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await _authService.verifyOtp(email: widget.email, token: token);
      if (!mounted) return;
      final hasProfile = await _authService.hasProfile();
      if (mounted) {
        context.go(hasProfile ? '/home' : '/setup-name');
      }
    } catch (e) {
      setState(() => _error = 'Invalid or expired code. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    setState(() { _resending = true; _error = null; });
    try {
      await _authService.sendOtp(widget.email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New code sent!')),
        );
      }
    } catch (_) {
      setState(() => _error = 'Failed to resend. Try again.');
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/login')),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Check your email',
                style: GoogleFonts.caveat(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: CrayonColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We sent a 6-digit code to\n${widget.email}',
                style: GoogleFonts.caveat(
                  color: CrayonColors.textSecondary,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 36),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                autofocus: true,
                textAlign: TextAlign.center,
                style: GoogleFonts.caveat(
                  fontSize: 32,
                  letterSpacing: 10,
                  fontWeight: FontWeight.w700,
                  color: CrayonColors.textPrimary,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '------',
                  hintStyle: GoogleFonts.caveat(
                    letterSpacing: 10,
                    color: CrayonColors.textHint,
                    fontSize: 32,
                  ),
                ),
                onChanged: (v) {
                  if (v.length == 6) _verify();
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: GoogleFonts.caveat(
                    color: CrayonColors.scoreNegative2,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : _verify,
                child: _loading
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Verify'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _resending ? null : _resend,
                child: _resending
                    ? const Text('Sending...')
                    : const Text('Didn\'t receive it? Resend'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
