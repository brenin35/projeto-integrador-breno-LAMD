import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/trip.dart';
import '../state/auth_provider.dart';
import '../state/driver_provider.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/status_chip.dart';
import 'create_trip_screen.dart';
import 'trip_manage_screen.dart';

/// Aba "Motorista": viagens que o usuário publicou, com botão para publicar uma
/// nova e atalho para gerenciar as solicitações de cada viagem.
class DriverTripsScreen extends StatefulWidget {
  const DriverTripsScreen({super.key});

  @override
  State<DriverTripsScreen> createState() => _DriverTripsScreenState();
}

class _DriverTripsScreenState extends State<DriverTripsScreen> {
  Future<void> _reload() async {
    final id = context.read<AuthProvider>().user?.id;
    if (id != null) await context.read<DriverProvider>().load(id);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<DriverProvider>();

    // Notifica novas solicitações (chega via WebSocket → seat_request.created).
    if (p.lastEventMessage != null) {
      final msg = p.lastEventMessage!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('🔔 $msg'), backgroundColor: AppColors.info),
        );
        context.read<DriverProvider>().clearBanner();
      });
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateTripScreen()),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Publicar viagem'),
      ),
      body: (p.loading && p.myTrips.isEmpty)
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _reload,
              child: p.myTrips.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 140),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.directions_car_outlined, size: 56, color: AppColors.muted),
                              SizedBox(height: 12),
                              Text('Você ainda não publicou viagens.', style: TextStyle(color: AppColors.inkSoft)),
                              SizedBox(height: 4),
                              Text('Toque em "Publicar viagem".', style: TextStyle(color: AppColors.muted, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                      itemCount: p.myTrips.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        final trip = p.myTrips[i];
                        return _DriverTripCard(
                          trip: trip,
                          pending: p.pendingCountForTrip(trip.id),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => TripManageScreen(tripId: trip.id)),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

class _DriverTripCard extends StatelessWidget {
  final Trip trip;
  final int pending;
  final VoidCallback onTap;
  const _DriverTripCard({required this.trip, required this.pending, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${trip.origin} → ${trip.destination}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.ink),
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusChip(trip.status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.schedule_rounded, size: 16, color: AppColors.inkSoft),
                  const SizedBox(width: 6),
                  Text(formatDateTime(trip.departureAt), style: const TextStyle(color: AppColors.inkSoft)),
                  const Spacer(),
                  const Icon(Icons.event_seat_rounded, size: 16, color: AppColors.inkSoft),
                  const SizedBox(width: 6),
                  Text('${trip.availableSeats}/${trip.totalSeats}', style: const TextStyle(color: AppColors.inkSoft)),
                ],
              ),
              if (pending > 0) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.pending.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.notifications_active_rounded, size: 18, color: AppColors.pending),
                      const SizedBox(width: 8),
                      Text(
                        '$pending ${pending == 1 ? 'nova solicitação' : 'novas solicitações'}',
                        style: const TextStyle(color: AppColors.pending, fontWeight: FontWeight.w700, fontSize: 13.5),
                      ),
                      const Spacer(),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.pending),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
