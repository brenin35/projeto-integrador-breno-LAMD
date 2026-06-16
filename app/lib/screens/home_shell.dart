import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/auth_provider.dart';
import '../state/trips_provider.dart';
import '../state/my_requests_provider.dart';
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
  static const _titles = ['Viagens', 'Minhas solicitações'];
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.directions_car), label: 'Viagens'),
          NavigationDestination(icon: Icon(Icons.event_seat), label: 'Solicitações'),
        ],
      ),
    );
  }
}
