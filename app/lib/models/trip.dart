class Trip {
  final String id;
  final String driverId;
  final String origin;
  final String destination;
  final DateTime departureAt;
  final int totalSeats;
  final int availableSeats;
  final String pricePerSeat;
  final String? notes;
  final String status; // open | full | started | completed | cancelled

  const Trip({
    required this.id,
    required this.driverId,
    required this.origin,
    required this.destination,
    required this.departureAt,
    required this.totalSeats,
    required this.availableSeats,
    required this.pricePerSeat,
    this.notes,
    required this.status,
  });

  factory Trip.fromJson(Map<String, dynamic> json) => Trip(
        id: json['id'] as String,
        driverId: json['driverId'] as String,
        origin: json['origin'] as String,
        destination: json['destination'] as String,
        departureAt: DateTime.parse(json['departureAt'] as String),
        totalSeats: json['totalSeats'] as int,
        availableSeats: json['availableSeats'] as int,
        pricePerSeat: json['pricePerSeat'].toString(),
        notes: json['notes'] as String?,
        status: json['status'] as String,
      );
}
