// email_screen.dart
// First step of OTP auth: user enters their email and taps "Send Code".
// Works for both new and returning users — no separate register flow needed.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../theme/crayon_theme.dart';

class EmailScreen extends StatefulWidget {
  const EmailScreen({super.key});

  @override
  State<EmailScreen> createState() => _EmailScreenState();
}

class _EmailScreenState extends State<EmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _authService = AuthService();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final email = _emailController.text.trim();
      await _authService.sendOtp(email);
      if (mounted) context.go('/verify', extra: email);
    } catch (e) {
      setState(() => _error = 'Could not send code. Check the email and try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Closer',
                  style: GoogleFonts.caveat(
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    color: CrayonColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage relationships with clarity.',
                  style: GoogleFonts.caveat(
                    color: CrayonColors.textSecondary,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 48),
                Text(
                  'Enter your email to sign in or create an account.',
                  style: GoogleFonts.caveat(fontSize: 18, color: CrayonColors.textPrimary),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                  ),
                  validator: (v) =>
                      v == null || !v.contains('@') ? 'Enter a valid email' : null,
                  onFieldSubmitted: (_) => _sendCode(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: GoogleFonts.caveat(
                      color: CrayonColors.scoreNegative2,
                      fontSize: 16,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _loading ? null : _sendCode,
                  child: _loading
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Send Code'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
