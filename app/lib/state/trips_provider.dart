import 'package:flutter/foundation.dart';
import '../models/trip.dart';
import '../services/trip_service.dart';

class TripsProvider extends ChangeNotifier {
  final TripService _service;
  TripsProvider(this._service);

  List<Trip> trips = [];
  bool loading = false;
  String? error;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      trips = await _service.listAvailable();
    } catch (e) {
      error = e.toString();
    }
    loading = false;
    notifyListeners();
  }
}
