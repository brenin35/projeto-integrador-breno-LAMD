import 'package:flutter/material.dart';
import '../models/seat_request.dart';
import '../models/trip.dart';
import '../utils/format.dart';
import 'status_chip.dart';

class TripCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback onTap;

  /// Se o usuário já tem uma solicitação ativa nesta viagem, mostra uma faixa.
  final SeatRequest? myRequest;

  const TripCard({super.key, required this.trip, required this.onTap, this.myRequest});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (myRequest != null)
              Container(
                width: double.infinity,
                color: theme.colorScheme.primaryContainer,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 16, color: theme.colorScheme.onPrimaryContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Você já está nesta viagem',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    StatusChip(myRequest!.status),
                  ],
                ),
              ),
            Padding(
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
                          '${trip.origin}  →  ${trip.destination}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      if (myRequest == null) StatusChip(trip.status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(formatDateTime(trip.departureAt)),
                      const Spacer(),
                      const Icon(Icons.event_seat, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('${trip.availableSeats}/${trip.totalSeats} vagas'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'R\$ ${trip.pricePerSeat} por vaga',
                    style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
