// auth_service.dart
// Handles authentication via Supabase email OTP (no password).
// Flow: sendOtp(email) → verifyOtp(email, token) → ensureProfile(displayName)

import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Sends a 6-digit OTP to the given email. Works for both new and existing users.
  Future<void> sendOtp(String email) async {
    await _client.auth.signInWithOtp(
      email: email,
      shouldCreateUser: true,
    );
  }

  /// Verifies the OTP entered by the user. Returns the auth response.
  Future<AuthResponse> verifyOtp({
    required String email,
    required String token,
  }) async {
    return _client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.email,
    );
  }

  /// Returns true if the current user has a profile row (i.e. has set their name).
  Future<bool> hasProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;
    final data = await _client
        .from('profiles')
        .select('id')
        .eq('id', userId)
        .maybeSingle();
    return data != null;
  }

  /// Creates or updates the profile row with display name.
  Future<void> saveProfile(String displayName) async {
    final userId = _client.auth.currentUser!.id;
    await _client.from('profiles').upsert({
      'id': userId,
      'display_name': displayName,
    });
  }

  Future<void> logout() async {
    await _client.auth.signOut();
  }
}
