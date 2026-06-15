import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config.dart';

class RealtimeEvent {
  final String type; // ex.: seat_request.status_changed
  final Map<String, dynamic> data;
  RealtimeEvent(this.type, this.data);
}

class RealtimeService {
  WebSocketChannel? _channel;
  final StreamController<RealtimeEvent> _controller =
      StreamController<RealtimeEvent>.broadcast();

  Stream<RealtimeEvent> get events => _controller.stream;

  void connect(String token) {
    disconnect();
    _channel = WebSocketChannel.connect(Uri.parse(AppConfig.wsUrl(token)));
    _channel!.stream.listen(
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
      onError: (_) {},
      onDone: () {},
    );
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    disconnect();
    _controller.close();
  }
}
