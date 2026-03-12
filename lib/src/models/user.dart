class User {
  final String id;
  final String username;
  final String fullName;
  final String email;
  final String roleName;
  final String stationId;
  final String stationName;

  User({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    required this.roleName,
    required this.stationId,
    required this.stationName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final station = json['station'] ?? {};

    return User(
      id: json['id'].toString(),
      username: json['username'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      roleName: json['role']?['roleName'] ?? '-',
      stationId: station['id'] ?? '',
      stationName: station['stationName'] ?? '',
    );
  }
}
