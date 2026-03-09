class ActivityLog {
  final String id;
  final String action;
  final String description;
  final String? notes;
  final DateTime createdAt;
  final String fullName;
  final String roleName;

  ActivityLog({
    required this.id,
    required this.action,
    required this.description,
    this.notes,
    required this.createdAt,
    required this.fullName,
    required this.roleName,
  });

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      id: json['id'],
      action: json['action'],
      description: json['description'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
      fullName: json['user']['fullName'],
      roleName: json['user']['role']['roleName'],
    );
  }
}
