import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/trips_provider.dart';
import '../widgets/trip_card.dart';
import 'trip_details_screen.dart';

/// Listagem de viagens disponíveis (integração REST: GET /trips).
class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<TripsProvider>().load());
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<TripsProvider>();

    if (p.loading && p.trips.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (p.error != null && p.trips.isEmpty) {
      return _CenteredMessage(
        icon: Icons.error_outline,
        message: p.error!,
        actionLabel: 'Tentar de novo',
        onAction: () => context.read<TripsProvider>().load(),
      );
    }
    return RefreshIndicator(
      onRefresh: () => context.read<TripsProvider>().load(),
      child: p.trips.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 160),
                _CenteredMessage(icon: Icons.directions_car_outlined, message: 'Nenhuma viagem disponível no momento.'),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: p.trips.length,
              itemBuilder: (_, i) {
                final trip = p.trips[i];
                return TripCard(
                  trip: trip,
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
  final VoidCallback? onAction;
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
