import '../models/user.dart';
import 'api_client.dart';

class AuthResult {
  final String token;
  final User user;
  AuthResult(this.token, this.user);
}

class AuthService {
  final ApiClient _api;
  AuthService(this._api);

  Future<AuthResult> login(String email, String password) async {
    final data = await _api.post('/auth/login', {
      'email': email,
      'password': password,
    });
    return _parse(data);
  }

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    final data = await _api.post('/auth/register', {
      'name': name,
      'email': email,
      'password': password,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
    });
    return _parse(data);
  }

  AuthResult _parse(dynamic data) => AuthResult(
        data['token'] as String,
        User.fromJson(data['user'] as Map<String, dynamic>),
      );
}
