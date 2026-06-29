import 'package:flutter/material.dart';
import '../models/seat_request.dart';
import '../models/trip.dart';
import '../theme.dart';
import '../utils/format.dart';
import 'status_chip.dart';

class SeatRequestCard extends StatelessWidget {
  final SeatRequest request;

  /// Viagem associada (resolvida pelo provider) — para mostrar rota/data/preço.
  final Trip? trip;

  /// Callback de "sair da viagem" (só aparece em solicitações ativas).
  final Future<void> Function()? onCancel;

  const SeatRequestCard({super.key, required this.request, this.trip, this.onCancel});

  bool get _canCancel {
    final active = request.status == 'pending' || request.status == 'accepted';
    final tripOpen = trip == null || (trip!.status != 'completed' && trip!.status != 'cancelled');
    return active && tripOpen;
  }

  /// Status da viagem que vale a pena destacar ao passageiro.
  bool get _hasTripBanner => trip != null && trip!.status != 'open' && trip!.status != 'full';

  @override
  Widget build(BuildContext context) {
    final t = trip;
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner da viagem (Em viagem / Concluída / Cancelada)
          if (_hasTripBanner) _tripStatusBanner(t!.status),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: AppColors.brand.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.route_rounded, size: 20, color: AppColors.brand),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        t != null ? '${t.origin} → ${t.destination}' : 'Viagem ${request.tripId}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5, color: AppColors.ink),
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusChip(request.status),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 18,
                  runSpacing: 10,
                  children: [
                    if (t != null) _line(Icons.calendar_today_rounded, formatDate(t.departureAt)),
                    if (t != null) _line(Icons.schedule_rounded, formatTime(t.departureAt)),
                    _line(Icons.event_seat_rounded, '${request.seats} vaga(s)'),
                    if (t != null) _line(Icons.payments_rounded, 'R\$ ${t.pricePerSeat}'),
                  ],
                ),
                if (request.message != null && request.message!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.canvas,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '"${request.message}"',
                      style: const TextStyle(fontStyle: FontStyle.italic, color: AppColors.inkSoft, fontSize: 13.5, height: 1.4),
                    ),
                  ),
                ],
                if (onCancel != null && _canCancel) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onCancel,
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text('Sair da viagem'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        minimumSize: const Size.fromHeight(46),
                        side: BorderSide(color: AppColors.danger.withValues(alpha: 0.4)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tripStatusBanner(String tripStatus) {
    final (color, icon, label) = switch (tripStatus) {
      'started' => (AppColors.info, Icons.directions_car_filled_rounded, 'Viagem em andamento'),
      'completed' => (AppColors.success, Icons.check_circle_rounded, 'Viagem concluída'),
      'cancelled' => (AppColors.danger, Icons.cancel_rounded, 'Viagem cancelada'),
      _ => (AppColors.muted, Icons.info_outline_rounded, tripStatus),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border(bottom: BorderSide(color: color.withValues(alpha: 0.2))),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _line(IconData icon, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.inkSoft),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: AppColors.ink, fontSize: 13.5, fontWeight: FontWeight.w500)),
        ],
      );
}
