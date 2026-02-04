import '../models/redeem.dart';
import '../repositories/voucher_repository.dart';

class VoucherRedeemController {
  final VoucherRepository _repo = VoucherRepository();

  // =====================
  // GET ALL VOUCHER DATA
  // =====================
  Future<List<Redeem>> fetchAllVoucher() async {
    int page = 1;
    const int limit = 50;
    List<Redeem> allData = [];

    while (true) {
      final data = await _repo.getRedeemList(page: page, limit: limit);
      if (data.isEmpty) break;

      allData.addAll(data);
      page++;
    }

    // 🔒 FINAL LOCK (ANTI NYAMPUR)
    return allData.where((e) => e.programType == 'VOUCHER').toList();
  }

  // =====================
  // VERIFY SERIAL
  // =====================
  Future<Map<String, dynamic>> verifySerial(String serialNumber) {
    return _repo.verifySerial(serialNumber);
  }

  // =====================
  // REDEEM
  // =====================
  Future<Map<String, dynamic>> redeemVoucher({
    required String serial,
    required String name,
    required String nik,
  }) {
    return _repo.redeemVoucher(serial: serial, name: name, nik: nik);
  }

  // =====================
  // DELETE
  // =====================
  Future<Map<String, dynamic>> deleteVoucher({
    required String id,
    required String note,
    required String deletedBy,
  }) {
    return _repo.deleteVoucher(id: id, note: note, deletedBy: deletedBy);
  }
}
