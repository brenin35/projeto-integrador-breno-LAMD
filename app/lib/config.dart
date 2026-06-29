import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class AppConfig {
  static const String _override = String.fromEnvironment('HOST');
  static const int port = 3000;

  static String get host {
    if (_override.isNotEmpty) return _override;
    if (!kIsWeb && Platform.isAndroid) return '10.0.2.2';
    return 'localhost';
  }

  static String get apiBaseUrl => 'http://$host:$port';
  static String wsUrl(String token) => 'ws://$host:$port/ws?token=$token';
}
