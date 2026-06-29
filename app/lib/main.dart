import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/trip_service.dart';
import 'services/seat_request_service.dart';
import 'services/user_service.dart';
import 'services/realtime_service.dart';
import 'state/auth_provider.dart';
import 'state/trips_provider.dart';
import 'state/my_requests_provider.dart';
import 'state/driver_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_shell.dart';
import 'theme.dart';

void main() {
  final api = ApiClient();
  final realtime = RealtimeService();
  runApp(CaronascarApp(api: api, realtime: realtime));
}

class CaronascarApp extends StatelessWidget {
  final ApiClient api;
  final RealtimeService realtime;
  const CaronascarApp({super.key, required this.api, required this.realtime});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(api, AuthService(api), realtime)),
        ChangeNotifierProvider(create: (_) => TripsProvider(TripService(api), realtime)),
        ChangeNotifierProvider(create: (_) => MyRequestsProvider(SeatRequestService(api), realtime)),
        ChangeNotifierProvider(
          create: (_) => DriverProvider(TripService(api), SeatRequestService(api), UserService(api), realtime),
        ),
      ],
      child: MaterialApp(
        title: 'Caronascar',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = context.watch<AuthProvider>().isAuthenticated;
    return isAuthenticated ? const HomeShell() : const LoginScreen();
  }
}
