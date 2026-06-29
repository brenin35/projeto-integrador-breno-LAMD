import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/seat_request.dart';
import '../state/auth_provider.dart';
import '../state/my_requests_provider.dart';
import '../state/trips_provider.dart';
import '../theme.dart';
import '../widgets/seat_request_card.dart';

/// Minhas solicitações. A lista se atualiza sozinha quando o motorista aceita
/// ou recusa (evento via WebSocket → provider → rebuild). Aqui também dá para
/// **sair da viagem** (cancelar uma solicitação ativa).
class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  Future<void> _reload() async {
    final tripsProvider = context.read<TripsProvider>();
    final myRequests = context.read<MyRequestsProvider>();
    final userId = context.read<AuthProvider>().user?.id;
    await tripsProvider.load();
    if (userId != null) await myRequests.load(userId);
  }

  Future<void> _cancel(SeatRequest req) async {
    final provider = context.read<MyRequestsProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair da viagem'),
        content: const Text('Deseja cancelar esta solicitação?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Voltar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sair')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await provider.cancel(req.id);
      messenger.showSnackBar(const SnackBar(content: Text('Você saiu da viagem.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<MyRequestsProvider>();
    final trips = context.watch<TripsProvider>();

    if (p.loading && p.requests.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: _reload,
      color: AppColors.brand,
      child: p.requests.isEmpty
          ? ListView(
              children: [
                const SizedBox(height: 120),
                Center(
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
                        child: const Icon(Icons.event_seat_rounded, size: 42, color: AppColors.brand),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Você ainda não solicitou vagas',
                        style: TextStyle(color: AppColors.ink, fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          'Explore as viagens disponíveis e peça sua carona.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.inkSoft, fontSize: 14, height: 1.45),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: p.requests.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (_, i) {
                final req = p.requests[i];
                return SeatRequestCard(
                  request: req,
                  trip: trips.byId(req.tripId),
                  onCancel: () => _cancel(req),
                );
              },
            ),
    );
  }
}
