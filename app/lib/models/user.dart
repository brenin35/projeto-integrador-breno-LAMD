/// Usuário autenticado (perfil é contextual: motorista numa viagem, passageiro
/// numa solicitação). Nunca recebe `passwordHash` do backend.
class User {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? vehicle;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.vehicle,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String?,
        vehicle: json['vehicle'] as String?,
      );
}
