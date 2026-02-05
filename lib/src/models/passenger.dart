class Passenger {
  final String id;
  final String passengerName;
  final String nik;

  Passenger({required this.id, required this.passengerName, required this.nik});

  factory Passenger.fromJson(Map<String, dynamic> json) {
    return Passenger(
      id: json['id']?.toString() ?? '',
      passengerName: json['passengerName'] ?? '-',
      nik: json['nik'] ?? '-',
    );
  }
}
