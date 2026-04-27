import 'dart:math';

class AuthResult {
  final String token;
  final String username;

  AuthResult({required this.token, required this.username});
}

class AuthService {
  Future<AuthResult> login(String username, String password) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final token = _generateUuid4();
    return AuthResult(token: token, username: username);
  }

  String _generateUuid4() {
    final random = Random.secure();
    final bytes = List.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }
}