import '../repositories/activity_log_repository.dart';

class ActivityLogController {
  final ActivityLogRepository repository = ActivityLogRepository();

  Future<Map<String, dynamic>> getLogs({
    int page = 1,
    int limit = 10,
    required String product,
    String? action,
    String? search,
  }) async {
    try {
      return await repository.fetchLogs(
        page: page,
        limit: limit,
        product: product,
        action: action,
        search: search,
      );
    } catch (e) {
      return {
        "logs": [],
        "pagination": {"page": 1, "totalPages": 1, "total": 0},
      };
    }
  }
}
