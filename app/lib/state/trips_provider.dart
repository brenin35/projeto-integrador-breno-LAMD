import 'package:flutter/foundation.dart';
import '../models/trip.dart';
import '../services/trip_service.dart';

/// Carrega TODAS as viagens; expõe as disponíveis e um lookup por id
/// (usado para resolver a viagem de cada solicitação).
class TripsProvider extends ChangeNotifier {
  final TripService _service;
  TripsProvider(this._service);

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
}
