import '../models/redeem.dart';
import '../repositories/redeem_repository.dart';

enum ProductType { voucher, fwc }

class RedeemController {
  final RedeemRepository _repo = RedeemRepository();

  // =====================
  // GET ALL DATA 🔥
  // =====================
  Future<List<Redeem>> fetchAllRedeem() async {
    int page = 1;
    const int limit = 1000; // ambil banyak biar cepat
    List<Redeem> allData = [];

    while (true) {
      final data = await _repo.getRedeemList(page: page, limit: limit);

      if (data.isEmpty) break;

      allData.addAll(data);
      page++;
    }

    return allData
        .where((e) => e.programType == 'FWC') // ✅ FILTER HERE
        .toList();
  }

  // =====================
  // VERIFY SERIAL
  // =====================
  Future<Map<String, dynamic>> verifySerial(String serialNumber) {
    return _repo.verifySerial(serialNumber);
  }

  ProductType detectProductType(Map<String, dynamic> data) {
    final totalQuota = data['cardProduct']?['totalQuota'];

    if (totalQuota == 1) return ProductType.voucher;
    if (totalQuota > 1) return ProductType.fwc;

    throw Exception('Invalid product data');
  }

  // =====================
  // DELETE REDEEM ✅
  // =====================
  Future<Map<String, dynamic>> deleteRedeem({
    required String id,
    required String note,
    required String deletedBy,
  }) {
    return _repo.deleteRedeem(id: id, note: note, deletedBy: deletedBy);
  }

  // =====================
  // REDEEM
  // =====================
  Future<Map<String, dynamic>> redeem({
    required String serialNumber,
    required int redeemType,
  }) {
    return _repo.redeem(serialNumber: serialNumber, redeemType: redeemType);
  }

  Future<Map<String, dynamic>> verifySerialFWC(String serialNumber) async {
    final res = await _repo.verifySerial(serialNumber);

    if (res['success'] != true) {
      return res;
    }

    final data = res['data'];
    final programType = data['programType'];

    // 🚨 BLOK JIKA BUKAN FWC
    if (programType != 'FWC') {
      return {
        'success': false,
        'errorType': 'WRONG_PROGRAM',
        'message': 'Serial ini adalah voucher, silakan redeem di menu Voucher',
      };
    }

    return res;
  }
}
