import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:balaji_crushers_app/core/network/api_client.dart';
import 'package:balaji_crushers_app/features/auth/data/repositories/auth_repository.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository());

// ── Auth State ────────────────────────────────────────────────────────────────
class AuthState {
  final Map<String, dynamic>? user;
  final bool isLoading;
  final String? error;

  AuthState({this.user, this.isLoading = false, this.error});

  /// Derived: logged in iff we have a user object in memory.
  bool get isLoggedIn => user != null;

  AuthState copyWith({Map<String, dynamic>? user, bool? isLoading, String? error}) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ── Provider ─────────────────────────────────────────────────────────────────
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});

// ── Notifier ──────────────────────────────────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(AuthState()){
    initAuth();
  }

  /// On app start: if a token is already in memory (loaded by main.dart),
  /// validate it with the server and restore the session silently.
  Future<void> _checkLoginStatus() async {
    final token = await ApiClient().getToken();
    if (token == null) return; // No stored token — stay on login screen.

    final profile = await _repo.getMe();
    if (profile != null) {
      // Token is valid; restore the session without re-login.
      state = AuthState(user: profile, isLoading: false);
    } else {
      // Token expired / revoked — wipe it so the user sees the login screen.
      await ApiClient().clearToken();
    }
  }

  Future<void> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _repo.login(username, password);
      if (user['token'] != null) {
        await ApiClient().setToken(user['token'] as String);
      }
      state = AuthState(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    await ApiClient().clearToken();
    state = AuthState();
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      final updated = await _repo.updateProfile(data);
      // Merge updated fields into current user map so the UI refreshes.
      state = state.copyWith(user: {...?state.user, ...updated});
    } catch (e) {
      rethrow;
    }
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    await _repo.changePassword(oldPassword, newPassword);
  }

  /// Re-fetch full profile from /auth/me and merge into state.
  /// Does NOT gate on isLoggedIn — the backend protect middleware validates
  /// the JWT, so a successful response always means we have a real user.
  Future<void> refreshProfile() async {
    final profile = await _repo.fetchProfile();
    // fetchProfile() throws on any error, so reaching here means success.
    // Merge into whatever user state currently exists (may be null during startup).
    state = state.copyWith(
      user: {...?state.user, ...profile},
      isLoading: false,
    );
  }

  Future<void> initAuth() async {
    state = state.copyWith(isLoading: true);

    try {
      final token = await ApiClient().getToken();

      if (token == null) {
        state = state.copyWith(isLoading: false, user: null);
        return;
      }

      final profile = await _repo.getMe();

      if (profile != null) {
        state = state.copyWith(
          user: profile,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      // 🔥 NEVER BLOCK UI
      state = state.copyWith(isLoading: false);
    }
  }
  
}
