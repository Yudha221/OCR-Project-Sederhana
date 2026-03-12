import '../repositories/history_delete_repository.dart';
import '../models/pembatalan_kereta.dart';

class HistoryDeleteController {
  final HistoryDeleteRepository _repo = HistoryDeleteRepository();

  bool isLoading = false;

  int currentPage = 1;
  int rowsPerPage = 10;

  List<PembatalanKereta> allData = [];
  List<PembatalanKereta> filteredData = [];
  List<PembatalanKereta> tableData = [];

  Future<void> load() async {
    isLoading = true;

    final res = await _repo.fetchHistoryDelete(limit: 1000);
    final result = res.data['data'];

    final List items = result['items'];

    allData = items
        .map((e) => PembatalanKereta.fromJson(e))
        .where((e) => e.programType == 'FWC')
        .toList();

    filteredData = allData;

    currentPage = 1;
    _applyPagination();

    isLoading = false;
  }

  void search(String keyword) {
    final key = keyword.toLowerCase();

    filteredData = allData.where((e) {
      return e.transactionNumber.toLowerCase().contains(key) ||
          e.serialNumber.toLowerCase().contains(key) ||
          e.operatorName.toLowerCase().contains(key) ||
          e.stationName.toLowerCase().contains(key);
    }).toList();

    currentPage = 1;
    _applyPagination();
  }

  void _applyPagination() {
    final start = (currentPage - 1) * rowsPerPage;
    final end = start + rowsPerPage;

    tableData = filteredData.sublist(
      start,
      end > filteredData.length ? filteredData.length : end,
    );
  }

  void rebuildPagination() => _applyPagination();

  void nextPage() {
    if (currentPage < totalPage) {
      currentPage++;
      _applyPagination();
    }
  }

  void prevPage() {
    if (currentPage > 1) {
      currentPage--;
      _applyPagination();
    }
  }

  int get totalPage => (filteredData.length / rowsPerPage).ceil().clamp(1, 999);
}
