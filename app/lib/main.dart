import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'state/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() {
  // ApiClient compartilhado guarda o token JWT após o login.
  final api = ApiClient();
  runApp(CaronascarApp(api: api));
}

class CaronascarApp extends StatelessWidget {
  final ApiClient api;
  const CaronascarApp({super.key, required this.api});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(api, AuthService(api))),
      ],
      child: MaterialApp(
        title: 'Caronascar',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFF2E7D32),
          useMaterial3: true,
        ),
        home: const AuthGate(),
      ),
    );
  }
}

/// Decide entre login e app conforme o estado de autenticação.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = context.watch<AuthProvider>().isAuthenticated;
    return isAuthenticated ? const HomeScreen() : const LoginScreen();
  }
}
