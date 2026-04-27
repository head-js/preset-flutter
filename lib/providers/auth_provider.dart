import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:preset/providers/shared_prefs_provider.dart';
import 'package:preset/services/auth_service.dart';
import 'package:preset/services/token_storage.dart';

class AuthState {
  const AuthState({
    this.isLoading = false,
    this.username,
    this.token,
    this.error,
  });

  final bool isLoading;
  final String? username;
  final String? token;
  final String? error;

  bool get isLoggedIn => token != null;

  AuthState copyWith({
    bool? isLoading,
    String? username,
    String? token,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      username: username ?? this.username,
      token: token ?? this.token,
      error: error ?? this.error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final TokenStorage _tokenStorage;

  AuthNotifier(this._authService, this._tokenStorage) : super(const AuthState()) {
    _restoreFromStorage();
  }

  void _restoreFromStorage() {
    final token = _tokenStorage.token;
    final username = _tokenStorage.username;
    if (token != null) {
      state = AuthState(token: token, username: username);
    }
  }

  Future<void> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _authService.login(username, password);
      await _tokenStorage.save(token: result.token, username: result.username);
      state = AuthState(token: result.token, username: result.username);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> logout() async {
    await _tokenStorage.clear();
    state = const AuthState();
  }
}

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return TokenStorage(prefs);
});

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  return AuthNotifier(AuthService(), tokenStorage);
});

final authStateProvider = Provider<AuthState>((ref) {
  return ref.watch(authNotifierProvider);
});