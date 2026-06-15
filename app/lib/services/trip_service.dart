import '../models/trip.dart';
import 'api_client.dart';

class TripService {
  final ApiClient _api;
  TripService(this._api);

  /// Viagens disponíveis para o passageiro: abertas e com vaga.
  Future<List<Trip>> listAvailable() async {
    final data = await _api.get('/trips') as List;
    return data
        .map((e) => Trip.fromJson(e as Map<String, dynamic>))
        .where((t) => t.status == 'open' && t.availableSeats > 0)
        .toList()
      ..sort((a, b) => a.departureAt.compareTo(b.departureAt));
  }

  Future<Trip> getById(String id) async =>
      Trip.fromJson(await _api.get('/trips/$id') as Map<String, dynamic>);
}
