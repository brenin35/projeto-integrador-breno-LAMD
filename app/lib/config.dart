/// Configuração de endereço do backend.
///
/// Em Linux desktop / iOS simulator use `localhost`. No emulador Android, o host
/// da máquina é `10.0.2.2`. Dá para sobrescrever na execução:
///   flutter run --dart-define=HOST=10.0.2.2
class AppConfig {
  static const String host = String.fromEnvironment('HOST', defaultValue: 'localhost');
  static const int port = 3000;

  static String get apiBaseUrl => 'http://$host:$port';
  static String wsUrl(String token) => 'ws://$host:$port/ws?token=$token';
}
