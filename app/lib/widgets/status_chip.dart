import 'package:flutter/material.dart';
import '../theme.dart';

/// Selo de status com ponto colorido. Usado para viagens e solicitações.
class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: style.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: style.color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: style.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            style.label,
            style: TextStyle(color: style.color, fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.1),
          ),
        ],
      ),
    );
  }

  _ChipStyle _styleFor(String s) {
    switch (s) {
      case 'pending':
        return const _ChipStyle(AppColors.pending, 'Pendente');
      case 'accepted':
        return const _ChipStyle(AppColors.success, 'Aceita');
      case 'rejected':
        return const _ChipStyle(AppColors.danger, 'Recusada');
      case 'cancelled':
        return const _ChipStyle(AppColors.muted, 'Cancelada');
      case 'open':
        return const _ChipStyle(AppColors.info, 'Aberta');
      case 'full':
        return const _ChipStyle(AppColors.accent, 'Lotada');
      case 'started':
        return const _ChipStyle(Color(0xFF0D9488), 'Em viagem');
      case 'completed':
        return const _ChipStyle(AppColors.muted, 'Concluída');
      default:
        return _ChipStyle(AppColors.muted, s);
    }
  }
}

class _ChipStyle {
  final Color color;
  final String label;
  const _ChipStyle(this.color, this.label);
}
