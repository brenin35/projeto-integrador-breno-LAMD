import '../models/trip.dart';
import 'api_client.dart';

class TripService {
  final ApiClient _api;
  TripService(this._api);

  /// Todas as viagens (a UI separa as disponíveis das que o usuário já está).
  Future<List<Trip>> listAll() async {
    final data = await _api.get('/trips') as List;
    return data.map((e) => Trip.fromJson(e as Map<String, dynamic>)).toList()
      ..sort((a, b) => a.departureAt.compareTo(b.departureAt));
  }

  Future<Trip> getById(String id) async =>
      Trip.fromJson(await _api.get('/trips/$id') as Map<String, dynamic>);

  Future<List<Trip>> listMine(String driverId) async {
    final data = await _api.get('/trips') as List;
    return data
        .map((e) => Trip.fromJson(e as Map<String, dynamic>))
        .where((t) => t.driverId == driverId)
        .toList()
      ..sort((a, b) => b.departureAt.compareTo(a.departureAt));
  }

 Future<Trip> create({
    required String origin,
    required String destination,
    required DateTime departureAt,
    required int totalSeats,
    required String pricePerSeat,
    String? notes,
  }) async {
    final data = await _api.post('/trips', {
      'origin': origin,
      'destination': destination,
      'departureAt': departureAt.toUtc().toIso8601String(),
      'totalSeats': totalSeats,
      'pricePerSeat': pricePerSeat,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    return Trip.fromJson(data as Map<String, dynamic>);
  }

  Future<Trip> updateStatus(String id, String status) async {
    final data = await _api.put('/trips/$id', {'status': status});
    return Trip.fromJson(data as Map<String, dynamic>);
  }
}
