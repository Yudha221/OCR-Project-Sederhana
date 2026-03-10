import 'package:ocr_project/src/models/activity_log.dart';
import 'package:ocr_project/src/presentation/api.dart';

class ActivityLogRepository {
  Future<Map<String, dynamic>> fetchLogs({
    int page = 1,
    int limit = 1000,
    required String product,
    String? action,
    String? search,
  }) async {
    final query = {"page": page, "limit": limit, "product": product};

    /// FILTER ACTION
    if (action != null && action != "ALL") {
      query["action"] = action;
    }

    /// SEARCH
    if (search != null && search.isNotEmpty) {
      query["search"] = search;
    }

    final response = await Api().dio.get(
      '/redeem/activity-logs',
      queryParameters: query,
    );

    if (response.data['success'] == true) {
      final List data = response.data['data'];

      List<ActivityLog> logs = data
          .map((e) => ActivityLog.fromJson(e))
          .toList();

      return {"logs": logs, "pagination": response.data['pagination']};
    }

    return {
      "logs": [],
      "pagination": {"page": 1, "totalPages": 1, "total": 0},
    };
  }
}
