import 'package:supabase_flutter/supabase_flutter.dart';

class AuthenticationService {
  final SupabaseClient _supabaseClient = Supabase.instance.client;

  Future<AuthResponse> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return await _supabaseClient.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUpWithEmail(String email, String password) async {
    return await _supabaseClient.auth.signUp(email: email, password: password);
  }

  Future<void> logout() async {
    return _supabaseClient.auth.signOut();
  }

  String? currentuserEmail() {
    final currentSession = _supabaseClient.auth.currentSession;

    return currentSession?.user.email;
  }
}
