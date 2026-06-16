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
    _sub = _realtime.events.listen((ev) {
      // Recarrega quando (re)conecta, quando uma viagem muda de status, ou
      // quando uma solicitação muda (aceitar/cancelar altera as vagas).
      if (ev.type == 'connected' ||
          ev.type == 'trip.status_changed' ||
          ev.type == 'seat_request.status_changed') {
        load();
      }
    });
  }

  List<Trip> trips = [];
  bool loading = false;
  String? error;

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
