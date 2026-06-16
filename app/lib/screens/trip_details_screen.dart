import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/seat_request.dart';
import '../models/trip.dart';
import '../state/my_requests_provider.dart';
import '../utils/format.dart';
import '../widgets/status_chip.dart';

/// Detalhes da viagem. Se o usuário ainda não está nela, permite **solicitar vaga**
/// (POST /seat-requests); se já está, permite **sair da viagem** (cancelar).
class TripDetailsScreen extends StatelessWidget {
  final Trip trip;
  const TripDetailsScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final myRequest = context.watch<MyRequestsProvider>().activeForTrip(trip.id);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes da viagem')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${trip.origin} → ${trip.destination}',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              StatusChip(trip.status),
            ],
          ),
          if (myRequest != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: theme.colorScheme.onPrimaryContainer),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Você já está nesta viagem',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  StatusChip(myRequest.status),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _InfoRow(icon: Icons.schedule, label: 'Partida', value: formatDateTime(trip.departureAt)),
                  const Divider(height: 24),
                  _InfoRow(
                    icon: Icons.event_seat,
                    label: 'Vagas',
                    value: '${trip.availableSeats} de ${trip.totalSeats} disponíveis',
                  ),
                  const Divider(height: 24),
                  _InfoRow(
                    icon: Icons.attach_money,
                    label: 'Preço por vaga',
                    value: 'R\$ ${trip.pricePerSeat}',
                  ),
                  if (trip.notes != null && trip.notes!.isNotEmpty) ...[
                    const Divider(height: 24),
                    _InfoRow(icon: Icons.notes, label: 'Observações do Motorista', value: trip.notes!),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _bottomBar(context, myRequest),
    );
  }

  Widget _bottomBar(BuildContext context, SeatRequest? myRequest) {
    if (myRequest != null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => _leave(context, myRequest),
          icon: const Icon(Icons.exit_to_app),
          label: const Text('Sair da viagem', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      );
    }
    final canRequest = trip.availableSeats > 0;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: canRequest ? () => _openRequestSheet(context) : null,
        icon: const Icon(Icons.add_circle_outline),
        label: Text(
          canRequest ? 'Solicitar Vaga' : 'Esgotado',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<void> _leave(BuildContext context, SeatRequest req) async {
    final provider = context.read<MyRequestsProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair da viagem'),
        content: const Text('Deseja cancelar sua solicitação nesta viagem?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Voltar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sair')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await provider.cancel(req.id);
      navigator.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Você saiu da viagem.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
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
