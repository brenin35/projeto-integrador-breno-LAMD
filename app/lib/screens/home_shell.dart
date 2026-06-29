import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/auth_provider.dart';
import '../state/driver_provider.dart';
import '../state/my_requests_provider.dart';
import '../state/trips_provider.dart';
import '../theme.dart';
import 'trips_screen.dart';
import 'my_requests_screen.dart';
import 'driver_trips_screen.dart';

enum AppMode { passenger, driver }

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  AppMode _mode = AppMode.passenger;
  int _passengerTab = 0; // 0 = Viagens, 1 = Solicitações

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
    final driver = _mode == AppMode.driver;

    final tripsMsg = context.watch<TripsProvider>().lastEventMessage;
    final driverMsg = context.watch<DriverProvider>().lastEventMessage;
    final requestsMsg = context.watch<MyRequestsProvider>().lastEventMessage;
    for (final msg in [tripsMsg, driverMsg, requestsMsg]) {
      if (msg != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('🔔 $msg'), backgroundColor: AppColors.info),
          );
          context.read<TripsProvider>().clearBanner();
          context.read<DriverProvider>().clearBanner();
          context.read<MyRequestsProvider>().clearBanner();
        });
        break; // só um snackbar por frame
      }
    }

    final String title;
    final String subtitle;
    if (driver) {
      title = 'Modo motorista';
      subtitle = 'Suas viagens publicadas';
    } else if (_passengerTab == 0) {
      title = firstName.isNotEmpty ? 'Olá, $firstName 👋' : 'Olá';
      subtitle = 'Encontre sua próxima carona';
    } else {
      title = 'Minhas solicitações';
      subtitle = 'Acompanhe seus pedidos';
    }

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
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.directions_car_filled_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.2),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(58),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _ModeSwitch(
              mode: _mode,
              onChanged: (m) => setState(() => _mode = m),
            ),
          ),
        ),
      ),
      body: driver
          ? const DriverTripsScreen()
          : IndexedStack(
              index: _passengerTab,
              children: const [TripsScreen(), MyRequestsScreen()],
            ),
      bottomNavigationBar: driver
          ? null
          : Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.line)),
              ),
              child: NavigationBar(
                selectedIndex: _passengerTab,
                onDestinationSelected: (i) => setState(() => _passengerTab = i),
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
                ],
              ),
            ),
    );
  }
}

/// Alternador entre os dois modos do app: o mesmo usuário pode ser passageiro
/// (busca/solicita caronas) ou motorista (publica/gerencia viagens).
class _ModeSwitch extends StatelessWidget {
  final AppMode mode;
  final ValueChanged<AppMode> onChanged;
  const _ModeSwitch({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          _segment('Passageiro', Icons.person_rounded, AppMode.passenger),
          _segment('Motorista', Icons.directions_car_filled_rounded, AppMode.driver),
        ],
      ),
    );
  }

  Widget _segment(String label, IconData icon, AppMode value) {
    final active = mode == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: active ? AppColors.brandGradient : null,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: active ? Colors.white : AppColors.inkSoft),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: active ? Colors.white : AppColors.inkSoft,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
