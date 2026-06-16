import 'package:flutter/material.dart';
import '../models/seat_request.dart';
import '../models/trip.dart';
import '../utils/format.dart';
import 'status_chip.dart';

class SeatRequestCard extends StatelessWidget {
  final SeatRequest request;

  /// Viagem associada (resolvida pelo provider) — para mostrar rota/data/preço.
  final Trip? trip;

  /// Callback de "sair da viagem" (só aparece em solicitações ativas).
  final Future<void> Function()? onCancel;

  const SeatRequestCard({super.key, required this.request, this.trip, this.onCancel});

  bool get _canCancel => request.status == 'pending' || request.status == 'accepted';

  @override
  Widget build(BuildContext context) {
    final t = trip;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.route, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    t != null ? '${t.origin}  →  ${t.destination}' : 'Viagem ${request.tripId}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                StatusChip(request.status),
              ],
            ),
            if (t != null) ...[
              const SizedBox(height: 10),
              _line(Icons.schedule, formatDateTime(t.departureAt)),
              const SizedBox(height: 4),
              _line(Icons.attach_money, 'R\$ ${t.pricePerSeat} por vaga'),
            ],
            const SizedBox(height: 4),
            _line(Icons.event_seat, '${request.seats} vaga(s) solicitada(s)'),
            if (request.message != null && request.message!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('"${request.message}"', style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black54)),
            ],
            if (onCancel != null && _canCancel) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.exit_to_app, size: 18),
                  label: const Text('Sair da viagem'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _line(IconData icon, String text) => Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.black87))),
        ],
      );
}
