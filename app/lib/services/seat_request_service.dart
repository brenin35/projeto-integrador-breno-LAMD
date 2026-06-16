import '../models/seat_request.dart';
import 'api_client.dart';

class SeatRequestService {
  final ApiClient _api;
  SeatRequestService(this._api);

  Future<SeatRequest> create({
    required String tripId,
    int? seats,
    String? message,
  }) async {
    final data = await _api.post('/seat-requests', {
      'tripId': tripId,
      'seats': ?seats,
      if (message != null && message.isNotEmpty) 'message': message,
    });
    return SeatRequest.fromJson(data as Map<String, dynamic>);
  }

  /// Minhas solicitações (o backend devolve todas; filtramos pelo meu id).
  Future<List<SeatRequest>> listMine(String myUserId) async {
    final data = await _api.get('/seat-requests') as List;
    return data
        .map((e) => SeatRequest.fromJson(e as Map<String, dynamic>))
        .where((r) => r.passengerId == myUserId)
        .toList();
  }

  Future<SeatRequest> cancel(String id) async {
    final data = await _api.post('/seat-requests/$id/cancel', {});
    return SeatRequest.fromJson(data as Map<String, dynamic>);
  }
}
