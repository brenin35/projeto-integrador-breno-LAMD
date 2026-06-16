import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/seat_request.dart';
import '../state/auth_provider.dart';
import '../state/my_requests_provider.dart';
import '../state/trips_provider.dart';
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

    // Quando chega um evento em tempo real, mostra um aviso e limpa o flag.
    if (p.lastEventMessage != null) {
      final message = p.lastEventMessage!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('🔔 $message'), backgroundColor: Colors.indigo),
        );
        context.read<MyRequestsProvider>().clearBanner();
      });
    }

    if (p.loading && p.requests.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: _reload,
      child: p.requests.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 160),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_seat_outlined, size: 56, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('Você ainda não solicitou vagas.', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: p.requests.length,
              separatorBuilder: (_, _) => const SizedBox(height: 4),
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
