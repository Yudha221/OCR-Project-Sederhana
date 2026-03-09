class Station {
  final String id;
  final String stationCode;
  final String stationName;
  final String location;
  final String channelName; // 🔥 TAMBAHKAN

  Station({
    required this.id,
    required this.stationCode,
    required this.stationName,
    required this.location,
    required this.channelName, // 🔥 TAMBAHKAN
  });

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      id: json['id'] ?? '',
      stationCode: json['stationCode'] ?? '',
      stationName: json['stationName'] ?? '',
      location: json['location'] ?? '',
      channelName: json['channelName'] ?? '', // 🔥 TAMBAHKAN
    );
  }
}
