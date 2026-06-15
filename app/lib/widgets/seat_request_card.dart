import 'package:flutter/material.dart';
import '../models/seat_request.dart';
import 'status_chip.dart';

class SeatRequestCard extends StatelessWidget {
  final SeatRequest request;
  const SeatRequestCard({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.event_seat, size: 20),
                const SizedBox(width: 8),
                Text('${request.seats} vaga(s)', style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                StatusChip(request.status),
              ],
            ),
            const SizedBox(height: 8),
            Text('Viagem: ${request.tripId}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            if (request.message != null && request.message!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('"${request.message}"', style: const TextStyle(fontStyle: FontStyle.italic)),
            ],
          ],
        ),
      ),
    );
  }
}
