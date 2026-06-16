import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/auth_provider.dart';
import '../state/trips_provider.dart';
import '../state/my_requests_provider.dart';
import '../theme.dart';
import 'trips_screen.dart';
import 'my_requests_screen.dart';

/// Casca com navegação inferior entre as duas áreas do cliente.
/// Usa IndexedStack para manter as duas telas vivas — a de "Minhas solicitações"
/// continua recebendo as atualizações em tempo real mesmo fora de foco.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  static const _screens = [TripsScreen(), MyRequestsScreen()];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().user?.id;
      context.read<TripsProvider>().load();
      if (userId != null) context.read<MyRequestsProvider>().load(userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final firstName = (user?.name ?? '').split(' ').first;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        toolbarHeight: 72,
        title: Row(
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.directions_car_filled_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _index == 0 ? 'Olá${firstName.isNotEmpty ? ', $firstName' : ''} 👋' : 'Minhas solicitações',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.2),
                ),
                Text(
                  _index == 0 ? 'Encontre sua próxima carona' : 'Acompanhe seus pedidos',
                  style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'Sair',
              style: IconButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.inkSoft),
              onPressed: () => context.read<AuthProvider>().logout(),
            ),
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.directions_car_outlined),
              selectedIcon: Icon(Icons.directions_car_filled_rounded),
              label: 'Viagens',
            ),
            NavigationDestination(
              icon: Icon(Icons.event_seat_outlined),
              selectedIcon: Icon(Icons.event_seat_rounded),
              label: 'Solicitações',
            ),
          ],
        ),
      ),
    );
  }
}
