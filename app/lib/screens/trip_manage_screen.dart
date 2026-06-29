import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/seat_request.dart';
import '../models/trip.dart';
import '../state/driver_provider.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/status_chip.dart';


class TripManageScreen extends StatelessWidget {
  final String tripId;
  const TripManageScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<DriverProvider>();
    final trip = p.tripById(tripId);

    if (trip == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Viagem')),
        body: const Center(child: Text('Viagem não encontrada')),
      );
    }

    final all = p.requestsForTrip(tripId);
    final pending = all.where((r) => r.status == 'pending').toList();
    final accepted = all.where((r) => r.status == 'accepted').toList();
    final history = all.where((r) => r.status == 'rejected' || r.status == 'cancelled').toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Gerenciar viagem')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _tripHeader(trip),
          const SizedBox(height: 20),
          _statusActions(context, trip),
          const SizedBox(height: 24),
          _sectionTitle('Pendentes', pending.length, AppColors.pending),
          const SizedBox(height: 8),
          if (pending.isEmpty)
            _emptyHint('Nenhuma solicitação pendente.')
          else
            ...pending.map((r) => _requestTile(context, p, r, actions: true)),
          const SizedBox(height: 24),
          _sectionTitle('Confirmados (em andamento)', accepted.length, AppColors.success),
          const SizedBox(height: 8),
          if (accepted.isEmpty)
            _emptyHint('Nenhum passageiro confirmado ainda.')
          else
            ...accepted.map((r) => _requestTile(context, p, r)),
          if (history.isNotEmpty) ...[
            const SizedBox(height: 24),
            _sectionTitle('Histórico', history.length, AppColors.muted),
            const SizedBox(height: 8),
            ...history.map((r) => _requestTile(context, p, r)),
          ],
        ],
      ),
    );
  }

  Widget _tripHeader(Trip trip) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${trip.origin} → ${trip.destination}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.ink),
                  ),
                ),
                const SizedBox(width: 8),
                StatusChip(trip.status),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(spacing: 18, runSpacing: 8, children: [
              _meta(Icons.event_rounded, formatDateTime(trip.departureAt)),
              _meta(Icons.event_seat_rounded, '${trip.availableSeats}/${trip.totalSeats} vagas'),
              _meta(Icons.payments_rounded, 'R\$ ${trip.pricePerSeat}'),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _meta(IconData icon, String text) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 15, color: AppColors.inkSoft),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: AppColors.ink, fontSize: 13.5, fontWeight: FontWeight.w500)),
      ]);

  Widget _statusActions(BuildContext context, Trip trip) {
    final buttons = <Widget>[];
    if (trip.status == 'open' || trip.status == 'full') {
      buttons.add(Expanded(
        child: FilledButton.icon(
          onPressed: () => _changeStatus(context, trip.id, 'started', 'Viagem iniciada'),
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Iniciar'),
        ),
      ));
      buttons.add(const SizedBox(width: 12));
      buttons.add(Expanded(
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.line)),
          onPressed: () => _confirmStatus(context, trip.id, 'cancelled', 'Cancelar viagem',
              'Deseja cancelar esta viagem?', 'Viagem cancelada'),
          icon: const Icon(Icons.close_rounded),
          label: const Text('Cancelar'),
        ),
      ));
    } else if (trip.status == 'started') {
      buttons.add(Expanded(
        child: FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: AppColors.success),
          onPressed: () => _confirmStatus(context, trip.id, 'completed', 'Concluir viagem',
              'Marcar esta viagem como concluída?', 'Viagem concluída'),
          icon: const Icon(Icons.check_circle_rounded),
          label: const Text('Concluir viagem'),
        ),
      ));
    } else {
      return const SizedBox.shrink();
    }
    return Row(children: buttons);
  }

  Widget _sectionTitle(String title, int count, Color color) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.ink)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
          child: Text('$count', style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _emptyHint(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(text, style: const TextStyle(color: AppColors.muted)),
      );

  Widget _requestTile(BuildContext context, DriverProvider p, SeatRequest r, {bool actions = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.brand.withValues(alpha: 0.12),
                    child: Text(
                      _initials(p.passengerName(r.passengerId)),
                      style: const TextStyle(color: AppColors.brand, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.passengerName(r.passengerId),
                            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
                        Text('${r.seats} vaga(s)', style: const TextStyle(color: AppColors.inkSoft, fontSize: 13)),
                      ],
                    ),
                  ),
                  StatusChip(r.status),
                ],
              ),
              if (r.message != null && r.message!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.canvas, borderRadius: BorderRadius.circular(8)),
                  child: Text('“${r.message}”',
                      style: const TextStyle(fontStyle: FontStyle.italic, color: AppColors.inkSoft, fontSize: 13.5)),
                ),
              ],
              if (actions) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          minimumSize: const Size.fromHeight(44),
                          side: BorderSide(color: AppColors.danger.withValues(alpha: 0.4)),
                        ),
                        onPressed: () => _run(context, () => p.reject(r.id), 'Solicitação recusada'),
                        child: const Text('Recusar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: AppColors.success, minimumSize: const Size.fromHeight(44)),
                        onPressed: () => _run(context, () => p.accept(r.id), 'Solicitação aceita'),
                        child: const Text('Aceitar'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Future<void> _run(BuildContext context, Future<void> Function() action, String okMsg) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      messenger.showSnackBar(SnackBar(content: Text(okMsg)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _changeStatus(BuildContext context, String id, String status, String okMsg) =>
      _run(context, () => context.read<DriverProvider>().setTripStatus(id, status), okMsg);

  Future<void> _confirmStatus(
    BuildContext context,
    String id,
    String status,
    String title,
    String body,
    String okMsg,
  ) async {
    final provider = context.read<DriverProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Voltar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirmar')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await provider.setTripStatus(id, status);
      messenger.showSnackBar(SnackBar(content: Text(okMsg)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}
