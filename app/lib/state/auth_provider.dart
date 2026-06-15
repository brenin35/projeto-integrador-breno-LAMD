import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

/// Estado de autenticação. Ao logar, injeta o token no [ApiClient].
///
/// (A conexão em tempo real via WebSocket será acoplada aqui quando essa
/// funcionalidade for migrada.)
class AuthProvider extends ChangeNotifier {
  final ApiClient _api;
  final AuthService _auth;

  AuthProvider(this._api, this._auth);

  User? _user;
  String? _token;
  bool _loading = false;
  String? _error;

  User? get user => _user;
  bool get isAuthenticated => _token != null;
  bool get loading => _loading;
  String? get error => _error;

  Future<bool> login(String email, String password) =>
      _run(() => _auth.login(email, password));

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) =>
      _run(() => _auth.register(name: name, email: email, password: password, phone: phone));

  Future<bool> _run(Future<AuthResult> Function() action) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await action();
      _token = result.token;
      _user = result.user;
      _api.setToken(_token);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _token = null;
    _user = null;
    _api.setToken(null);
    notifyListeners();
  }
}
