import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/seat_request.dart';
import '../state/auth_provider.dart';
import '../state/my_requests_provider.dart';
import '../state/trips_provider.dart';
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
      child: list.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 160),
                _CenteredMessage(icon: Icons.directions_car_outlined, message: 'Nenhuma viagem disponível no momento.'),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: 4),
              itemBuilder: (_, i) {
                final trip = list[i];
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
          Icon(icon, size: 56, color: Colors.grey),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 12),
            FilledButton.tonal(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
