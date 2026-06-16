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
}
