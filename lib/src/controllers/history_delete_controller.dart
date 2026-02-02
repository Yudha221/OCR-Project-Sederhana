import '../repositories/history_delete_repository.dart';

class HistoryDeleteController {
  final HistoryDeleteRepository _repo = HistoryDeleteRepository();

  bool isLoading = false;

  // pagination (CLIENT SIDE)
  int currentPage = 1;
  int rowsPerPage = 10;

  List<dynamic> allData = [];
  List<dynamic> filteredData = [];
  List<dynamic> tableData = [];

  Future<void> load() async {
    isLoading = true;

    // 🔥 AMBIL SEMUA DATA (limit BESAR)
    final res = await _repo.fetchHistoryDelete(limit: 1000);
    final result = res.data['data'];

    allData = result['items'] ?? [];
    currentPage = 1;

    _applyPagination();

    isLoading = false;
  }

  void search(String keyword) {
    final key = keyword.toLowerCase();

    filteredData = allData.where((e) {
      return (e['transactionNumber'] ?? '').toString().toLowerCase().contains(
            key,
          ) ||
          (e['card']?['serialNumber'] ?? '').toString().toLowerCase().contains(
            key,
          ) ||
          (e['operator']?['fullName'] ?? '').toString().toLowerCase().contains(
            key,
          ) ||
          (e['station']?['stationName'] ?? '')
              .toString()
              .toLowerCase()
              .contains(key);
    }).toList();

    currentPage = 1;
    _applyPagination();
  }

  void _applyPagination() {
    filteredData = filteredData.isEmpty ? allData : filteredData;

    final start = (currentPage - 1) * rowsPerPage;
    final end = start + rowsPerPage;

    tableData = filteredData.sublist(
      start,
      end > filteredData.length ? filteredData.length : end,
    );
  }

  void nextPage() {
    currentPage++;
    _applyPagination();
  }

  void prevPage() {
    if (currentPage > 1) {
      currentPage--;
      _applyPagination();
    }
  }

  int get totalPage => (filteredData.length / rowsPerPage).ceil().clamp(1, 999);
}
