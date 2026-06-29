import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/driver_provider.dart';
import '../theme.dart';
import '../utils/format.dart';

/// Formulário para o motorista publicar uma nova viagem (POST /trips).
class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({super.key});

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _origin = TextEditingController();
  final _destination = TextEditingController();
  final _price = TextEditingController();
  final _notes = TextEditingController();
  int _seats = 3;
  DateTime _departure = DateTime.now().add(const Duration(days: 1, hours: 1));
  bool _submitting = false;

  @override
  void dispose() {
    _origin.dispose();
    _destination.dispose();
    _price.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDeparture() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _departure,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_departure),
    );
    if (time == null) return;
    setState(() {
      _departure = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final provider = context.read<DriverProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await provider.publishTrip(
        origin: _origin.text.trim(),
        destination: _destination.text.trim(),
        departureAt: _departure,
        totalSeats: _seats,
        pricePerSeat: _price.text.trim().replaceAll(',', '.'),
        notes: _notes.text.trim(),
      );
      navigator.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Viagem publicada!')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Publicar viagem')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _origin,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Origem', prefixIcon: Icon(Icons.trip_origin)),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe a origem' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _destination,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Destino', prefixIcon: Icon(Icons.location_on_outlined)),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o destino' : null,
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickDeparture,
              borderRadius: BorderRadius.circular(16),
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Partida', prefixIcon: Icon(Icons.event_rounded)),
                child: Text(formatDateTime(_departure), style: const TextStyle(fontSize: 16, color: AppColors.ink)),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event_seat_rounded, color: AppColors.inkSoft),
                  const SizedBox(width: 12),
                  const Text('Vagas', style: TextStyle(fontSize: 16, color: AppColors.ink)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                    onPressed: _seats > 1 ? () => setState(() => _seats--) : null,
                  ),
                  Text('$_seats', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    onPressed: _seats < 8 ? () => setState(() => _seats++) : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _price,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Preço por vaga (R\$)', prefixIcon: Icon(Icons.payments_rounded)),
              validator: (v) {
                final value = double.tryParse((v ?? '').trim().replaceAll(',', '.'));
                if (value == null || value < 0) return 'Informe um preço válido';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notes,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Observações (opcional)',
                prefixIcon: Icon(Icons.sticky_note_2_outlined),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.publish_rounded),
              label: Text(_submitting ? 'Publicando...' : 'Publicar viagem'),
            ),
          ],
        ),
      ),
    );
  }
}
