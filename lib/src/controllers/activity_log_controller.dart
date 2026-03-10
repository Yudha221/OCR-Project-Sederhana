import '../models/activity_log.dart';
import '../repositories/activity_log_repository.dart';

class ActivityLogController {
  final ActivityLogRepository repository = ActivityLogRepository();

  bool isLoading = false;
  List<ActivityLog> allLogs = [];
  List<ActivityLog> filteredLogs = [];
  List<ActivityLog> tableLogs = [];

  int currentPage = 1;
  int rowsPerPage = 10;

  Future<void> loadLogs({required String product}) async {
    isLoading = true;
    try {
      final result = await repository.fetchLogs(product: product, limit: 1000);
      allLogs = result["logs"];
      filteredLogs = allLogs;
      currentPage = 1;
      applyPagination();
    } catch (e) {
      allLogs = [];
      filteredLogs = [];
      tableLogs = [];
    } finally {
      isLoading = false;
    }
  }

  void filterLogs(String query, String action) {
    final searchKey = query.toLowerCase();
    
    filteredLogs = allLogs.where((log) {
      final matchesSearch = log.description.toLowerCase().contains(searchKey) ||
          log.fullName.toLowerCase().contains(searchKey) ||
          log.action.toLowerCase().contains(searchKey);
          
      final matchesAction = action == "ALL" || log.action.toUpperCase() == action.toUpperCase();
      
      return matchesSearch && matchesAction;
    }).toList();

    currentPage = 1;
    applyPagination();
  }

  void applyPagination() {
    final start = (currentPage - 1) * rowsPerPage;
    final end = start + rowsPerPage;

    if (filteredLogs.isEmpty) {
      tableLogs = [];
      return;
    }

    tableLogs = filteredLogs.sublist(
      start,
      end > filteredLogs.length ? filteredLogs.length : end,
    );
  }

  int get totalPages => (filteredLogs.length / rowsPerPage).ceil().clamp(1, 999);

  void nextPage() {
    if (currentPage < totalPages) {
      currentPage++;
      applyPagination();
    }
  }

  void prevPage() {
    if (currentPage > 1) {
      currentPage--;
      applyPagination();
    }
  }
}
