import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:viralflow_automation/core/models/user_model.dart';

class AuthService {
  final SupabaseClient _client;

  AuthService(this._client);

  // Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );

    return response;
  }

  // Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    return await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.flutter://login-callback',
    );
  }

  // Sign out
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // Get current user
  User? get currentUser => _client.auth.currentUser;

  // Get current user profile
  Future<UserModel> getCurrentUserProfile() async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _client
        .from('users')
        .select()
        .eq('id', userId)
        .single();

    return UserModel.fromJson(response);
  }

  // Update user profile
  Future<UserModel> updateUserProfile({
    String? fullName,
    String? avatarUrl,
  }) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    updates['updated_at'] = DateTime.now().toIso8601String();

    final response = await _client
        .from('users')
        .update(updates)
        .eq('id', userId)
        .select()
        .single();

    return UserModel.fromJson(response);
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  // Auth state stream
  Stream<AuthState> get authStateStream =>
      _client.auth.onAuthStateChange;
}