import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/seat_request.dart';
import '../models/trip.dart';
import '../state/my_requests_provider.dart';
import '../state/trips_provider.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/status_chip.dart';

/// Detalhes da viagem. Se o usuário ainda não está nela, permite **solicitar vaga**
/// (POST /seat-requests); se já está, permite **sair da viagem** (cancelar).
class TripDetailsScreen extends StatelessWidget {
  final Trip trip;
  const TripDetailsScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    // Usa a versão "viva" da viagem (atualizada via WebSocket) quando disponível,
    // para refletir mudanças de status/vagas sem precisar reabrir a tela.
    final live = context.watch<TripsProvider>().byId(trip.id) ?? trip;
    final myRequest = context.watch<MyRequestsProvider>().activeForTrip(trip.id);

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes da viagem')),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _hero(live),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (myRequest != null) ...[
                  _enrolledBanner(context, myRequest),
                  const SizedBox(height: 20),
                ],
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Column(
                      children: [
                        _InfoRow(icon: Icons.event_rounded, label: 'Partida', value: formatDateTime(trip.departureAt)),
                        const Divider(height: 1),
                        _InfoRow(
                          icon: Icons.event_seat_rounded,
                          label: 'Vagas disponíveis',
                          value: '${live.availableSeats} de ${live.totalSeats}',
                        ),
                        const Divider(height: 1),
                        _InfoRow(
                          icon: Icons.payments_rounded,
                          label: 'Preço por vaga',
                          value: 'R\$ ${trip.pricePerSeat}',
                          highlight: true,
                        ),
                        if (trip.notes != null && trip.notes!.isNotEmpty) ...[
                          const Divider(height: 1),
                          _InfoRow(
                            icon: Icons.sticky_note_2_outlined,
                            label: 'Observações do motorista',
                            value: trip.notes!,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _bottomBar(context, myRequest, live),
    );
  }

  Widget _hero(Trip live) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: AppColors.brandGradient),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: StatusChipOnDark(live.status),
          ),
          const SizedBox(height: 4),
          _heroPoint(Icons.trip_origin, 'Origem', trip.origin),
          Padding(
            padding: const EdgeInsets.only(left: 11),
            child: Container(width: 2, height: 26, color: Colors.white.withValues(alpha: 0.4)),
          ),
          _heroPoint(Icons.location_on, 'Destino', trip.destination),
        ],
      ),
    );
  }

  Widget _heroPoint(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _enrolledBanner(BuildContext context, SeatRequest myRequest) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.success),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Você já está nesta viagem',
              style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700, fontSize: 14.5),
            ),
          ),
          StatusChip(myRequest.status),
        ],
      ),
    );
  }

  Widget _bottomBar(BuildContext context, SeatRequest? myRequest, Trip live) {
    final finished = live.status == 'completed' || live.status == 'cancelled';
    final accepting = live.status == 'open' && live.availableSeats > 0;
    // Só dá para sair enquanto a viagem ainda não começou/terminou.
    final canLeave = live.status == 'open' || live.status == 'full';

    final Widget content;
    if (myRequest != null) {
      content = OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.danger,
          side: BorderSide(color: AppColors.danger.withValues(alpha: 0.4)),
        ),
        onPressed: canLeave ? () => _leave(context, myRequest) : null,
        icon: Icon(canLeave ? Icons.logout_rounded : Icons.lock_outline_rounded),
        label: Text(canLeave ? 'Sair da viagem' : 'Viagem ${live.status == 'completed' ? 'concluída' : 'em andamento'}'),
      );
    } else if (accepting) {
      content = FilledButton.icon(
        onPressed: () => _openRequestSheet(context, live),
        icon: const Icon(Icons.add_circle_outline_rounded),
        label: const Text('Solicitar vaga'),
      );
    } else {
      final label = finished
          ? 'Viagem encerrada'
          : live.status != 'open'
              ? 'Indisponível'
              : 'Esgotado';
      content = FilledButton.icon(
        onPressed: null,
        icon: const Icon(Icons.block_rounded),
        label: Text(label),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 14, 20, 14),
        child: content,
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
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger, minimumSize: const Size(88, 44)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sair'),
          ),
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

  void _openRequestSheet(BuildContext context, Trip live) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _RequestSheet(trip: live),
    );
  }
}

/// Variante do StatusChip legível sobre o gradiente escuro do hero.
class StatusChipOnDark extends StatelessWidget {
  final String status;
  const StatusChipOnDark(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
      ),
      child: StatusChip(status),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool highlight;
  const _InfoRow({required this.icon, required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.brand.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: AppColors.brand),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppColors.inkSoft, fontSize: 12.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: highlight ? 18 : 15.5,
                    fontWeight: FontWeight.w700,
                    color: highlight ? AppColors.brand : AppColors.ink,
                  ),
                ),
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
        left: 24,
        right: 24,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(3)),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Solicitar vaga', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
          const SizedBox(height: 4),
          Text(
            '${widget.trip.origin} → ${widget.trip.destination}',
            style: const TextStyle(color: AppColors.inkSoft, fontSize: 14),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Text('Quantidade de vagas', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
                const Spacer(),
                _StepperButton(
                  icon: Icons.remove_rounded,
                  onTap: _seats > 1 ? () => setState(() => _seats--) : null,
                ),
                SizedBox(
                  width: 40,
                  child: Text('$_seats', textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                ),
                _StepperButton(
                  icon: Icons.add_rounded,
                  onTap: _seats < widget.trip.availableSeats ? () => setState(() => _seats++) : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _message,
            decoration: const InputDecoration(
              labelText: 'Mensagem ao motorista (opcional)',
              alignLabelWithHint: true,
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _submitting ? null : _submit,
            icon: _submitting
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                : const Icon(Icons.send_rounded, size: 20),
            label: Text(_submitting ? 'Enviando...' : 'Confirmar solicitação'),
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _StepperButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: enabled ? Colors.white : AppColors.canvas,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: enabled ? AppColors.line : Colors.transparent),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 22, color: enabled ? AppColors.brand : AppColors.muted),
        ),
      ),
    );
  }
}
