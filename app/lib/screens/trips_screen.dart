import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/seat_request.dart';
import '../state/auth_provider.dart';
import '../state/my_requests_provider.dart';
import '../state/trips_provider.dart';
import '../theme.dart';
import '../widgets/trip_card.dart';
import 'trip_details_screen.dart';

/// Listagem de viagens: as disponíveis para solicitar + as que o usuário já está.
class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  Future<void> _reload() async {
    final tripsProvider = context.read<TripsProvider>();
    final myRequests = context.read<MyRequestsProvider>();
    final userId = context.read<AuthProvider>().user?.id;
    await tripsProvider.load();
    if (userId != null) await myRequests.load(userId);
  }

  @override
  Widget build(BuildContext context) {
    final trips = context.watch<TripsProvider>();
    final mine = context.watch<MyRequestsProvider>();

    if (trips.loading && trips.trips.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (trips.error != null && trips.trips.isEmpty) {
      return _CenteredMessage(
        icon: Icons.error_outline,
        message: trips.error!,
        actionLabel: 'Tentar de novo',
        onAction: _reload,
      );
    }

    // Minhas solicitações ativas, indexadas pela viagem.
    final myByTrip = <String, SeatRequest>{};
    for (final r in mine.requests) {
      if (r.status == 'pending' || r.status == 'accepted') myByTrip[r.tripId] = r;
    }

    // Mostra as disponíveis + as viagens em que já estou (mesmo lotadas).
    final available = trips.available;
    final shownIds = available.map((t) => t.id).toSet();
    final alsoMine = trips.trips.where((t) => myByTrip.containsKey(t.id) && !shownIds.contains(t.id));
    final list = [...available, ...alsoMine];

    return RefreshIndicator(
      onRefresh: _reload,
      color: AppColors.brand,
      child: list.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 120),
                _CenteredMessage(
                  icon: Icons.explore_off_rounded,
                  message: 'Nenhuma viagem disponível no momento.\nPuxe para baixo para atualizar.',
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: list.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (_, i) {
                if (i == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      '${list.length} ${list.length == 1 ? 'viagem disponível' : 'viagens disponíveis'}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.inkSoft),
                    ),
                  );
                }
                final trip = list[i - 1];
                return TripCard(
                  trip: trip,
                  myRequest: myByTrip[trip.id],
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => TripDetailsScreen(trip: trip)),
                  ),
                );
              },
            ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final Future<void> Function()? onAction;
  const _CenteredMessage({required this.icon, required this.message, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 88,
            width: 88,
            decoration: BoxDecoration(
              color: AppColors.brand.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 42, color: AppColors.brand),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.inkSoft, fontSize: 14.5, height: 1.45),
            ),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 20),
            FilledButton.tonalIcon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
