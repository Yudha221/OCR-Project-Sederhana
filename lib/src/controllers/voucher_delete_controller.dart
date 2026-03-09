import '../repositories/voucher_delete_repository.dart';
import '../models/pembatalan_kereta.dart';

class VoucherDeleteController {
  final VoucherDeleteRepository _repo = VoucherDeleteRepository();

  bool isLoading = false;

  int currentPage = 1;
  int rowsPerPage = 10;

  List<PembatalanKereta> allData = [];
  List<PembatalanKereta> filteredData = [];
  List<PembatalanKereta> tableData = [];

  Future<void> load() async {
    isLoading = true;

    try {
      final res = await _repo.fetchVoucherDelete(limit: 1000);
      final result = res.data['data'];

      final List items = result['items'];

      /// 🔥 FILTER KHUSUS VOUCHER
      allData = items
          .map((e) => PembatalanKereta.fromJson(e))
          .where((e) => e.programType == 'VOUCHER')
          .toList();

      filteredData = allData;

      currentPage = 1;
      _applyPagination();
    } catch (e) {
      print('LOAD VOUCHER DELETE ERROR: $e');
      allData = [];
      tableData = [];
    }

    isLoading = false;
  }

  /// ================= SEARCH =================
  void search(String keyword) {
    final key = keyword.toLowerCase();

    filteredData = allData.where((e) {
      return e.transactionNumber.toLowerCase().contains(key) ||
          e.serialNumber.toLowerCase().contains(key) ||
          e.operatorName.toLowerCase().contains(key) ||
          e.stationName.toLowerCase().contains(key) ||
          e.customerName.toLowerCase().contains(key);
    }).toList();

    currentPage = 1;
    _applyPagination();
  }

  /// ================= PAGINATION =================
  void _applyPagination() {
    final start = (currentPage - 1) * rowsPerPage;
    final end = start + rowsPerPage;

    tableData = filteredData.sublist(
      start,
      end > filteredData.length ? filteredData.length : end,
    );
  }

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
