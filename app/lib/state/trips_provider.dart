import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/trip.dart';
import '../services/realtime_service.dart';
import '../services/trip_service.dart';

/// Carrega TODAS as viagens; expõe as disponíveis e um lookup por id
/// (usado para resolver a viagem de cada solicitação). Recarrega sozinha quando
/// (re)conecta o WebSocket ou quando uma viagem muda de status.
class TripsProvider extends ChangeNotifier {
  final TripService _service;
  final RealtimeService _realtime;
  StreamSubscription<RealtimeEvent>? _sub;

  TripsProvider(this._service, this._realtime) {
    _sub = _realtime.events.listen(_onEvent);
  }

  List<Trip> trips = [];
  bool loading = false;
  String? error;

  /// Mensagem do último evento em tempo real (ex.: nova viagem publicada).
  String? lastEventMessage;

  void _onEvent(RealtimeEvent ev) {
    switch (ev.type) {
      case 'connected':
      case 'trip.status_changed':
      case 'seat_request.status_changed':
        // Recarrega: (re)conexão, mudança de status ou de vagas (aceitar/cancelar).
        load();
        break;
      case 'trip.created':
        try {
          final newTrip = Trip.fromJson(ev.data);
          // Insere imediatamente na lista local — sem round-trip HTTP.
          // Se já existe (reentrega do broker), não duplica.
          if (!trips.any((t) => t.id == newTrip.id)) {
            trips = [newTrip, ...trips]
              ..sort((a, b) => a.departureAt.compareTo(b.departureAt));
          }
          lastEventMessage = 'Nova viagem: ${newTrip.origin} → ${newTrip.destination}';
        } catch (_) {
          lastEventMessage = 'Uma nova viagem foi publicada!';
        }
        notifyListeners(); // imediato — UI atualiza antes do HTTP
        load(); // sync em background para garantir consistência
        break;
    }
  }

  void clearBanner() {
    lastEventMessage = null;
  }

  /// Viagens que ainda dá para solicitar (abertas e com vaga).
  List<Trip> get available =>
      trips.where((t) => t.status == 'open' && t.availableSeats > 0).toList();

  Trip? byId(String id) {
    for (final t in trips) {
      if (t.id == id) return t;
    }
    return null;
  }

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      trips = await _service.listAll();
    } catch (e) {
      error = e.toString();
    }
    loading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
