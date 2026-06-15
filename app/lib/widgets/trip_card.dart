import 'package:flutter/material.dart';
import '../models/trip.dart';
import '../utils/format.dart';
import 'status_chip.dart';

class TripCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback onTap;
  const TripCard({super.key, required this.trip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
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
                      '${trip.origin}  →  ${trip.destination}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  StatusChip(trip.status),
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
                  Text('${trip.availableSeats}/${trip.totalSeats}'),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'R\$ ${trip.pricePerSeat} por vaga',
                style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
