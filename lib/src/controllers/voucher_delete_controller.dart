import '../repositories/voucher_delete_repository.dart';
import '../models/redeem.dart';

class VoucherDeleteController {
  final VoucherDeleteRepository _repo = VoucherDeleteRepository();

  bool isLoading = false;

  // pagination (CLIENT SIDE)
  int currentPage = 1;
  int rowsPerPage = 10;

  // ✅ PAKAI MODEL
  List<Redeem> allData = [];
  List<Redeem> filteredData = [];
  List<Redeem> tableData = [];

  Future<void> load() async {
    isLoading = true;

    try {
      final res = await _repo.fetchVoucherDelete(limit: 1000);
      final raw = res.data;

      if (raw is Map && raw['data'] is Map && raw['data']['items'] is List) {
        // 🔥 FILTER FINAL: HANYA VOUCHER
        allData = (raw['data']['items'] as List)
            .where(
              (e) =>
                  e['product'] == 'VOUCHER' ||
                  e['card']?['programType'] == 'VOUCHER',
            )
            .map<Redeem>((e) => Redeem.fromJson(e))
            .toList();
      } else {
        allData = [];
      }

      filteredData = [];
      currentPage = 1;
      _applyPagination();
    } catch (e) {
      print('LOAD VOUCHER DELETE ERROR: $e');
      allData = [];
      tableData = [];
    }

    isLoading = false;
  }

  // ================= SEARCH =================
  void search(String keyword) {
    final key = keyword.toLowerCase();

    filteredData = allData.where((e) {
      return e.transactionNumber.toLowerCase().contains(key) ||
          e.serialNumber.toLowerCase().contains(key) ||
          e.operatorName.toLowerCase().contains(key) ||
          e.station.toLowerCase().contains(key) ||
          e.customerName.toLowerCase().contains(key);
    }).toList();

    currentPage = 1;
    _applyPagination();
  }

  // ================= PAGINATION =================
  void _applyPagination() {
    final source = filteredData.isNotEmpty ? filteredData : allData;

    if (source.isEmpty) {
      tableData = [];
      return;
    }

    final start = (currentPage - 1) * rowsPerPage;
    final end = start + rowsPerPage;

    tableData = source.sublist(
      start,
      end > source.length ? source.length : end,
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

  int get totalPage =>
      ((filteredData.isNotEmpty ? filteredData.length : allData.length) /
              rowsPerPage)
          .ceil()
          .clamp(1, 999);
}
