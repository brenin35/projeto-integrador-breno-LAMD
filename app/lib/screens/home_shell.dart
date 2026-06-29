import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/auth_provider.dart';
import '../state/trips_provider.dart';
import '../state/my_requests_provider.dart';
import '../state/driver_provider.dart';
import '../theme.dart';
import 'trips_screen.dart';
import 'my_requests_screen.dart';
import 'driver_trips_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  static const _screens = [TripsScreen(), MyRequestsScreen(), DriverTripsScreen()];

  static const _titles = ['Olá', 'Minhas solicitações', 'Modo motorista'];
  static const _subtitles = [
    'Encontre sua próxima carona',
    'Acompanhe seus pedidos',
    'Suas viagens publicadas',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().user?.id;
      context.read<TripsProvider>().load();
      if (userId != null) {
        context.read<MyRequestsProvider>().load(userId);
        context.read<DriverProvider>().load(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final firstName = (user?.name ?? '').split(' ').first;
    final title = _index == 0 && firstName.isNotEmpty ? 'Olá, $firstName 👋' : _titles[_index];

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
                  title,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.2),
                ),
                Text(
                  _subtitles[_index],
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
              icon: Icon(Icons.search_rounded),
              selectedIcon: Icon(Icons.search_rounded),
              label: 'Viagens',
            ),
            NavigationDestination(
              icon: Icon(Icons.event_seat_outlined),
              selectedIcon: Icon(Icons.event_seat_rounded),
              label: 'Solicitações',
            ),
            NavigationDestination(
              icon: Icon(Icons.directions_car_outlined),
              selectedIcon: Icon(Icons.directions_car_filled_rounded),
              label: 'Motorista',
            ),
          ],
        ),
      ),
    );
  }
}
