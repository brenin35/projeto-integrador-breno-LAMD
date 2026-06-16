import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/seat_request.dart';
import '../services/realtime_service.dart';
import '../services/seat_request_service.dart';

/// Minhas solicitações de vaga. Escuta o WebSocket: quando o motorista aceita
/// ou recusa, o status é atualizado AQUI, automaticamente, sem o usuário mexer.
class MyRequestsProvider extends ChangeNotifier {
  final SeatRequestService _service;
  final RealtimeService _realtime;
  StreamSubscription<RealtimeEvent>? _sub;

  MyRequestsProvider(this._service, this._realtime) {
    _sub = _realtime.events.listen(_onEvent);
  }

  List<SeatRequest> requests = [];
  bool loading = false;
  String? error;

  /// Mensagem do último evento em tempo real (para exibir um banner/snackbar).
  String? lastEventMessage;

  /// Solicitação ativa (pendente ou aceita) do usuário para uma viagem, se houver.
  SeatRequest? activeForTrip(String tripId) {
    for (final r in requests) {
      if (r.tripId == tripId && (r.status == 'pending' || r.status == 'accepted')) {
        return r;
      }
    }
    return null;
  }

  Future<void> load(String myUserId) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      requests = await _service.listMine(myUserId);
    } catch (e) {
      error = e.toString();
    }
    loading = false;
    notifyListeners();
  }

  Future<SeatRequest> create({
    required String tripId,
    int? seats,
    String? message,
  }) async {
    final created = await _service.create(tripId: tripId, seats: seats, message: message);
    // Pode ser uma solicitação reaberta (mesmo id): substitui em vez de duplicar.
    final idx = requests.indexWhere((r) => r.id == created.id);
    if (idx >= 0) {
      requests[idx] = created;
    } else {
      requests = [created, ...requests];
    }
    notifyListeners();
    return created;
  }

  /// Sair da viagem / cancelar a própria solicitação.
  Future<void> cancel(String id) async {
    final updated = await _service.cancel(id);
    final idx = requests.indexWhere((r) => r.id == id);
    if (idx >= 0) requests[idx] = updated;
    notifyListeners();
  }

  void _onEvent(RealtimeEvent ev) {
    if (ev.type == 'seat_request.status_changed') {
      final id = ev.data['id'] as String?;
      final status = ev.data['status'] as String?;
      if (id == null || status == null) return;
      final idx = requests.indexWhere((r) => r.id == id);
      if (idx >= 0) {
        requests[idx] = requests[idx].copyWith(status: status);
        lastEventMessage = 'Sua solicitação agora está "$status"';
        notifyListeners();
      }
    } else if (ev.type == 'trip.status_changed') {
      final status = ev.data['status'] as String?;
      if (status == null) return;
      lastEventMessage = 'Uma viagem sua mudou para "$status"';
      notifyListeners();
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
