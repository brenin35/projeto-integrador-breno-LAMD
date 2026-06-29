import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/seat_request.dart';
import '../models/trip.dart';
import '../services/realtime_service.dart';
import '../services/seat_request_service.dart';
import '../services/trip_service.dart';
import '../services/user_service.dart';

class DriverProvider extends ChangeNotifier {
  final TripService _trips;
  final SeatRequestService _seatRequests;
  final UserService _users;
  final RealtimeService _realtime;
  StreamSubscription<RealtimeEvent>? _sub;

  DriverProvider(this._trips, this._seatRequests, this._users, this._realtime) {
    _sub = _realtime.events.listen(_onEvent);
  }

  String? _driverId;
  List<Trip> myTrips = [];
  List<SeatRequest> requests = []; // solicitações nas minhas viagens
  Map<String, String> _usersById = {}; // id -> nome
  bool loading = false;
  String? error;
  String? lastEventMessage;

  Future<void> load(String driverId) async {
    _driverId = driverId;
    loading = true;
    error = null;
    notifyListeners();
    try {
      myTrips = await _trips.listMine(driverId);
      final tripIds = myTrips.map((t) => t.id).toSet();
      final all = await _seatRequests.listAll();
      requests = all.where((r) => tripIds.contains(r.tripId)).toList();
      final users = await _users.list();
      _usersById = {for (final u in users) u.id: u.name};
    } catch (e) {
      error = e.toString();
    }
    loading = false;
    notifyListeners();
  }

  List<SeatRequest> requestsForTrip(String tripId) =>
      requests.where((r) => r.tripId == tripId).toList();

  int pendingCountForTrip(String tripId) =>
      requests.where((r) => r.tripId == tripId && r.status == 'pending').length;

  String passengerName(String id) => _usersById[id] ?? 'Passageiro';

  Trip? tripById(String id) {
    for (final t in myTrips) {
      if (t.id == id) return t;
    }
    return null;
  }

  Future<Trip> publishTrip({
    required String origin,
    required String destination,
    required DateTime departureAt,
    required int totalSeats,
    required String pricePerSeat,
    String? notes,
  }) async {
    final trip = await _trips.create(
      origin: origin,
      destination: destination,
      departureAt: departureAt,
      totalSeats: totalSeats,
      pricePerSeat: pricePerSeat,
      notes: notes,
    );
    if (_driverId != null) await load(_driverId!);
    return trip;
  }

  Future<void> accept(String requestId) async {
    await _seatRequests.accept(requestId);
    if (_driverId != null) await load(_driverId!);
  }

  Future<void> reject(String requestId) async {
    await _seatRequests.reject(requestId);
    if (_driverId != null) await load(_driverId!);
  }

  Future<void> setTripStatus(String tripId, String status) async {
    await _trips.updateStatus(tripId, status);
    if (_driverId != null) await load(_driverId!);
  }

  void _onEvent(RealtimeEvent ev) {
    if (_driverId == null) return;
    switch (ev.type) {
      case 'connected':
        load(_driverId!);
        break;
      case 'seat_request.created':
        lastEventMessage = 'Nova solicitação de vaga recebida!';
        load(_driverId!);
        break;
      case 'seat_request.status_changed':
      case 'trip.status_changed':
        load(_driverId!);
        break;
    }
  }

  void clearBanner() {
    lastEventMessage = null;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
