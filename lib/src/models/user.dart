class User {
  final String id;
  final String username;
  final String fullName;
  final String email;

  User({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      username: json['username'],
      fullName: json['fullName'],
      email: json['email'],
    );
  }
}
