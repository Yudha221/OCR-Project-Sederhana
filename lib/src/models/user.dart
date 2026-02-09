class User {
  final String id;
  final String username;
  final String fullName;
  final String email;
  final String roleName;

  User({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    required this.roleName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      username: json['username'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      roleName: json['role']?['roleName'] ?? '-', // 🔥 INI PENTING
    );
  }
}
