import 'package:flutter/material.dart';
import '../models/seat_request.dart';
import '../models/trip.dart';
import '../theme.dart';
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
    final full = trip.availableSeats <= 0;

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (myRequest != null) _enrolledBanner(),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: _RouteTimeline(origin: trip.origin, destination: trip.destination)),
                      const SizedBox(width: 12),
                      if (myRequest == null) StatusChip(trip.status),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      _Meta(icon: Icons.calendar_today_rounded, text: formatDate(trip.departureAt)),
                      const SizedBox(width: 16),
                      _Meta(icon: Icons.schedule_rounded, text: formatTime(trip.departureAt)),
                      const Spacer(),
                      _SeatBadge(available: trip.availableSeats, total: trip.totalSeats, full: full),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      RichText(
                        text: TextSpan(
                          style: theme.textTheme.titleLarge?.copyWith(color: AppColors.brand, fontWeight: FontWeight.w800),
                          children: [
                            const TextSpan(text: 'R\$ ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            TextSpan(text: trip.pricePerSeat),
                            const TextSpan(
                              text: '  / vaga',
                              style: TextStyle(fontSize: 13, color: AppColors.inkSoft, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Ver detalhes',
                        style: theme.textTheme.labelLarge?.copyWith(color: AppColors.brand, fontWeight: FontWeight.w700),
                      ),
                      const Icon(Icons.arrow_forward_rounded, size: 18, color: AppColors.brand),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _enrolledBanner() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: AppColors.brandGradient),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Você está nesta viagem',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5),
            ),
          ),
          StatusChip(myRequest!.status),
        ],
      ),
    );
  }
}

/// Visual de rota: dois pontos ligados por uma linha tracejada vertical.
class _RouteTimeline extends StatelessWidget {
  final String origin;
  final String destination;
  const _RouteTimeline({required this.origin, required this.destination});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            const SizedBox(height: 4),
            Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.brand, width: 2.5),
              ),
            ),
            Container(width: 2, height: 22, color: AppColors.line),
            const Icon(Icons.location_on, size: 16, color: AppColors.brand),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                origin,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5, color: AppColors.ink),
              ),
              const SizedBox(height: 13),
              Text(
                destination,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5, color: AppColors.ink),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Meta({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.inkSoft),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(color: AppColors.inkSoft, fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _SeatBadge extends StatelessWidget {
  final int available;
  final int total;
  final bool full;
  const _SeatBadge({required this.available, required this.total, required this.full});

  @override
  Widget build(BuildContext context) {
    final color = full ? AppColors.danger : AppColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_seat_rounded, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            full ? 'Esgotado' : '$available de $total',
            style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}
