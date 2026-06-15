import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: style.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        style.label,
        style: TextStyle(color: style.color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }

  _ChipStyle _styleFor(String s) {
    switch (s) {
      case 'pending':
        return const _ChipStyle(Colors.orange, 'Pendente');
      case 'accepted':
        return const _ChipStyle(Colors.green, 'Aceita');
      case 'rejected':
        return const _ChipStyle(Colors.red, 'Recusada');
      case 'cancelled':
        return const _ChipStyle(Colors.grey, 'Cancelada');
      case 'open':
        return const _ChipStyle(Colors.blue, 'Aberta');
      case 'full':
        return const _ChipStyle(Colors.purple, 'Lotada');
      case 'started':
        return const _ChipStyle(Colors.teal, 'Em viagem');
      case 'completed':
        return const _ChipStyle(Colors.blueGrey, 'Concluída');
      default:
        return _ChipStyle(Colors.grey, s);
    }
  }
}

class _ChipStyle {
  final Color color;
  final String label;
  const _ChipStyle(this.color, this.label);
}
