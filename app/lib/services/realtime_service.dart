import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as ws_status;
import '../config.dart';

/// Evento recebido em tempo real do backend (ponte MOM → WebSocket).
/// O tipo especial `connected` é emitido a cada (re)conexão para que os
/// providers ressincronizem os dados (recuperando o que perderam offline).
class RealtimeEvent {
  final String type; // ex.: seat_request.status_changed | connected
  final Map<String, dynamic> data;
  RealtimeEvent(this.type, this.data);
}

class RealtimeService {
  WebSocketChannel? _channel;
  String? _token;
  bool _closedByUser = false;
  Timer? _reconnectTimer;

  final StreamController<RealtimeEvent> _controller =
      StreamController<RealtimeEvent>.broadcast();

  Stream<RealtimeEvent> get events => _controller.stream;

  void connect(String token) {
    _token = token;
    _closedByUser = false;
    _open();
  }

  void _open() {
    _reconnectTimer?.cancel();
    final token = _token;
    if (token == null || _closedByUser) return;

    final channel = WebSocketChannel.connect(Uri.parse(AppConfig.wsUrl(token)));
    _channel = channel;

    channel.ready.then((_) {
      debugPrint('[ws] conectado');
      _controller.add(RealtimeEvent('connected', {}));
    }).catchError((e) {
      debugPrint('[ws] falha ao conectar: $e');
      _scheduleReconnect();
    });

    channel.stream.listen(
      (message) {
        try {
          final decoded = jsonDecode(message as String) as Map<String, dynamic>;
          _controller.add(RealtimeEvent(
            decoded['type'] as String,
            (decoded['data'] as Map?)?.cast<String, dynamic>() ?? {},
          ));
        } catch (_) {
          // mensagem malformada — ignora
        }
      },
      onError: (e) {
        debugPrint('[ws] erro: $e');
        _scheduleReconnect();
      },
      onDone: () {
        debugPrint('[ws] conexão encerrada');
        _scheduleReconnect();
      },
      cancelOnError: true,
    );
  }

  void _scheduleReconnect() {
    if (_closedByUser) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), _open);
  }

  void disconnect() {
    _closedByUser = true;
    _reconnectTimer?.cancel();
    _channel?.sink.close(ws_status.normalClosure);
    _channel = null;
  }

  void dispose() {
    disconnect();
    _controller.close();
  }
}
