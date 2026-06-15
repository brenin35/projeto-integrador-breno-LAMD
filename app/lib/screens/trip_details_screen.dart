import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/trip.dart';
import '../state/my_requests_provider.dart';
import '../utils/format.dart';
import '../widgets/status_chip.dart';

/// Detalhes da viagem + ação principal: solicitar vaga (POST /seat-requests).
class TripDetailsScreen extends StatelessWidget {
  final Trip trip;
  const TripDetailsScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes da viagem')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${trip.origin}  →  ${trip.destination}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              StatusChip(trip.status),
            ],
          ),
          const SizedBox(height: 20),
          _InfoRow(icon: Icons.schedule, label: 'Partida', value: formatDateTime(trip.departureAt)),
          _InfoRow(icon: Icons.event_seat, label: 'Vagas', value: '${trip.availableSeats} de ${trip.totalSeats} disponíveis'),
          _InfoRow(icon: Icons.attach_money, label: 'Preço por vaga', value: 'R\$ ${trip.pricePerSeat}'),
          if (trip.notes != null && trip.notes!.isNotEmpty)
            _InfoRow(icon: Icons.notes, label: 'Observações', value: trip.notes!),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton.icon(
          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
          onPressed: () => _openRequestSheet(context),
          icon: const Icon(Icons.add),
          label: const Text('Solicitar vaga'),
        ),
      ),
    );
  }

  void _openRequestSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _RequestSheet(trip: trip),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RequestSheet extends StatefulWidget {
  final Trip trip;
  const _RequestSheet({required this.trip});

  @override
  State<_RequestSheet> createState() => _RequestSheetState();
}

class _RequestSheetState extends State<_RequestSheet> {
  int _seats = 1;
  final _message = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final provider = context.read<MyRequestsProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await provider.create(tripId: widget.trip.id, seats: _seats, message: _message.text.trim());
      navigator.pop(); // fecha o sheet
      navigator.pop(); // volta para a lista de viagens
      messenger.showSnackBar(
        const SnackBar(content: Text('Solicitação enviada! Acompanhe em "Minhas solicitações".')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Solicitar vaga', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Quantidade de vagas'),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: _seats > 1 ? () => setState(() => _seats--) : null,
              ),
              Text('$_seats', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: _seats < widget.trip.availableSeats ? () => setState(() => _seats++) : null,
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _message,
            decoration: const InputDecoration(
              labelText: 'Mensagem ao motorista (opcional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            child: _submitting
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Confirmar solicitação'),
          ),
        ],
      ),
    );
  }
}
