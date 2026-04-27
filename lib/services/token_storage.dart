import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const _tokenKey = 'auth_token';
  static const _usernameKey = 'auth_username';

  final SharedPreferences? _prefs;

  TokenStorage(this._prefs);

  String? get token => _prefs?.getString(_tokenKey);
  String? get username => _prefs?.getString(_usernameKey);
  bool get isLoggedIn => token != null;

  Future<void> save({required String token, required String username}) async {
    await _prefs?.setString(_tokenKey, token);
    await _prefs?.setString(_usernameKey, username);
  }

  Future<void> clear() async {
    await _prefs?.remove(_tokenKey);
    await _prefs?.remove(_usernameKey);
  }
}