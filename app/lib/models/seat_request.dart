class SeatRequest {
  final String id;
  final String tripId;
  final String passengerId;
  final int seats;
  final String? message;
  final String status; // pending | accepted | rejected | cancelled

  const SeatRequest({
    required this.id,
    required this.tripId,
    required this.passengerId,
    required this.seats,
    this.message,
    required this.status,
  });

  factory SeatRequest.fromJson(Map<String, dynamic> json) => SeatRequest(
        id: json['id'] as String,
        tripId: json['tripId'] as String,
        passengerId: json['passengerId'] as String,
        seats: (json['seats'] ?? 1) as int,
        message: json['message'] as String?,
        status: json['status'] as String,
      );

  SeatRequest copyWith({String? status}) => SeatRequest(
        id: id,
        tripId: tripId,
        passengerId: passengerId,
        seats: seats,
        message: message,
        status: status ?? this.status,
      );
}
